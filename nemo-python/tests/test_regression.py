import subprocess
import tempfile
from pathlib import Path
from nemo_git_status import parse_status


def run_git(repo_path, *args):
    """Helper to run git commands in the given repo."""
    result = subprocess.run(
        ["git", "-C", str(repo_path), *args],
        capture_output=True,
        text=True,
        check=True,
    )
    result.stdout.strip().splitlines()


def test_e2e_clean_repo_with_branch_info():
    """
    End-to-end regression test:
    - Create a temporary Git repo
    - Add an initial commit
    - Check parse_status output for a clean repo with branch info
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir)
        # Initialize repo
        run_git(repo, "init")
        # Configure minimal user
        run_git(repo, "config", "user.name", "Test User")
        run_git(repo, "config", "user.email", "test@example.com")
        # Add an initial file and commit
        (repo / "README.md").write_text("# Test Repo\n")
        run_git(repo, "add", "README.md")
        run_git(repo, "commit", "-m", "Initial commit")

        # Simulate branch ahead/behind scenario (simulate upstream)
        # For simplicity, we won't add a real remote; just check branch.ab
        status_lines = run_git(repo, "status", "--porcelain=v2", "--branch")

        result = parse_status(status_lines)

        # Regression check: should be 'clean' (or 'clean +0 -0' if branch info exists)
        assert result in ("clean", "clean +0 -0")
