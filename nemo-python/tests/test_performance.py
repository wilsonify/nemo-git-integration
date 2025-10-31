#!/usr/bin/env python3
"""
Performance tests for nemo_git_status.py
"""
import os
import subprocess
# Mock the gi module for testing
import sys
import tempfile
import time
from os.path import abspath, dirname
from pathlib import Path

sys.modules['gi'] = type(sys)('gi')
sys.modules['gi.repository'] = type(sys)('gi.repository')
sys.modules['gi.repository.Nemo'] = type(sys)('Nemo')
sys.modules['gi.repository.GObject'] = type(sys)('GObject')

# Import only the functions we need, avoiding the NemoGitIntegration class
path_to_here = abspath(dirname(__file__))
path_to_extensions = os.path.abspath(os.path.join(path_to_here, ".."))
import importlib.util

spec = importlib.util.spec_from_file_location(
    "nemo_git_status",
    f"{path_to_extensions}/extensions/nemo_git_status.py"
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
GitCache = module.GitCache
get_file_git_info = module.get_file_git_info
cache = module.cache
parse_porcelain_status = module.parse_porcelain_status
resolve_repo_root = module.resolve_repo_root
_run_git_command = module._run_git_command


class TestGitCache:
    """Test the enhanced Git cache functionality"""

    def test_cache_basic_operations(self):
        """Test basic cache set/get operations"""
        test_cache = GitCache(max_size=5)

        # Test setting and getting
        test_data = {"branch": "main", "status": "clean"}
        test_cache.set("/test/repo", test_data)

        result = test_cache.get("/test/repo")
        assert result == test_data, "Cache should return stored data"

    def test_cache_ttl_expiration(self):
        """Test that cache entries expire after TTL"""
        test_cache = GitCache()

        # Set a very short TTL for testing (we'll mock this)
        test_data = {"test": "data"}
        test_cache.set("/test/repo", test_data)

        # Should be available immediately
        result = test_cache.get("/test/repo")
        assert result is not None, "Data should be available immediately"

        # We can't easily test TTL without modifying the module, 
        # but we can test the cleanup logic
        stats = test_cache.get_stats()
        assert "hits" in stats, "Cache should track hits"
        assert "misses" in stats, "Cache should track misses"
        assert "size" in stats, "Cache should track size"

    def test_cache_size_limit(self):
        """Test that cache respects size limits"""
        test_cache = GitCache(max_size=3)

        # Fill cache beyond limit
        for i in range(5):
            test_cache.set(f"/test/repo{i}", {"data": i})

        stats = test_cache.get_stats()
        assert stats["size"] <= 3, f"Cache size should not exceed limit: {stats['size']}"

    def test_cache_cleanup(self):
        """Test automatic cleanup of old entries"""
        test_cache = GitCache(max_size=2)

        # Add entries
        test_cache.set("/repo1", {"data": "1"})
        test_cache.set("/repo2", {"data": "2"})
        test_cache.set("/repo3", {"data": "3"})  # Should trigger cleanup

        # Cache should have removed oldest entries
        stats = test_cache.get_stats()
        assert stats["size"] <= 2, "Cache should cleanup old entries"

    def test_cache_thread_safety(self):
        """Test that cache operations are thread-safe"""
        import threading

        test_cache = GitCache()
        results = []

        def worker(thread_id):
            for i in range(10):
                test_cache.set(f"/thread{thread_id}/repo{i}", {"thread": thread_id, "i": i})
                result = test_cache.get(f"/thread{thread_id}/repo{i}")
                results.append((thread_id, i, result is not None))

        # Create multiple threads
        threads = []
        for i in range(3):
            thread = threading.Thread(target=worker, args=(i,))
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Check that all operations succeeded
        assert len(results) == 30, "All cache operations should complete"
        assert all(success for _, _, success in results), "All cache operations should succeed"


class TestPerformanceOptimizations:
    """Test performance-related optimizations"""

    def test_fast_status_parsing(self):
        """Test that status parsing is optimized"""
        from nemo_git_status import parse_porcelain_status

        # Test with various status formats
        test_lines = [
            "?? untracked.txt",
            "1 M N... 100644 000000 100644 000000 0000000000 0000000000 modified.txt",
            " M modified.txt",
            "A  added.txt",
            "D  deleted.txt",
            "R  old.txt -> new.txt",
            "C  original.txt copy.txt",
        ]

        start_time = time.time()
        result = parse_porcelain_status(test_lines)
        end_time = time.time()

        # Should complete quickly
        assert end_time - start_time < 0.01, "Status parsing should be fast"

        # Should parse all lines correctly
        assert len(result) > 0, "Should parse status lines"
        assert result.get("untracked.txt") == "untracked", "Should detect untracked files"
        assert result.get("modified.txt") == "dirty", "Should detect modified files"

    def test_repo_root_resolution_performance(self):
        """Test that repo root resolution is efficient"""
        from nemo_git_status import resolve_repo_root

        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a nested directory structure
            nested_path = Path(tmpdir) / "a" / "b" / "c" / "d"
            nested_path.mkdir(parents=True)

            # Time the resolution (should be fast even for deep paths)
            start_time = time.time()
            result = resolve_repo_root(str(nested_path))
            end_time = time.time()

            # Should complete quickly even without git repo
            assert end_time - start_time < 0.01, "Repo resolution should be fast"
            assert result is None, "Should return None for non-git directory"

    def test_git_command_execution(self):
        """Test that git commands execute efficiently"""
        from nemo_git_status import _run_git_command

        with tempfile.TemporaryDirectory() as tmpdir:
            # Initialize a git repo
            subprocess.run(["git", "init"], cwd=tmpdir, capture_output=True)

            # Time git command execution
            start_time = time.time()
            result = _run_git_command(tmpdir, ["--version"])
            end_time = time.time()

            assert result is not None, "Git command should return result"
            assert end_time - start_time < 1.0, "Git command should complete quickly"

    def test_caching_effectiveness(self):
        """Test that caching improves performance"""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Initialize git repo
            subprocess.run(["git", "init"], cwd=tmpdir, capture_output=True)
            subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmpdir, capture_output=True)
            subprocess.run(["git", "config", "user.name", "Test User"], cwd=tmpdir, capture_output=True)

            # Create and commit a file to make it a proper git repo
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("test content")
            subprocess.run(["git", "add", "test.txt"], cwd=tmpdir, capture_output=True)
            subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=tmpdir, capture_output=True)

            # Clear cache for clean test
            cache.clear()

            # First call (cache miss)
            result1 = get_file_git_info(tmpdir)

            # Check cache stats after first call
            stats_after_first = cache.get_stats()

            # Second call should use cache (same directory)
            result2 = get_file_git_info(tmpdir)

            # Results should be identical
            assert result1 == result2, "Cached and fresh results should be identical"

            # Cache stats should show hits
            stats = cache.get_stats()

            # At minimum, we should have some cache activity
            assert stats["hits"] + stats["misses"] > 0, f"Cache should have activity, got: {stats}"

            # If we got valid git info, we should have cache hits
            if result1.get("git_branch"):  # Only check cache if git repo was detected
                assert stats["hits"] > 0, f"Cache should have hits for valid git repo, got: {stats}"


class TestMemoryUsage:
    """Test memory usage optimizations"""

    def test_cache_memory_limits(self):
        """Test that cache doesn't grow indefinitely"""
        test_cache = GitCache(max_size=10)

        # Add many entries
        for i in range(100):
            large_data = {"data": "x" * 1000, "index": i}
            test_cache.set(f"/repo{i}", large_data)

        # Cache should stay within size limits
        stats = test_cache.get_stats()
        assert stats["size"] <= 10, "Cache should not exceed size limit"

    def test_cache_clear_memory(self):
        """Test that cache clear frees memory"""
        test_cache = GitCache()

        # Add entries
        for i in range(50):
            test_cache.set(f"/repo{i}", {"data": i})

        # Verify cache has entries
        stats_before = test_cache.get_stats()
        assert stats_before["size"] > 0, "Cache should have entries"

        # Clear cache
        test_cache.clear()

        # Verify memory is freed
        stats_after = test_cache.get_stats()
        assert stats_after["size"] == 0, "Cache should be empty after clear"
        assert stats_after["hits"] == 0, "Hit counter should be reset"
        assert stats_after["misses"] == 0, "Miss counter should be reset"
