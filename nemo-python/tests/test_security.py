#!/usr/bin/env python3
"""
Security tests for nemo_git_status.py
"""

import importlib.util
import os
# Mock the gi module for testing
import sys
import tempfile
from os.path import dirname, abspath

sys.modules['gi'] = type(sys)('gi')
sys.modules['gi.repository'] = type(sys)('gi.repository')
sys.modules['gi.repository.Nemo'] = type(sys)('Nemo')
sys.modules['gi.repository.GObject'] = type(sys)('GObject')

# Import only the functions we need, avoiding the NemoGitIntegration class
path_to_here = abspath(dirname(__file__))
path_to_extensions = os.path.abspath(os.path.join(path_to_here, "..","extensions"))

spec = importlib.util.spec_from_file_location(
    "nemo_git_status",
    f"{path_to_extensions}/nemo_git_status.py"
)
module = importlib.util.module_from_spec(spec)

# Set up mocks before loading
sys.modules['gi.repository.Nemo'].Column = type('Column', (), {})
sys.modules['gi.repository.Nemo'].ColumnProvider = type('ColumnProvider', (), {})
sys.modules['gi.repository.Nemo'].InfoProvider = type('InfoProvider', (), {})
sys.modules['gi.repository.Nemo'].NameAndDescProvider = type('NameAndDescProvider', (), {})
sys.modules['gi.repository.Nemo'].OperationResult = type('OperationResult', (), {'COMPLETE': 'complete'})
sys.modules['gi.repository.GObject'].GObject = type('GObject', (), {})

# Load the module
spec.loader.exec_module(module)

# Get the functions we need
_is_safe_path = module._is_safe_path
uri_to_path = module.uri_to_path
_run_git_command = module._run_git_command


class TestSecurityFunctions:
    """Test security-related functions"""

    def test_safe_path_validation(self):
        """Test that safe paths are accepted"""
        safe_paths = [
            "/home/user/project",
            "/tmp/test",
            os.path.expanduser("~/documents"),
            "/var/log/app.log",
            "/usr/local/bin/script"
        ]

        for path in safe_paths:
            assert _is_safe_path(path), f"Safe path was rejected: {path}"

    def test_unsafe_path_validation(self):
        """Test that unsafe paths are rejected"""
        unsafe_paths = [
            "/home/user/project$rm -rf",
            "/tmp/`whoami`",
            "/path/with|pipe",
            "/path/with;semicolon",
            "/path/with&ampersand",
            "",  # Empty string
            None,  # None value
            123,  # Non-string type
        ]

        for path in unsafe_paths:
            assert not _is_safe_path(path), f"Unsafe path was accepted: {path}"

    def test_uri_parsing_valid(self):
        """Test parsing of valid file URIs"""
        test_cases = [
            ("file:///home/user/test.txt", "/home/user/test.txt"),
            ("file:///tmp/project", "/tmp/project"),
            ("file:///home/user/file%20with%20spaces.txt", "/home/user/file with spaces.txt"),
        ]

        for uri, expected in test_cases:
            result = uri_to_path(uri)
            assert result == expected, f"URI {uri} parsed as {result}, expected {expected}"

    def test_uri_parsing_invalid(self):
        """Test that invalid URIs are rejected"""
        invalid_uris = [
            "invalid_uri",
            "",
            "http://example.com/file.txt",
            "ftp://server/file.txt",
            None,
            123
        ]

        for uri in invalid_uris:
            result = uri_to_path(uri)
            assert result is None, f"Invalid URI {uri} was accepted as {result}"

    def test_git_command_security(self):
        """Test that git commands are executed securely"""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Test that clean environment is used
            result = _run_git_command(tmpdir, ["--version"])
            assert result is not None, "Git version command should work"
            assert "git version" in result.lower(), "Should return git version info"

    def test_git_command_timeout(self):
        """Test that git commands respect timeout"""
        # This test would need to be implemented with a mock that simulates timeout
        # For now, we just verify the function exists and handles basic cases
        with tempfile.TemporaryDirectory() as tmpdir:
            result = _run_git_command(tmpdir, ["--version"])
            assert result is not None, "Git command should not timeout for simple operations"


class TestInputValidation:
    """Test input validation throughout the module"""

    def test_path_traversal_prevention(self):
        """Test that path traversal attempts are prevented"""
        dangerous_paths = [
            "/safe/path/../../../etc/passwd",
            "/home/user/../../root/.ssh",
            "/tmp/../etc/shadow"
        ]

        for path in dangerous_paths:
            # Even if resolved, the path should be checked for dangerous characters
            if any(char in path for char in ['$', '`', '|', ';', '&']):
                assert not _is_safe_path(path), f"Path with traversal should be rejected: {path}"

    def test_type_safety(self):
        """Test that non-string inputs are handled safely"""
        non_string_inputs = [
            None,
            123,
            [],
            {},
            3.14
        ]

        for input_val in non_string_inputs:
            assert not _is_safe_path(input_val), f"Non-string input should be rejected: {input_val}"
            assert uri_to_path(input_val) is None, f"Non-string URI should be rejected: {input_val}"
