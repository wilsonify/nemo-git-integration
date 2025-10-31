#!/usr/bin/python3
"""
Nemo Git Integration Extension

Provides Git status columns in Nemo file manager.
Optimized for performance with caching and security best practices.
"""

import logging
import os
import re
import subprocess
import threading
import time
from typing import Dict, Optional, Tuple
from urllib.parse import urlparse, unquote

from gi.repository import Nemo, GObject

# Configuration
CACHE_TTL = 3  # seconds
GIT_TIMEOUT = 3  # seconds
MAX_CACHE_SIZE = 100  # Maximum number of repos to cache
LOG_LEVEL = logging.WARNING  # Reduce log noise in production

# Configure logging
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


# ============================================================
#  Git Utilities
# ============================================================

def run_git(repo_root: str) -> Optional[dict]:
    """
    Run git commands to fetch repository information.
    Uses parameterized commands for security and optimized error handling.
    
    Args:
        repo_root: Absolute path to git repository
        
    Returns:
        Dict with git info or None if repo invalid/inaccessible
    """
    if not repo_root or not _is_safe_path(repo_root) or not os.path.isdir(repo_root):
        return None

    try:
        # Get branch information
        branch = _run_git_command(repo_root, ["rev-parse", "--abbrev-ref", "HEAD"])
        if branch is None:
            return None
        branch = branch.strip()
        
        # Handle detached HEAD
        if branch == "HEAD":
            commit_hash = _run_git_command(repo_root, ["rev-parse", "--short", "HEAD"])
            branch = f"detached@{commit_hash.strip()}" if commit_hash else "detached"
        
        # Get origin URL
        origin = _run_git_command(repo_root, ["remote", "get-url", "origin"])
        origin = origin.strip() if origin else ""
        
        # Get status information
        status_output = _run_git_command(repo_root, ["status", "--porcelain=v2", "--branch"])
        status_lines = status_output.splitlines() if status_output else []
        
        return {
            "git_branch": branch,
            "git_repo": origin,
            "file_status_map": parse_porcelain_status(status_lines),
        }
        
    except (subprocess.SubprocessError, OSError, ValueError) as e:
        logger.debug(f"Git command failed for {repo_root}: {e}")
        return None


def _run_git_command(repo_root: str, args: list) -> Optional[str]:
    """
    Execute a git command with proper security measures.
    
    Args:
        repo_root: Repository path (must be validated)
        args: Git command arguments
        
    Returns:
        Command output or None on failure
    """
    cmd = ["git", "-C", repo_root] + args
    
    try:
        return subprocess.check_output(
            cmd, 
            stderr=subprocess.DEVNULL, 
            text=True, 
            timeout=GIT_TIMEOUT,
            env={}  # Clean environment for security
        )
    except subprocess.TimeoutExpired:
        logger.warning(f"Git command timed out for {repo_root}")
        return None
    except subprocess.SubprocessError as e:
        logger.debug(f"Git subprocess error: {e}")
        return None


def _is_safe_path(path: str) -> bool:
    """
    Validate that a path is safe for git operations.
    
    Args:
        path: File system path to validate
        
    Returns:
        True if path is safe, False otherwise
    """
    if not path or not isinstance(path, str):
        return False
        
    # Check for dangerous characters before any other processing
    if any(char in path for char in ['$', '`', '|', ';', '&']):
        return False
        
    # Resolve path to prevent directory traversal
    try:
        resolved = os.path.abspath(path)
        # Additional safety checks for resolved path
        if any(char in resolved for char in ['$', '`', '|', ';', '&']):
            return False
        return True
    except (ValueError, OSError):
        return False


def parse_porcelain_status(lines) -> Dict[str, str]:
    """
    Parse `git status --porcelain[=v2] --branch` output into per-file status.
    
    Optimized parser with early returns and better error handling.

    Args:
        lines: List of git status output lines

    Returns:
        Dict mapping file paths to status:
          - 'dirty' for modified/staged files
          - 'untracked' for untracked files
          - 'clean' for unchanged files
    """
    if not lines:
        return {}
        
    status_map = {}
    
    for raw in lines:
        if not raw:
            continue
            
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        # Fast path: check line prefix to determine parser
        first_char = line[0] if line else ''
        
        if first_char == "?" and len(line) > 2:
            # Untracked file (most common case)
            path = line[2:].lstrip()
            if path:
                status_map[path] = "untracked"
        elif first_char in ("1", "2", "u"):
            # Porcelain v2 format
            parts = line.split()
            if len(parts) >= 2:
                path = parts[-1]
                if path:
                    status_map[path] = "dirty"
        elif first_char in ("M", "A", "D", "R", "C") and len(line) > 2:
            # Porcelain v1 format
            path = line[2:].strip()
            if path:
                status_map[path] = "dirty"

    return status_map


# ---------------------------
# Format-specific parsers
# ---------------------------

def parse_untracked(line):
    """Parse untracked files (porcelain v1: '?? path')."""

    if line.startswith("??"):
        path = line[2:].lstrip()  # remove the leading ?? and any whitespace
        return path, "untracked"
    return None, None


