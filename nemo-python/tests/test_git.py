import os
import subprocess
import tempfile
import time
from unittest.mock import patch

import pytest

from nemo_git_status import CACHE_TTL
from nemo_git_status import get_git_info
from nemo_git_status import run_git


@pytest.fixture
def temp_git_repo():
    """Create a temporary git repository for testing."""
    with tempfile.TemporaryDirectory() as tmpdir:
        init_git_repo(tmpdir)
        yield tmpdir


def init_git_repo(path: str):
    """Initialize a temporary git repository with one commit."""
    subprocess.run(["git", "init"], cwd=path, check=True)
    # Configure a user for commits
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.name", "Test User"], cwd=path, check=True)
    # Create an initial file
    file_path = os.path.join(path, "README.md")
    with open(file_path, "w") as f:
        f.write("# Test Repo\n")
    subprocess.run(["git", "add", "."], cwd=path, check=True)
    subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=path, check=True)


# --------------------------
# run_git tests
# --------------------------

@patch("subprocess.check_output")
def test_run_git_success(mock_check_output):
    mock_check_output.return_value = "output\n"
    result = run_git("/tmp", "status")
    assert result == "output"
    mock_check_output.assert_called_once()


@patch("subprocess.check_output", side_effect=subprocess.CalledProcessError(1, "git"))
def test_run_git_failure(mock_check_output):
    result = run_git("/tmp", "status")
    assert result is None
    mock_check_output.assert_called_once()


# --------------------------
# get_git_info tests
# --------------------------


def test_get_git_info_not_a_repo():
    cache = {}
    with tempfile.TemporaryDirectory() as tmpdir:
        init_git_repo(tmpdir)

        # First call: compute git info
        info = get_git_info(tmpdir, cache)
        assert info["git_repo"] == "yes"
        assert info["git_branch"] == "main" or info["git_branch"].startswith("detached@")
        assert info["git_status"] == "clean"


@patch("nemo_git_status.run_git")
def test_get_git_info_branch_and_status(mock_run_git):
    # Simulate sequence of run_git calls
    # 1: repo root
    # 2: branch name
    # 3: status output
    mock_run_git.side_effect = [
        "/tmp",  # repo root
        "main",  # branch
        "# branch.ab +1 -0\nM foo.txt",  # status
    ]
    cache = {}
    info = get_git_info("/tmp", cache)
    assert info["git_repo"] == "yes"
    assert info["git_branch"] == "main"
    assert "dirty" in info["git_status"]


@patch("nemo_git_status.run_git")
def test_get_git_info_detached_head(mock_run_git):
    mock_run_git.side_effect = [
        "/tmp",  # repo root
        "HEAD",  # branch is detached
        "abc123",  # commit hash
        "# branch.ab +0 -0\n",  # status
    ]
    cache = {}
    info = get_git_info("/tmp", cache)
    assert info["git_branch"].startswith("detached@")
    assert "clean" in info["git_status"]


def test_git_info_clean_repo(temp_git_repo):
    """Test that a fresh repository is reported as clean."""
    cache = {}
    info = get_git_info(temp_git_repo, cache)
    assert info["git_repo"] == "yes"
    assert info["git_branch"] == "main" or info["git_branch"].startswith("detached@")
    assert info["git_status"] == "clean"


def test_git_info_dirty_repo(temp_git_repo):
    """Test that modifying a tracked file marks the repo as dirty."""
    cache = {}
    # initial clean status
    get_git_info(temp_git_repo, cache)

    # modify file
    readme_path = os.path.join(temp_git_repo, "README.md")
    with open(readme_path, "a") as f:
        f.write("New line\n")

    # stage change
    subprocess.run(["git", "add", "README.md"], cwd=temp_git_repo, check=True)
    time.sleep(CACHE_TTL + 1)
    info = get_git_info(temp_git_repo, cache)
    assert info["git_repo"] == "yes"
    assert info["git_status"] == "dirty"


def test_git_info_cache_expiry(temp_git_repo):
    """Test that cached git info is recomputed after TTL expiry."""
    cache = {}
    info = get_git_info(temp_git_repo, cache)

    # artificially expire cache
    repo_root = subprocess.check_output(
        ["git", "-C", temp_git_repo, "rev-parse", "--show-toplevel"],
        text=True
    ).strip()
    cache[repo_root] = (time.time() - CACHE_TTL - 1, info)

    info2 = get_git_info(temp_git_repo, cache)
    assert info2["git_repo"] == "yes"
    # branch/status should be recomputed
    assert "git_branch" in info2
    assert "git_status" in info2
