import pytest
import time
from unittest.mock import patch

from nemo_git_status import uri_to_path, should_skip_path


# --------------------------
# uri_to_path tests
# --------------------------

def test_uri_to_path_valid():
    uri = "file:///home/user/project"
    assert uri_to_path(uri) == "/home/user/project"


def test_uri_to_path_invalid_scheme():
    uri = "http://example.com"
    assert uri_to_path(uri) is None


# --------------------------
# should_skip_path tests
# --------------------------

def test_should_skip_path_inside_git():
    assert should_skip_path("/home/user/project/.git/config") is True


def test_should_skip_path_normal():
    assert should_skip_path("/home/user/project/src") is False