def parse_porcelain_v2(line):
    """
    Parse porcelain v2 entries:
      - 1 <xy> ... path
      - 2 <xy> ... path
      - u <xy> ... path
    Returns (path, 'dirty') or (None, None) if not v2.
    """
    if line[0] in ("1", "2", "u"):
        parts = line.split()
        if len(parts) >= 2:
            return parts[-1], "dirty"
    return None, None


def parse_porcelain_v1(line):
    """
    Parse porcelain v1 single-character codes:
      - M, A, D, R, C → dirty
      - ? → untracked
    Ignore lines starting with '??' (handled by parse_untracked)
    """
    if not line or line.startswith("??"):
        return None, None
    if len(line) > 2:
        code = line[0]
        path = line[2:].strip()
        if code in ("M", "A", "D", "R", "C"):
            return path, "dirty"
        if code == "?":
            return path, "untracked"
    return None, None


def resolve_repo_root(path: str) -> Optional[str]:
    """
    Find git repository root efficiently.
    
    Args:
        path: File or directory path
        
    Returns:
        Repository root path or None if not in a git repo
    """
    if not path or not _is_safe_path(path):
        return None
        
    try:
        # Start with the directory containing the file, or the directory itself
        if os.path.isfile(path):
            path = os.path.dirname(path)
            
        cur = os.path.abspath(path)
        
        # Walk up the directory tree looking for .git
        while cur != "/" and cur:
            git_dir = os.path.join(cur, ".git")
            if os.path.isdir(git_dir):
                return cur
            cur = os.path.dirname(cur)
            
    except (OSError, ValueError):
        pass
        
    return None


def uri_to_path(uri: str) -> Optional[str]:
    """
    Convert a 'file://...' URI into a local filesystem path.
    
    Enhanced with better validation and error handling.

    Args:
        uri: File URI to convert

    Returns:
        Decoded local path or None if URI is invalid
    """
    if not uri or not isinstance(uri, str):
        return None

    uri = uri.strip()
    if not uri.lower().startswith("file:"):
        return None

    try:
        parsed = urlparse(uri)
        if parsed.scheme.lower() != "file":
            return None

        path = parsed.path or ""
        if not path:
            return None

        # Decode URI-encoded characters
        decoded = unquote(path)
        
        # Handle Windows paths if needed
        if os.name == "nt" and decoded.startswith("/"):
            if len(decoded) > 2 and decoded[1] == ":":
                decoded = decoded[1:]

        # Validate the resulting path
        if not _is_safe_path(decoded):
            return None
            
        return decoded
        
    except (ValueError, OSError, Exception) as e:
        logger.debug(f"URI parsing failed for {uri}: {e}")
        return None


def should_skip(path: str) -> bool:
    return bool(re.search(r"(^|/)\.git(/|$)", path.replace("\\", "/")))


# ============================================================
#  Caching and File Info
# ============================================================

