#!/usr/bin/python3
import logging
import os
import subprocess
import time
from typing import Optional
from urllib import parse

from gi.repository import Nemo, GObject

CACHE_TTL = 2  # seconds

# --- Logging setup ---
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


# --------------------------
# Core Git logic (testable)
# --------------------------

def run_git(path: str, *args, timeout: int = 2) -> Optional[str]:
    """Run a git command in a given path, return stripped output or None on error."""
    cmd = ["git", "-C", path, *args]
    try:
        output = subprocess.check_output(
            cmd, stderr=subprocess.DEVNULL, text=True, timeout=timeout
        ).strip()
        logging.debug("Ran %s → %s", cmd, output)
        return output
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        logging.debug("Git command failed (%s): %s", cmd, e)
        return None


def parse_status(status_lines: list[str]) -> str:
    """Parse git status lines (porcelain v1 or v2) into 'clean', 'dirty', or 'untracked'."""
    import logging
    logging.debug("Parsing status: %d lines", len(status_lines))

    dirty = False
    untracked = False
    branch_ahead = ""
    branch_behind = ""

    for line in status_lines:
        line = line.strip()
        if not line:
            continue

        # Branch info
        if line.startswith("# branch.ab"):
            parts = line.split()
            for p in parts:
                if p.startswith("+"):
                    branch_ahead = p[1:]
                elif p.startswith("-"):
                    branch_behind = p[1:]
            continue

        # Worktree changes
        first_char = line[0]
        # Porcelain v2 codes
        if first_char in ("1", "2", "u"):
            dirty = True
        # Untracked
        elif first_char == "?":
            untracked = True
        # Porcelain v1 codes (like 'M', 'A', 'D', 'R', 'C')
        elif first_char in ("M", "A", "D", "R", "C"):
            dirty = True

    if dirty:
        status = "dirty"
    elif untracked:
        status = "untracked"
    else:
        status = "clean"

    # Append ahead/behind info if present
    if branch_ahead or branch_behind:
        status += f" +{branch_ahead} -{branch_behind}".strip()

    logging.debug("Parsed status result: %s", status)
    return status


def get_git_info(path: str, cache: dict, ttl: int = CACHE_TTL) -> dict[str, str]:
    """Return git info (repo presence, branch, status) for a path."""
    now = time.time()
    repo_root = run_git(path, "rev-parse", "--show-toplevel")
    cached = cache.get(repo_root)

    # Only return cache if within TTL and the repo is still clean
    if cached and now - cached[0] < ttl and cached[1]["git_status"] == "clean":
        return cached[1]

    # Get branch
    branch = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD") or ""
    if branch == "HEAD":  # detached head
        commit = run_git(repo_root, "rev-parse", "--short", "HEAD") or ""
        branch = f"detached@{commit}"

    # Get status lines
    status_output = run_git(repo_root, "status", "--porcelain=v2", "--branch")
    status_lines = status_output.splitlines() if status_output else []

    # parse status (our robust function handles v1/v2, staged, unstaged, untracked)
    status = parse_status(status_lines) if status_lines else "clean"

    info = {"git_repo": "yes", "git_branch": branch, "git_status": status}
    cache[repo_root] = (now, info)
    return info



def should_skip_path(path: str) -> bool:
    """Return True if the path should be skipped (e.g., inside .git)."""
    return "/.git" in path


def uri_to_path(uri: str) -> Optional[str]:
    """Convert a file:// URI to a filesystem path, or None if unsupported."""
    if not uri.startswith("file://"):
        return None
    return parse.unquote(uri[7:])


# --------------------------
# Nemo Integration Layer
# --------------------------

class GitColumns(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
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
        uri = file.get_activation_uri()
        logging.debug("update_file_info_full called for URI=%s", uri)

        path = uri_to_path(uri)
        if not path or should_skip_path(path) or not os.path.isdir(path):
            self._apply_info(file, {"git_repo": "", "git_branch": "", "git_status": ""})
            return Nemo.OperationResult.COMPLETE

        info = get_git_info(path, self._cache, ttl=CACHE_TTL)
        self._apply_info(file, info)
        return Nemo.OperationResult.COMPLETE

    def _apply_info(self, file, info: dict[str, str]):
        """Attach computed info to a Nemo file object."""
        file.add_string_attribute("git_repo", info.get("git_repo", ""))
        file.add_string_attribute("git_branch", info.get("git_branch", ""))
        file.add_string_attribute("git_status", info.get("git_status", ""))
