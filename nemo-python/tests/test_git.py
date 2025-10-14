import os
import subprocess
import tempfile

import pytest

from nemo_git_status import (
    run_git,
)


# --------------------------
# Fixtures
# --------------------------

@pytest.fixture
def temp_git_repo():
    """Create a temporary git repository with one commit."""
    with tempfile.TemporaryDirectory() as tmpdir:
        subprocess.run(["git", "init"], cwd=tmpdir, check=True, stdout=subprocess.DEVNULL)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmpdir, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=tmpdir, check=True)

        file_path = os.path.join(tmpdir, "README.md")
        with open(file_path, "w") as f:
            f.write("# Test Repo\n")

        subprocess.run(["git", "add", "."], cwd=tmpdir, check=True)
        subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=tmpdir, check=True)
        yield tmpdir


# --------------------------
# Core git function tests
# --------------------------

def test_run_git_success(temp_git_repo):
    output = run_git(temp_git_repo, "rev-parse", "--show-toplevel")
    assert os.path.exists(output)
    assert output == temp_git_repo


def test_run_git_failure(temp_git_repo):
    # run_git should gracefully return None for invalid git commands
    result = run_git(temp_git_repo, "not-a-real-command")
    assert result is None