class GitCache:
    """
    Thread-safe TTL cache for repository information with size limits.
    
    Features:
    - Automatic cleanup of expired entries
    - Size limit to prevent memory bloat
    - Thread-safe operations
    """

    def __init__(self, max_size: int = MAX_CACHE_SIZE):
        self._lock = threading.RLock()  # Use RLock for nested calls
        self._data: Dict[str, Tuple[float, dict]] = {}
        self._max_size = max_size
        self._hits = 0
        self._misses = 0

    def get(self, repo_root: str) -> Optional[dict]:
        """
        Get cached repository info if still valid.
        
        Args:
            repo_root: Repository root path
            
        Returns:
            Cached info dict or None if expired/not found
        """
        if not repo_root:
            return None
            
        with self._lock:
            item = self._data.get(repo_root)
            if item:
                timestamp, data = item
                if (time.time() - timestamp) < CACHE_TTL:
                    self._hits += 1
                    return data
                else:
                    # Remove expired entry
                    del self._data[repo_root]
                    
            self._misses += 1
            return None

    def set(self, repo_root: str, data: dict):
        """
        Cache repository info with automatic cleanup.
        
        Args:
            repo_root: Repository root path
            data: Repository information to cache
        """
        if not repo_root or not data:
            return
            
        with self._lock:
            # Remove oldest entries if cache is full
            if len(self._data) >= self._max_size:
                self._cleanup_oldest()
                
            self._data[repo_root] = (time.time(), data)
    
    def _cleanup_oldest(self):
        """Remove oldest entries to make room for new ones."""
        if not self._data:
            return
            
        # Sort by timestamp and remove oldest 25%
        sorted_items = sorted(self._data.items(), key=lambda x: x[1][0])
        to_remove = max(1, len(sorted_items) // 4)
        
        for repo_root, _ in sorted_items[:to_remove]:
            del self._data[repo_root]
    
    def clear(self):
        """Clear all cached entries."""
        with self._lock:
            self._data.clear()
            self._hits = 0
            self._misses = 0
    
    def get_stats(self) -> dict:
        """Get cache performance statistics."""
        with self._lock:
            total = self._hits + self._misses
            hit_rate = self._hits / total if total > 0 else 0
            return {
                "size": len(self._data),
                "hits": self._hits,
                "misses": self._misses,
                "hit_rate": hit_rate
            }


cache = GitCache()


def get_overall_repo_status(file_status_map: dict) -> str:
    """
    Determine the overall status of a repository based on all file statuses.
    
    Returns:
      - 'dirty' if any files are modified/staged
      - 'untracked' if there are untracked files (and no dirty files)
      - 'clean' if repository is clean
    """
    has_dirty = False
    has_untracked = False
    
    for status in file_status_map.values():
        if status == "dirty":
            has_dirty = True
            break  # Dirty takes priority
        elif status == "untracked":
            has_untracked = True
    
    if has_dirty:
        return "dirty"
    elif has_untracked:
        return "untracked"
    else:
        return "clean"


def get_file_git_info(path: str) -> dict:
    """
    Get comprehensive git information for a file or directory.
    
    Enhanced with better error handling and performance optimizations.
    
    Args:
        path: File system path
        
    Returns:
        Dict with git_repo, git_branch, and git_status keys
    """
    # Input validation
    if not path or not isinstance(path, str) or should_skip(path):
        return {"git_repo": "", "git_branch": "", "git_status": ""}

    # Resolve repository root
    repo_root = resolve_repo_root(path)
    if not repo_root:
        return {"git_repo": "", "git_branch": "", "git_status": ""}

    # Try to get cached info first
    cached = cache.get(repo_root)
    if not cached:
        # Fetch fresh git information
        info = run_git(repo_root)
        if not info:
            return {"git_repo": "", "git_branch": "", "git_status": ""}
        cache.set(repo_root, info)
    else:
        info = cached

    # Determine appropriate status for the path
    try:
        if os.path.abspath(path) == os.path.abspath(repo_root):
            # Repository root - show overall status
            status = get_overall_repo_status(info["file_status_map"])
        else:
            # Individual file or directory - show specific status
            rel_path = os.path.relpath(path, repo_root)
            status = info["file_status_map"].get(rel_path, "clean")
    except (ValueError, OSError):
        # Fallback to clean status if path resolution fails
        status = "clean"

    return {
        "git_repo": info.get("git_repo", ""),
        "git_branch": info.get("git_branch", ""),
        "git_status": status,
    }


# ============================================================
#  Nemo Integration
# ============================================================

class NemoGitIntegration(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider, Nemo.NameAndDescProvider):
    """
    High-performance Git integration for Nemo file manager.
    
    Features:
    - Optimized git status display
    - Thread-safe caching
    - Security-focused path handling
    - Performance monitoring
    """

    def __init__(self):
        super().__init__()
        self._column_stats = {"updates": 0, "errors": 0}
        logger.info("Nemo Git Integration initialized")

    @staticmethod
    def get_name_and_desc():
        return [
            "nemo-git-integration:::Provides Git status columns with caching and security features"
        ]

    @staticmethod
    def get_columns():
        return (
            Nemo.Column(
                name="NemoGitIntegration::git_repo",
                attribute="git_repo",
                label="Git Repo",
                description="Remote repository URL (truncated)"
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_branch",
                attribute="git_branch",
                label="Git Branch",
                description="Current branch or commit hash"
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_status",
                attribute="git_status",
                label="Git Status",
                description="Working tree state (clean/dirty/untracked)"
            ),
        )

    def update_file_info_full(self, provider, handle, closure, file):
        """
        Update file information with git status.
        
        Enhanced with error handling and performance tracking.
        """
        try:
            self._column_stats["updates"] += 1
            
            uri = file.get_activation_uri()
            if not uri:
                return Nemo.OperationResult.COMPLETE
                
            path = uri_to_path(uri)
            if not path:
                return Nemo.OperationResult.COMPLETE

            info = get_file_git_info(path)
            self._apply_info(file, info)
            
        except Exception as e:
            self._column_stats["errors"] += 1
            logger.debug(f"Error updating file info: {e}")
            # Don't fail the operation, just skip git info
            
        return Nemo.OperationResult.COMPLETE

    @staticmethod
    def _apply_info(file, info: dict):
        """
        Apply git information to file attributes.
        
        Enhanced with data sanitization.
        """
        # Sanitize repo URL for display
        repo = info.get("git_repo", "")
        if repo and len(repo) > 50:
            repo = repo[:47] + "..."
            
        # Apply attributes with validation
        file.add_string_attribute("git_repo", repo)
        file.add_string_attribute("git_branch", info.get("git_branch", "")[:20])  # Limit branch name length
        file.add_string_attribute("git_status", info.get("git_status", ""))
    
    def get_stats(self) -> dict:
        """Get performance statistics for monitoring."""
        cache_stats = cache.get_stats()
        return {
            **self._column_stats,
            **cache_stats
        }
