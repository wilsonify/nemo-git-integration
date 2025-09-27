#!/usr/bin/python3
import os
import subprocess
from urllib import parse
from gi.repository import Nemo, GObject

class GitFileInfo:
    def __init__(self):
        self.git_repo = ""
        self.git_branch = ""
        self.git_status = ""

class GitColumns(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
    def __init__(self):
        self.ids_by_handle = {}

    # Define the new columns
    def get_columns(self):
        return (
            Nemo.Column(name="NemoPython::git_repo",
                        attribute="git_repo",
                        label="Git Repo",
                        description="Whether this folder is a Git repository"),
            Nemo.Column(name="NemoPython::git_branch",
                        attribute="git_branch",
                        label="Git Branch",
                        description="Current Git branch"),
            Nemo.Column(name="NemoPython::git_status",
                        attribute="git_status",
                        label="Git Status",
                        description="Working tree status"),
        )

    def update_file_info_full(self, provider, handle, closure, file):
        if file.get_uri_scheme() != 'file':
            return Nemo.OperationResult.COMPLETE

        uri = file.get_activation_uri()
        if not uri.startswith("file://"):
            return Nemo.OperationResult.COMPLETE

        path = parse.unquote(uri[7:])
        if not os.path.isdir(path):
            return Nemo.OperationResult.COMPLETE

        info = self.get_git_info(path)

        file.add_string_attribute("git_repo", info.git_repo)
        file.add_string_attribute("git_branch", info.git_branch)
        file.add_string_attribute("git_status", info.git_status)

        Nemo.info_provider_update_complete_invoke(
            closure, provider, handle, Nemo.OperationResult.COMPLETE
        )
        return Nemo.OperationResult.COMPLETE

    def get_git_info(self, path):
        info = GitFileInfo()
        git_dir = os.path.join(path, ".git")

        if not os.path.isdir(git_dir):
            return info  # not a repo

        info.git_repo = "yes"

        # Get branch
        try:
            branch = subprocess.check_output(
                ["git", "-C", path, "rev-parse", "--abbrev-ref", "HEAD"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=2
            ).strip()
            info.git_branch = branch
        except Exception:
            info.git_branch = "(unknown)"

        # Get status
        try:
            status = subprocess.check_output(
                ["git", "-C", path, "status", "--porcelain=v2", "--branch"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=2
            ).splitlines()

            worktree = [l for l in status if not l.startswith("#")]
            branch_info = [l for l in status if l.startswith("# branch.ab")]

            if not worktree:
                info.git_status = "clean"
            elif any(l.startswith("??") for l in worktree):
                info.git_status = "untracked"
            else:
                info.git_status = "dirty"

            if branch_info:
                parts = branch_info[0].split()
                ahead = behind = ""
                if "ahead" in parts[2]:
                    ahead = parts[2]
                if len(parts) > 3 and "behind" in parts[3]:
                    behind = parts[3]
                if ahead or behind:
                    info.git_status += f" {ahead} {behind}".strip()

        except Exception:
            info.git_status = "(error)"

        return info
