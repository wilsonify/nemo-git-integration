#!/usr/bin/python3
import logging
import os
import subprocess
import time
from urllib import parse

from gi.repository import Nemo, GObject

CACHE_TTL = 5  # seconds

# --- Logging setup ---
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


class GitColumns(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
    def __init__(self):
        super().__init__()
        # cache: repo_root -> (timestamp, dict with git_repo/branch/status)
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
        logging.debug("provider=%s", provider)
        logging.debug("handle=%s", handle)
        logging.debug("closure=%s", closure)

        if file.get_uri_scheme() != "file" or not uri.startswith("file://"):
            self._apply_info(file, {"git_repo": "", "git_branch": "", "git_status": ""})
            return Nemo.OperationResult.COMPLETE

        path = parse.unquote(uri[7:])

        # Skip .git internals
        if "/.git" in path:
            logging.debug("Skipping .git path: %s", path)
            self._apply_info(file, {"git_repo": "", "git_branch": "", "git_status": ""})
            return Nemo.OperationResult.COMPLETE

        info = {"git_repo": "", "git_branch": "", "git_status": ""}
        if os.path.isdir(path):
            info = self._get_git_info(path)

        self._apply_info(file, info)
        return Nemo.OperationResult.COMPLETE

    def _apply_info(self, file, info: dict[str, str]):
        file.add_string_attribute("git_repo", info.get("git_repo", ""))
        file.add_string_attribute("git_branch", info.get("git_branch", ""))
        file.add_string_attribute("git_status", info.get("git_status", ""))

    def _parse_status(self, status_lines: list[str]) -> str:
        logging.debug("Parsing status: %d lines", len(status_lines))
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

        logging.debug("Parsed status result: %s", status)
        return status

    def _run_git(self, path, *args, timeout=2) -> str | None:
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

    def _get_git_info(self, path: str) -> dict[str, str]:
        now = time.time()
        repo_root = self._run_git(path, "rev-parse", "--show-toplevel")
        if not repo_root:
            logging.debug("%s is not a git repo", path)
            return {"git_repo": "", "git_branch": "", "git_status": ""}

        cached = self._cache.get(repo_root)
        if cached and now - cached[0] < CACHE_TTL:
            return cached[1]

        branch = self._run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD") or ""
        if branch == "HEAD":  # handle detached HEAD
            commit = self._run_git(repo_root, "rev-parse", "--short", "HEAD") or ""
            branch = f"detached@{commit}"

        status_output = self._run_git(repo_root, "status", "--porcelain=v2", "--branch")
        status_lines = status_output.splitlines() if status_output else []
        status = self._parse_status(status_lines) if status_lines else "(error)"

        info = {"git_repo": "yes", "git_branch": branch, "git_status": status}
        self._cache[repo_root] = (now, info)
        return info
