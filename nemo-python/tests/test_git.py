import os
import subprocess
import tempfile
import time
import pytest

from nemo_git_status import (
    run_git,

    uri_to_path,

    CACHE_TTL,
    GitColumns, get_repo_info, should_skip, get_file_git_info,
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


def test_get_git_info_clean_repo(temp_git_repo):
    cache = {}
    info = get_repo_info(temp_git_repo, cache)
    assert info["git_repo"] == "yes"
    assert "git_branch" in info
    assert info["git_status"] == "clean"


def test_get_git_info_dirty_repo(temp_git_repo):
    cache = {}
    readme = os.path.join(temp_git_repo, "README.md")
    with open(readme, "a") as f:
        f.write("extra line\n")

    subprocess.run(["git", "add", "README.md"], cwd=temp_git_repo, check=True)
    time.sleep(CACHE_TTL + 1)  # expire any prior cache entries
    info = get_repo_info(temp_git_repo, cache)
    assert info["git_status"].startswith("dirty")


def test_get_git_info_detached_head(temp_git_repo):
    """Simulate a detached HEAD by checking out a commit hash."""
    cache = {}
    head_commit = subprocess.check_output(
        ["git", "-C", temp_git_repo, "rev-parse", "HEAD"], text=True
    ).strip()
    subprocess.run(["git", "-C", temp_git_repo, "checkout", head_commit], check=True)
    info = get_repo_info(temp_git_repo, cache)
    assert info["git_branch"].startswith("detached@")


def test_get_git_info_cache_refresh(temp_git_repo):
    """Ensure cache invalidation works after TTL expiry."""
    cache = {}
    first = get_repo_info(temp_git_repo, cache)
    repo_root = subprocess.check_output(
        ["git", "-C", temp_git_repo, "rev-parse", "--show-toplevel"],
        text=True,
    ).strip()
    cache[repo_root] = (time.time() - CACHE_TTL - 2, first)
    refreshed = get_file_git_info(temp_git_repo, cache)
    assert refreshed["git_repo"] == "yes"
    assert "git_branch" in refreshed


# --------------------------
# Helper function tests
# --------------------------







# --------------------------
# GitColumns integration tests (using real repos)
# --------------------------

class DummyFile:
    """Simple replacement for Nemo file object."""
    def __init__(self, uri):
        self.uri = uri
        self.attributes = {}

    def get_activation_uri(self):
        return self.uri

    def add_string_attribute(self, key, value):
        self.attributes[key] = value


def test_gitcolumns_apply_info(temp_git_repo):
    file_uri = f"file://{temp_git_repo}"
    file = DummyFile(file_uri)

    columns = GitColumns()
    info = get_repo_info(temp_git_repo, columns._cache)
    columns._apply_info(file, info)

    assert file.attributes["git_repo"] == "yes"
    assert "git_branch" in file.attributes
    assert file.attributes["git_status"] in ("clean", "dirty")


def test_gitcolumns_update_file_info_full_real(temp_git_repo):
    file_uri = f"file://{temp_git_repo}"
    file = DummyFile(file_uri)
    columns = GitColumns()

    result = columns.update_file_info_full(None, None, None, file)

    # Support both real Nemo enums and stubbed OperationResult objects
    result_value = getattr(result, "name", str(result))
    assert "COMPLETE" in result_value.upper()

    assert file.attributes["git_repo"] == "yes"
    assert "git_branch" in file.attributes
    assert "git_status" in file.attributes



def test_gitcolumns_update_file_info_full_skips_git_dir(temp_git_repo):
    git_config_path = os.path.join(temp_git_repo, ".git", "config")
    file_uri = f"file://{git_config_path}"
    file = DummyFile(file_uri)
    columns = GitColumns()

    result = columns.update_file_info_full(None, None, None, file)

    # Handle both enum constants and introspection stubs
    result_value = getattr(result, "name", str(result))
    assert "COMPLETE" in result_value.upper()

    assert file.attributes["git_repo"] == ""
    assert file.attributes["git_branch"] == ""
    assert file.attributes["git_status"] == ""

