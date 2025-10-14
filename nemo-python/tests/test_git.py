import os
import subprocess
import tempfile
import time
import pytest

from nemo_git_status import (
    run_git,
    parse_porcelain_status,
    resolve_repo_root,
    get_file_git_info,
    cache,
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
# Batch Git Command Tests
# --------------------------

def test_run_git_basic(temp_git_repo):
    info = run_git(temp_git_repo)
    assert isinstance(info, dict)
    assert info["git_branch"] in ("master", "main")
    assert info["git_repo"] == ""  # no remote yet
    assert isinstance(info["file_status_map"], dict)
    assert "README.md" not in info["file_status_map"]  # clean repo


def test_run_git_after_change(temp_git_repo):
    # modify a file to trigger dirty state
    readme = os.path.join(temp_git_repo, "README.md")
    with open(readme, "a") as f:
        f.write("extra line\n")

    info = run_git(temp_git_repo)
    assert "README.md" in info["file_status_map"]
    assert info["file_status_map"]["README.md"] == "dirty"


def test_parse_porcelain_status_untracked():
    lines = ["?? newfile.txt"]
    result = parse_porcelain_status(lines)
    assert result["newfile.txt"] == "untracked"


def test_resolve_repo_root(temp_git_repo):
    subdir = os.path.join(temp_git_repo, "subdir")
    os.makedirs(subdir)
    resolved = resolve_repo_root(subdir)
    assert resolved == temp_git_repo


# --------------------------
# File Info and Cache Tests
# --------------------------

def test_get_file_git_info_clean(temp_git_repo):
    readme = os.path.join(temp_git_repo, "README.md")
    info = get_file_git_info(readme)
    assert info["git_branch"] in ("master", "main")
    assert info["git_repo"] == ""
    assert info["git_status"] == "clean"


def test_get_file_git_info_dirty(temp_git_repo):
    readme = os.path.join(temp_git_repo, "README.md")
    with open(readme, "a") as f:
        f.write("dirty\n")
    info = get_file_git_info(readme)
    assert info["git_status"] == "dirty"


def test_cache_reuse(temp_git_repo):
    readme = os.path.join(temp_git_repo, "README.md")

    # populate cache
    info1 = get_file_git_info(readme)
    assert "git_branch" in info1
    t0 = list(cache._data.values())[0][0]

    # immediately fetch again; should not run new git commands
    time.sleep(0.5)
    info2 = get_file_git_info(readme)
    t1 = list(cache._data.values())[0][0]
    assert t0 == t1  # cache reused


def test_invalid_path_handling(tmp_path):
    # should gracefully handle non-git paths
    fakefile = tmp_path / "nofile.txt"
    fakefile.write_text("hello")
    info = get_file_git_info(str(fakefile))
    assert info["git_repo"] == ""
    assert info["git_branch"] == ""
    assert info["git_status"] == ""
