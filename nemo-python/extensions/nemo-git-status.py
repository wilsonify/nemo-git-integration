#!/usr/bin/python3
import os
import subprocess
import time
from dataclasses import dataclass
from urllib import parse
from gi.repository import Nemo, GObject

CACHE_TTL = 5  # seconds


@dataclass(frozen=True)
class GitFileInfo:
    git_repo: str = ""
    git_branch: str = ""
    git_status: str = ""


class GitColumns(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
    def __init__(self):
        super().__init__()
        # Cache keyed by repo root, not arbitrary path
        self._cache: dict[str, tuple[float, GitFileInfo]] = {}

    # Define custom columns
    def get_columns(self):
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
        if file.get_uri_scheme() != "file":
            return Nemo.OperationResult.COMPLETE

        uri = file.get_activation_uri()
        if not uri.startswith("file://"):
            return Nemo.OperationResult.COMPLETE

        path = parse.unquote(uri[7:])
        if not os.path.isdir(path):
            return Nemo.OperationResult.COMPLETE

        info = self._get_git_info(path)

        file.add_string_attribute("git_repo", info.git_repo)
        file.add_string_attribute("git_branch", info.git_branch)
        file.add_string_attribute("git_status", info.git_status)

        Nemo.info_provider_update_complete_invoke(
            closure, provider, handle, Nemo.OperationResult.COMPLETE
        )
        return Nemo.OperationResult.COMPLETE

    # --- Helpers ---

    def _run_git(self, path, *args, timeout=2) -> str | None:
        """Run a git command and return its output, or None on error."""
        try:
            return subprocess.check_output(
                ["git", "-C", path, *args],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=timeout,
            ).strip()
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return None

    def _parse_status(self, status_lines: list[str]) -> str:
        worktree = [l for l in status_lines if not l.startswith("#")]
        branch_info = [l for l in status_lines if l.startswith("# branch.ab")]

        if not worktree:
            status = "clean"
        elif any(l.startswith("??") for l in worktree):
            status = "untracked"
        else:
            status = "dirty"

        if branch_info:
            parts = branch_info[0].split()
            ahead = next((p for p in parts if "ahead" in p), "")
            behind = next((p for p in parts if "behind" in p), "")
            if ahead or behind:
                status += f" {ahead} {behind}".strip()

        return status

    def _get_git_info(self, path: str) -> GitFileInfo:
        now = time.time()

        # First detect repo root
        repo_root = self._run_git(path, "rev-parse", "--show-toplevel")
        if not repo_root:
            return GitFileInfo()  # not a repo

        # Cache lookup at repo root level
        cached = self._cache.get(repo_root)
        if cached and now - cached[0] < CACHE_TTL:
            return cached[1]

        branch = self._run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
        if not branch:
            branch = "(unknown)"

        try:
            status_output = self._run_git(repo_root, "status", "--porcelain=v2", "--branch")
            status_lines = status_output.splitlines() if status_output else []
            status = self._parse_status(status_lines) if status_lines else "(error)"
        except Exception:
            status = "(error)"

        info = GitFileInfo(git_repo="yes", git_branch=branch, git_status=status)
        self._cache[repo_root] = (now, info)
        return info
