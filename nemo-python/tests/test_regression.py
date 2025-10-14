import os
import subprocess
import tempfile
from pathlib import Path

from nemo_git_status import get_file_git_info


def run_git(repo_path, *args):
    """Helper to run git commands in the given repo and return output lines."""
    result = subprocess.run(
        ["git", "-C", str(repo_path), *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip().splitlines()


def test_e2e_clean_repo_with_branch_info():
    """
    End-to-end regression test:
    - Create a temporary Git repo
    - Add an initial commit
    - Check get_file_git_info() for a clean file
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        repo_root = Path(tmpdir)
        # Initialize repo
        run_git(repo_root, "init")
        # Configure minimal user
        run_git(repo_root, "config", "user.name", "Test User")
        run_git(repo_root, "config", "user.email", "test@example.com")

        # Add and commit an initial file
        readme = repo_root / "README.md"
        readme.write_text("# Test Repo\n")
        run_git(repo_root, "add", "README.md")
        run_git(repo_root, "commit", "-m", "Initial commit")

        # Get git info for a clean file
        cache = {}
        info = get_file_git_info(str(readme), cache)

        # Expect repo detected, branch name available, and status = 'clean'
        assert info["git_repo"] == "yes"
        assert info["git_status"] == "clean"
        assert isinstance(info["git_branch"], str)
        assert len(info["git_branch"]) > 0


def test_modified_file_shows_dirty():
    """
    Create a repo with clean and modified files,
    and check that get_file_git_info() reports correct Git status.
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        repo_root = Path(tmpdir)
        run_git(repo_root, "init")
        run_git(repo_root, "config", "user.name", "Tester")
        run_git(repo_root, "config", "user.email", "test@example.com")

        # Create and commit clean files
        for f in ["clean1.txt", "clean2.txt"]:
            (repo_root / f).write_text("clean content\n")
        run_git(repo_root, "add", ".")
        run_git(repo_root, "commit", "-m", "initial commit")

        # Modify one file
        mod_file = repo_root / "clean1.txt"
        mod_file.write_text("modified content\n")

        cache = {}

        # Check modified file
        mod_info = get_file_git_info(str(mod_file), cache)
        assert mod_info["git_status"] == "dirty"
        assert mod_info["git_repo"] == "yes"

        # Check unmodified file
        clean_file = repo_root / "clean2.txt"
        clean_info = get_file_git_info(str(clean_file), cache)
        assert clean_info["git_status"] == "clean"
        assert clean_info["git_repo"] == "yes"


def test_modified_file_detects_dirty_status():
    """
    Regression test:
    Ensure that get_file_git_info() reports 'dirty' for a modified (unstaged) file.

    Scenario:
    - Create a repo and commit an initial file (Contributing.md)
    - Modify the file without staging
    - Expect get_file_git_info() to return git_status == 'dirty'
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        repo_root = Path(tmpdir)
        run_git(repo_root, "init")
        run_git(repo_root, "config", "user.name", "Test User")
        run_git(repo_root, "config", "user.email", "test@example.com")

        # Create and commit initial Contributing.md
        contrib_file = repo_root / "Contributing.md"
        contrib_file.write_text("Original contribution guide\n")
        run_git(repo_root, "add", "Contributing.md")
        run_git(repo_root, "commit", "-m", "Add Contributing.md")

        # Modify the file but do NOT stage it
        contrib_file.write_text("Modified contribution guide\n")

        # Confirm git sees it as modified
        porcelain = run_git(repo_root, "status", "--porcelain=v2")
        assert any("Contributing.md" in line for line in porcelain), (
            "Git porcelain output should include modified file."
        )

        # Run your extension function
        cache = {}
        info = get_file_git_info(str(contrib_file), cache)

        # Expect status to be dirty
        assert info["git_repo"] == "yes"
        assert info["git_status"] == "dirty", (
            f"Expected dirty status, got {info['git_status']!r}"
        )
        assert isinstance(info["git_branch"], str)
        assert len(info["git_branch"]) > 0