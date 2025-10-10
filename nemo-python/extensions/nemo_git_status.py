#!/usr/bin/python3
import logging
import os
import re
import subprocess
import time
from typing import List, Tuple, Optional
from urllib import parse

from gi.repository import Nemo, GObject

CACHE_TTL = 2  # seconds

# --- Logging setup ---
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


# ============================================================
#  Git Core Utilities (Repository-level actions)
# ============================================================

def run_git(path: str, *args, timeout: int = 2) -> Optional[str]:
    """Run a git command inside the specified directory and return stripped output or None."""
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


def parse_status(lines: List[str]) -> str:
    """Parse git status lines (porcelain v1 or v2) into a human-readable state."""
    dirty, untracked = False, False
    ahead, behind = "", ""

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # parse branch info
        if line.startswith("# branch.ab"):
            ahead, behind = _parse_branch_ab(line)
            continue

        # parse file status
        status_type = _parse_file_status(line)
        if status_type == "dirty":
            dirty = True
        elif status_type == "untracked":
            untracked = True

    return _build_status(dirty, untracked, ahead, behind)


# ---- Helpers ----

def _parse_branch_ab(line: str) -> Tuple[str, str]:
    """Extract ahead/behind numbers from a '# branch.ab' line."""
    ahead, behind = "", ""
    parts = line.split()
    for p in parts:
        if p.startswith("+") and p[1:].isdigit():
            ahead = p[1:]
        elif p.startswith("-") and p[1:].isdigit():
            behind = p[1:]
    return ahead, behind


def _parse_file_status(line: str) -> str | None:
    """Return 'dirty', 'untracked', or None depending on the line."""
    if not line:
        return None
    c = line[0]
    if c in ("1", "2", "u", "M", "A", "D", "R", "C"):
        return "dirty"
    if c == "?":
        return "untracked"
    return None


def _build_status(dirty: bool, untracked: bool, ahead: str, behind: str) -> str:
    """Construct the final status string."""
    if dirty:
        base = "dirty"
    elif untracked:
        base = "untracked"
    else:
        base = "clean"

    if ahead or behind:
        base += f" +{ahead} -{behind}"

    return base


def get_repo_info(repo_root: str, cache: dict, ttl: int = CACHE_TTL) -> dict[str, str]:
    """Return cached or fresh repo-level info: branch name and working tree status."""
    now = time.time()
    cached = cache.get(repo_root)

    if cached and now - cached[0] < ttl and cached[1]["git_status"] == "clean":
        return cached[1]

    branch = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD") or ""
    if branch == "HEAD":
        commit = run_git(repo_root, "rev-parse", "--short", "HEAD") or ""
        branch = f"detached@{commit}"

    status_output = run_git(repo_root, "status", "--porcelain=v2", "--branch")
    lines = status_output.splitlines() if status_output else []
    status = parse_status(lines) if lines else "clean"

    info = {"git_repo": "yes", "git_branch": branch, "git_status": status}
    cache[repo_root] = (now, info)
    return info


# ============================================================
#  File-Level Logic (path conversion, classification, filtering)
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
    """Return True if the path is inside a .git directory (case-sensitive on Unix)."""
    # Normalize Windows backslashes to forward slashes
    normalized = path.replace("\\", "/")

    # Match '.git' as a directory (must be surrounded by slashes or string boundaries)
    # Do not match .gitignore or .github
    return bool(re.search(r'(^|/)\.git(/|$)', normalized))


def resolve_repo_root(path: str) -> Optional[str]:
    """Given a file or directory, find its Git repo root (if any)."""
    search_path = path if os.path.isdir(path) else os.path.dirname(path)
    return run_git(search_path, "rev-parse", "--show-toplevel")


def get_file_git_info(path: str, cache: dict) -> dict[str, str]:
    """Return git info for an arbitrary file or directory."""
    if should_skip(path):
        return {"git_repo": "", "git_branch": "", "git_status": ""}
    repo_root = resolve_repo_root(path)
    if not repo_root:
        return {"git_repo": "", "git_branch": "", "git_status": ""}
    return get_repo_info(repo_root, cache)


# ============================================================
#  Nemo Integration Layer
# ============================================================

class GitColumns(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
    """Provide per-file Git columns in Nemo."""

    def __init__(self):
        super().__init__()
        self._cache: dict[str, tuple[float, dict[str, str]]] = {}

    @staticmethod
    def get_columns():
        return (
            Nemo.Column(
                name="NemoPython::git_repo",
                attribute="git_repo",
                label="Git Repo",
                description="Whether this folder belongs to a Git repository",
            ),
            Nemo.Column(
                name="NemoPython::git_branch",
                attribute="git_branch",
                label="Git Branch",
                description="Current Git branch",
            ),
            Nemo.Column(
                name="NemoPython::git_status",
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
    def _apply_info(file, info: dict[str, str]):
        """Attach computed info to a Nemo file object."""
        for key in ("git_repo", "git_branch", "git_status"):
            file.add_string_attribute(key, info.get(key, ""))
