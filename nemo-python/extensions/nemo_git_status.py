#!/usr/bin/python3
import logging
import re
import subprocess
import threading
import time
from typing import Dict, Optional

from gi.repository import Nemo, GObject

CACHE_TTL = 3  # seconds
GIT_TIMEOUT = 3  # seconds

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)


# ============================================================
#  Git Utilities
# ============================================================

def run_git(repo_root: str) -> Optional[dict]:
    """
    Run git commands to fetch repository information.
    Returns dict or None if repo invalid.
    """
    if not repo_root or not os.path.isdir(repo_root):
        return None

    try:
        # Get branch information
        branch_cmd = ["git", "-C", repo_root, "rev-parse", "--abbrev-ref", "HEAD"]
        try:
            branch = subprocess.check_output(
                branch_cmd, stderr=subprocess.DEVNULL, text=True, timeout=GIT_TIMEOUT
            ).strip()
        except subprocess.SubprocessError:
            branch = ""
        
        # Handle detached HEAD
        if branch == "HEAD":
            try:
                commit_hash = subprocess.check_output(
                    ["git", "-C", repo_root, "rev-parse", "--short", "HEAD"],
                    stderr=subprocess.DEVNULL, text=True, timeout=GIT_TIMEOUT
                ).strip()
                branch = f"detached@{commit_hash}"
            except subprocess.SubprocessError:
                branch = "detached"
        
        # Get origin URL
        try:
            origin = subprocess.check_output(
                ["git", "-C", repo_root, "remote", "get-url", "origin"],
                stderr=subprocess.DEVNULL, text=True, timeout=GIT_TIMEOUT
            ).strip()
        except subprocess.SubprocessError:
            origin = ""
        
        # Get status information
        try:
            status_output = subprocess.check_output(
                ["git", "-C", repo_root, "status", "--porcelain=v2", "--branch"],
                stderr=subprocess.DEVNULL, text=True, timeout=GIT_TIMEOUT
            )
            status_lines = status_output.splitlines()
        except subprocess.SubprocessError:
            status_lines = []
        
    except subprocess.SubprocessError:
        return None

    return {
        "git_branch": branch,
        "git_repo": origin,
        "file_status_map": parse_porcelain_status(status_lines),
    }


def parse_porcelain_status(lines):
    """
    Parse `git status --porcelain[=v2] --branch` output into per-file status.

    Returns a dict mapping file paths to status:
      - 'dirty' for modified/staged files
      - 'untracked' for untracked files
    """
    status_map = {}

    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        # Try each parser until one returns a result
        for parser in (parse_untracked, parse_porcelain_v2, parse_porcelain_v1):
            path, status = parser(line)
            if path:
                status_map[path] = status
                break

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
    """Find repo root quickly without spawning git unnecessarily."""
    cur = os.path.abspath(path if os.path.isdir(path) else os.path.dirname(path))
    while cur != "/":
        if os.path.isdir(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return None


# nemo_git_status.py (excerpt)

from urllib.parse import urlparse, unquote
import os


def uri_to_path(uri: str):
    """
    Convert a 'file://...' URI into a local filesystem path.

    Returns:
        str: decoded local path
        None: if URI is invalid or not a file:// scheme
    """
    if not uri or not isinstance(uri, str):
        return None

    uri = uri.strip()
    if not uri.lower().startswith("file:"):
        return None

    # Must have at least 'file://'
    if not uri.lower().startswith("file://"):
        return None

    parsed = urlparse(uri)
    if parsed.scheme.lower() != "file":
        return None

    path = parsed.path or ""
    if not path:
        return None

    try:
        decoded = unquote(path)
    except Exception:
        decoded = path

    if decoded == "":
        return None

    if os.name == "nt" and decoded.startswith("/"):
        if len(decoded) > 2 and decoded[1] == ":":
            decoded = decoded[1:]

    return decoded


def should_skip(path: str) -> bool:
    return bool(re.search(r"(^|/)\.git(/|$)", path.replace("\\", "/")))


# ============================================================
#  Caching and File Info
# ============================================================

class GitCache:
    """Thread-safe TTL cache for repo info."""

    def __init__(self):
        self._lock = threading.Lock()
        self._data: Dict[str, tuple[float, dict]] = {}

    def get(self, repo_root: str) -> Optional[dict]:
        with self._lock:
            item = self._data.get(repo_root)
            if item and (time.time() - item[0]) < CACHE_TTL:
                return item[1]
        return None

    def set(self, repo_root: str, data: dict):
        with self._lock:
            self._data[repo_root] = (time.time(), data)


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
    if not path or should_skip(path):
        return {"git_repo": "", "git_branch": "", "git_status": ""}

    repo_root = resolve_repo_root(path)
    if not repo_root:
        return {"git_repo": "", "git_branch": "", "git_status": ""}

    cached = cache.get(repo_root)
    if not cached:
        info = run_git(repo_root)
        if not info:
            return {"git_repo": "", "git_branch": "", "git_status": ""}
        cache.set(repo_root, info)
    else:
        info = cached

    # If the path is the repository root directory, show overall repo status
    if os.path.abspath(path) == os.path.abspath(repo_root):
        status = get_overall_repo_status(info["file_status_map"])
    else:
        # For individual files, show their specific status
        rel_path = os.path.relpath(path, repo_root)
        status = info["file_status_map"].get(rel_path, "clean")

    return {
        "git_repo": info["git_repo"],
        "git_branch": info["git_branch"],
        "git_status": status,
    }


# ============================================================
#  Nemo Integration
# ============================================================

class NemoGitIntegration(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider, Nemo.NameAndDescProvider):
    """High-performance Git columns provider for Nemo."""

    def __init__(self):
        super().__init__()

    @staticmethod
    def get_name_and_desc():
        return ["nemo-git-integration-fast:::Provides optimized git status columns"]

    @staticmethod
    def get_columns():
        return (
            Nemo.Column(
                name="NemoGitIntegration::git_repo",
                attribute="git_repo",
                label="Git Repo",
                description="Remote repository URL"
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_branch",
                attribute="git_branch",
                label="Git Branch",
                description="Current branch or commit"
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_status",
                attribute="git_status",
                label="Git Status",
                description="Working tree state"
            ),
        )

    def update_file_info_full(self, provider, handle, closure, file):
        uri = file.get_activation_uri()
        path = uri_to_path(uri)
        info = get_file_git_info(path)
        self._apply_info(file, info)
        return Nemo.OperationResult.COMPLETE

    @staticmethod
    def _apply_info(file, info: dict):
        for key in ("git_repo", "git_branch", "git_status"):
            file.add_string_attribute(key, info.get(key, ""))
