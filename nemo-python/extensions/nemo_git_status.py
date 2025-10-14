#!/usr/bin/python3
import logging
import os
import re
import subprocess
import time
from typing import List, Dict, Optional
from urllib import parse

from gi.repository import Nemo, GObject

CACHE_TTL = 2  # seconds

# --- Logging setup ---
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


# ============================================================
#  Git Utilities
# ============================================================

def run_git(path: str, *args, timeout: int = 2) -> Optional[str]:
    """Run a git command inside a directory and return stripped output or None."""
    if not path or not os.path.isdir(path):
        return None
    cmd = ["git", "-C", path, *args]
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=timeout).strip()
        logging.debug("Ran %s → %s", cmd, output)
        return output
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        logging.debug("Git command failed (%s): %s", cmd, e)
        return None


def parse_porcelain_status(lines: List[str]) -> Dict[str, str]:
    """
    Parse `git status --porcelain[=v2] --branch` output into per-file status.
    Returns dict: filepath -> status ('clean'|'dirty'|'untracked').

    Handles both porcelain v1 and v2 formats, including untracked files (??).
    """
    status_map: Dict[str, str] = {}

    for raw_line in lines:
        line = raw_line.rstrip()
        if not line or line.startswith("#"):
            continue

        stripped = line.lstrip()

        # --- Untracked entries (??) ---
        if stripped.startswith("?? "):
            filepath = stripped[3:].strip()
            status_map[filepath] = "untracked"
            continue

        # --- Porcelain v2 entries (1, 2, or u) ---
        if stripped[0] in ("1", "2", "u"):
            parts = stripped.split()
            if len(parts) >= 2:
                status_map[parts[-1]] = "dirty"
            continue

        # --- Porcelain v1 entries (M, A, D, R, C, ?) ---
        code = stripped[0]
        if code in ("M", "A", "D", "R", "C"):
            status_map[stripped[2:].strip()] = "dirty"
        elif code == "?":
            status_map[stripped[2:].strip()] = "untracked"

    return status_map


def get_repo_branch(repo_root: str, cache: dict) -> str:
    """Return current branch or detached head string, with caching."""
    now = time.time()
    cached = cache.get(repo_root)
    if cached and now - cached[0] < CACHE_TTL:
        return cached[1].get("git_branch", "")
    branch = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD") or ""
    if branch == "HEAD":
        commit = run_git(repo_root, "rev-parse", "--short", "HEAD") or ""
        branch = f"detached@{commit}"
    return branch


def resolve_repo_root(path: str) -> Optional[str]:
    """Given a file or directory, find its Git repo root (if any)."""
    search_path = path if os.path.isdir(path) else os.path.dirname(path)
    return run_git(search_path, "rev-parse", "--show-toplevel")


# ============================================================
#  File path Logic
# ============================================================

def uri_to_path(uri: str) -> Optional[str]:
    """Convert a file:// URI to a local filesystem path with safe decoding."""
    if not uri.lower().startswith("file://"):
        return None

    rest = uri[7:]  # strip scheme

    # If rest is empty, return None
    if rest == "":
        return None

    # For absolute paths, rest must start with '/'
    if not rest.startswith("/"):
        return None

    # Decode percent-encoded characters; invalid % sequences remain
    path = parse.unquote(rest, errors="strict")

    return path


def should_skip(path: str) -> bool:
    """Return True if path is inside .git directory."""
    normalized = path.replace("\\", "/")

    # Match '.git' as a directory (must be surrounded by slashes or boundaries)
    # Do not match .gitignore or .github
    pattern = r'(^|/)\.git(/|$)'

    return bool(re.search(pattern, normalized))


def get_file_git_info(path: str, cache: dict) -> dict:
    """
    Return per-file Git info: repo presence, branch, and file status.
    """
    if should_skip(path):
        return {"git_repo": "", "git_branch": "", "git_status": ""}
    repo_root = resolve_repo_root(path)
    if not repo_root:
        return {"git_repo": "", "git_branch": "", "git_status": ""}

    # branch (cached)
    branch = get_repo_branch(repo_root, cache)

    # full repo status (cached)
    now = time.time()
    cached = cache.get(repo_root)
    if cached and now - cached[0] < CACHE_TTL and "file_status_map" in cached[1]:
        file_status_map = cached[1]["file_status_map"]
    else:
        output = run_git(repo_root, "status", "--porcelain=v2", "--branch")
        lines = output.splitlines() if output else []
        file_status_map = parse_porcelain_status(lines)
        cache[repo_root] = (now, {"git_branch": branch, "file_status_map": file_status_map})

    # determine file status
    rel_path = os.path.relpath(path, repo_root)
    status = file_status_map.get(rel_path, "clean")

    return {"git_repo": "yes", "git_branch": branch, "git_status": status}


# ============================================================
#  Nemo Integration
# ============================================================


class NemoGitIntegration(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider, Nemo.NameAndDescProvider):
    """Provide per-file Git columns in Nemo."""

    def __init__(self):
        super().__init__()
        self._cache: dict[str, tuple[float, dict]] = {}

    def get_name_and_desc(self):
        """
        Return a list of strings in the format "name::desc[:executable]".
        Optional executable path can be included for context menus or preferences.
        """
        return [f"nemo-git-integration:::Provides git status columns"]

    @staticmethod
    def get_columns():
        return (
            Nemo.Column(
                name="NemoGitIntegration::git_repo",
                attribute="git_repo",
                label="Git Repo",
                description="Whether this folder belongs to a Git repository",
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_branch",
                attribute="git_branch",
                label="Git Branch",
                description="Current Git branch",
            ),
            Nemo.Column(
                name="NemoGitIntegration::git_status",
                attribute="git_status",
                label="Git Status",
                description="Working tree status",
            ),
        )

    def update_file_info_full(self, provider, handle, closure, file):
        """Called by Nemo for each file in view."""
        uri = file.get_activation_uri()
        logging.debug("update_file_info_full: %s", uri)
        path = uri_to_path(uri)
        info = get_file_git_info(path, self._cache)
        self._apply_info(file, info)
        return Nemo.OperationResult.COMPLETE

    @staticmethod
    def _apply_info(file, info: dict):
        """Attach computed info to a Nemo file object."""
        for key in ("git_repo", "git_branch", "git_status"):
            file.add_string_attribute(key, info.get(key, ""))
