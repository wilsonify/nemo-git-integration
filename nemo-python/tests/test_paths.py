import pytest
from nemo_git_status import uri_to_path, should_skip


# --------------------------
# uri_to_path fuzz tests
# --------------------------

@pytest.mark.parametrize("uri,expected", [
    ("file:/home/user", "/home/user"),  # Valid according to RFC 8089
    ("file://", None),
    ("file:///", "/"),
    ("file:///tmp//double", "/tmp//double"),
    ("file:///home/user/../etc/passwd", "/home/user/../etc/passwd"),
    ("file:///tmp/na%C3%AFve.txt", "/tmp/naïve.txt"),
    ("file:///C:/Users/Test", "/C:/Users/Test"),
    ("file:///tmp/%ZZ.txt", "/tmp/%ZZ.txt"),  # urllib leaves %ZZ unchanged
    ("FILE:///tmp/foo", "/tmp/foo"),
])
def test_uri_to_path_edge_cases(uri, expected):
    """Fuzz edge cases for URI decoding behavior."""
    assert uri_to_path(uri) == expected


# --------------------------
# should_skip fuzz tests
# --------------------------

@pytest.mark.parametrize("path,expected", [
    ("/repo/.git/config", True),
    ("/.git", True),
    ("/repo/.github/workflows", False),
    ("/repo/.gitignore", False),
    ("./.git/config", True),
    ("/repo/.git/", True),
    ("/repo/.git/sub/.git/config", True),
    ("/repo/.GIT/config", False),  # case-sensitive on Linux
    (r"C:\\repo\\.git\\config", True),
])
def test_should_skip_edge_cases(path, expected):
    """Fuzz edge cases for .git detection logic."""
    assert should_skip(path) == expected
