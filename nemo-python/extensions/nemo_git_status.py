#!/usr/bin/python3
import logging
import os
import re
import subprocess
import time
import threading
from typing import Dict, Optional
from urllib import parse
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
    Run a single composite git command to fetch:
      - current branch or detached commit
      - origin URL
      - full status (porcelain v2)
    Returns dict or None if repo invalid.
    """
    if not repo_root or not os.path.isdir(repo_root):
        return None

    cmd = [
        "bash", "-c",
        (
            "set -e;"
            "branch=$(git -C \"$1\" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '');"
            "if [ \"$branch\" = 'HEAD' ]; then "
            "  branch=\"detached@$(git -C \"$1\" rev-parse --short HEAD 2>/dev/null || echo '')\";"
            "fi;"
            "origin=$(git -C \"$1\" remote get-url origin 2>/dev/null || echo '');"
            "status=$(git -C \"$1\" status --porcelain=v2 --branch 2>/dev/null || true);"
            "echo \"$branch\";"
            "echo '<<<ORIGIN>>>';"
            "echo \"$origin\";"
            "echo '<<<STATUS>>>';"
            "echo \"$status\";"
        ),
        "_", repo_root
    ]

    try:
        output = subprocess.check_output(
            cmd, stderr=subprocess.DEVNULL, text=True, timeout=GIT_TIMEOUT
        )
    except subprocess.SubprocessError:
        return None

    # Parse sections
    branch, origin, status_lines = "", "", []
    section = "branch"
    for line in output.splitlines():
        if line == "<<<ORIGIN>>>":
            section = "origin"
            continue
        elif line == "<<<STATUS>>>":
            section = "status"
            continue
        if section == "branch":
            branch = line.strip()
        elif section == "origin":
            origin = line.strip()
        elif section == "status":
            status_lines.append(line)

    return {
        "git_branch": branch,
        "git_repo": origin,
        "file_status_map": parse_porcelain_status(status_lines),
    }


def parse_porcelain_status(lines):
    """
    Parse `git status --porcelain[=v2] --branch` output into per-file status.

    Supports both porcelain v1 and v2 formats:
    - ?? path              → untracked
    - M, A, D, R, C path   → dirty
    - 1/2/u entries in v2  → dirty
    """
    status_map = {}

    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        # Untracked files (??)
        if line.startswith("?? "):
            status_map[line[3:].strip()] = "untracked"
            continue

        # Porcelain v2: 1 <xy> ... path
        if line[0] in ("1", "2", "u"):
            parts = line.split()
            if len(parts) >= 2:
                path = parts[-1]
                status_map[path] = "dirty"
            continue

        # Porcelain v1: M A D R C ? codes in first column
        code = line[0]
        if code in ("M", "A", "D", "R", "C"):
            # skip status marker and space
            if len(line) > 2:
                status_map[line[2:].strip()] = "dirty"
        elif code == "?":
            if len(line) > 2:
                status_map[line[2:].strip()] = "untracked"

    return status_map


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
