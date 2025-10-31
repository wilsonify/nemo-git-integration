#!/usr/bin/env python3
"""
Integration tests for nemo_git_status.py
Tests the complete workflow and interaction with real git repositories
"""

import pytest
import tempfile
import os
import subprocess
from pathlib import Path

# Mock the gi module for testing
import sys
sys.modules['gi'] = type(sys)('gi')
sys.modules['gi.repository'] = type(sys)('gi.repository')
sys.modules['gi.repository.Nemo'] = type(sys)('Nemo')
sys.modules['gi.repository.GObject'] = type(sys)('GObject')

from nemo_git_status import get_file_git_info, resolve_repo_root, cache


class TestGitIntegration:
    """Test integration with real git repositories"""
    
    @pytest.fixture
    def temp_git_repo(self):
        """Create a temporary git repository with sample content"""
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_path = Path(tmpdir)
            
            # Initialize git repo
            subprocess.run(["git", "init"], cwd=repo_path, capture_output=True, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=repo_path, check=True)
            subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo_path, check=True)
            
            # Create initial commit
            readme = repo_path / "README.md"
            readme.write_text("# Test Repository\n\nThis is a test repo.\n")
            subprocess.run(["git", "add", "README.md"], cwd=repo_path, check=True)
            subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=repo_path, check=True)
            
            yield repo_path
    
    @pytest.fixture
    def dirty_git_repo(self, temp_git_repo):
        """Create a git repository with uncommitted changes"""
        # Modify existing file
        readme = temp_git_repo / "README.md"
        readme.write_text("# Test Repository\n\nThis is a test repo.\n\nModified content.")
        
        # Create new untracked file
        new_file = temp_git_repo / "new_file.txt"
        new_file.write_text("This is a new file.")
        
        return temp_git_repo
    
    @pytest.fixture
    def multi_branch_repo(self, temp_git_repo):
        """Create a git repository with multiple branches"""
        # Create and checkout a new branch
        subprocess.run(["git", "checkout", "-b", "feature/test"], cwd=temp_git_repo, check=True)
        
        # Add something to the new branch
        feature_file = temp_git_repo / "feature.txt"
        feature_file.write_text("Feature branch content.")
        subprocess.run(["git", "add", "feature.txt"], cwd=temp_git_repo, check=True)
        subprocess.run(["git", "commit", "-m", "Add feature"], cwd=temp_git_repo, check=True)
        
        return temp_git_repo
    
    def test_clean_repo_file_info(self, temp_git_repo):
        """Test getting info for files in a clean repository"""
        readme_path = temp_git_repo / "README.md"
        
        info = get_file_git_info(str(readme_path))
        
        assert info["git_status"] == "clean", "File should be clean"
        assert info["git_branch"] == "main", "Should be on main branch"
        # git_repo might be empty if no remote is configured
    
    def test_dirty_repo_file_info(self, dirty_git_repo):
        """Test getting info for files in a dirty repository"""
        readme_path = dirty_git_repo / "README.md"
        new_file_path = dirty_git_repo / "new_file.txt"
        
        readme_info = get_file_git_info(str(readme_path))
        new_file_info = get_file_git_info(str(new_file_path))
        
        assert readme_info["git_status"] == "dirty", "Modified file should be dirty"
        assert new_file_info["git_status"] == "untracked", "New file should be untracked"
    
    def test_repo_root_status(self, temp_git_repo):
        """Test getting status for repository root directory"""
        repo_info = get_file_git_info(str(temp_git_repo))
        
        assert repo_info["git_status"] == "clean", "Repo root should show overall clean status"
        assert repo_info["git_branch"] == "main", "Should show branch info"
    
    def test_multi_branch_info(self, multi_branch_repo):
        """Test getting info from different branches"""
        feature_file = multi_branch_repo / "feature.txt"
        
        info = get_file_git_info(str(feature_file))
        
        assert info["git_branch"] == "feature/test", "Should show current branch"
        assert info["git_status"] == "clean", "Feature file should be clean"
    
    def test_nested_directory_info(self, temp_git_repo):
        """Test getting info for files in nested directories"""
        # Create nested directory structure
        nested_dir = temp_git_repo / "subdir" / "deep"
        nested_dir.mkdir(parents=True)
        
        nested_file = nested_dir / "nested.txt"
        nested_file.write_text("Nested file content.")
        
        subprocess.run(["git", "add", "."], cwd=temp_git_repo, check=True)
        subprocess.run(["git", "commit", "-m", "Add nested file"], cwd=temp_git_repo, check=True)
        
        info = get_file_git_info(str(nested_file))
        
        assert info["git_status"] == "clean", "Nested file should be clean"
        assert info["git_branch"] == "main", "Should detect repo from nested path"
    
    def test_non_git_directory(self):
        """Test getting info for files outside git repositories"""
        with tempfile.TemporaryDirectory() as tmpdir:
            test_file = Path(tmpdir) / "test.txt"
            test_file.write_text("Not in git repo.")
            
            info = get_file_git_info(str(test_file))
            
            assert info["git_repo"] == "", "Should have no repo info"
            assert info["git_branch"] == "", "Should have no branch info"
            assert info["git_status"] == "", "Should have no status info"
    
    def test_git_repo_with_remote(self, temp_git_repo):
        """Test repository with configured remote"""
        # Add a fake remote (we won't actually push to it)
        subprocess.run(["git", "remote", "add", "origin", "https://github.com/test/repo.git"], 
                      cwd=temp_git_repo, check=True)
        
        info = get_file_git_info(str(temp_git_repo / "README.md"))
        
        assert "github.com" in info["git_repo"], "Should show remote URL"
    
    def test_detached_head(self, temp_git_repo):
        """Test repository in detached HEAD state"""
        # Get the first commit hash
        result = subprocess.run(["git", "rev-list", "--max-count=1", "HEAD"], 
                              cwd=temp_git_repo, capture_output=True, text=True, check=True)
        commit_hash = result.stdout.strip()
        
        # Checkout detached HEAD
        subprocess.run(["git", "checkout", commit_hash], cwd=temp_git_repo, check=True)
        
        info = get_file_git_info(str(temp_git_repo / "README.md"))
        
        assert info["git_branch"].startswith("detached@"), "Should show detached HEAD status"
        assert commit_hash[:7] in info["git_branch"], "Should include commit hash"
    
    def test_cache_across_operations(self, temp_git_repo):
        """Test that cache works correctly across multiple operations"""
        cache.clear()
        
        # First call should populate cache
        info1 = get_file_git_info(str(temp_git_repo))
        
        # Second call should use cache
        info2 = get_file_git_info(str(temp_git_repo))
        
        assert info1 == info2, "Cached results should be identical"
        
        stats = cache.get_stats()
        assert stats["hits"] > 0, "Should have cache hits"
    
    def test_performance_with_large_repo(self):
        """Test performance with a repository containing many files"""
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_path = Path(tmpdir)
            
            # Initialize git repo
            subprocess.run(["git", "init"], cwd=repo_path, capture_output=True, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=repo_path, check=True)
            subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo_path, check=True)
            
            # Create many files
            for i in range(100):
                file_path = repo_path / f"file_{i:03d}.txt"
                file_path.write_text(f"Content of file {i}\n")
            
            # Add and commit all files
            subprocess.run(["git", "add", "."], cwd=repo_path, check=True)
            subprocess.run(["git", "commit", "-m", "Add many files"], cwd=repo_path, check=True)
            
            # Test getting info for one of the files
            test_file = repo_path / "file_050.txt"
            
            import time
            start_time = time.time()
            info = get_file_git_info(str(test_file))
            end_time = time.time()
            
            assert info["git_status"] == "clean", "File should be clean"
            assert end_time - start_time < 2.0, "Should complete in reasonable time even for large repos"


class TestErrorHandling:
    """Test error handling in various scenarios"""
    
    def test_broken_git_repository(self):
        """Test handling of corrupted git repositories"""
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_path = Path(tmpdir)
            
            # Initialize git repo
            subprocess.run(["git", "init"], cwd=repo_path, capture_output=True, check=True)
            
            # Corrupt the git directory by removing .git
            git_dir = repo_path / ".git"
            if git_dir.exists():
                import shutil
                shutil.rmtree(git_dir)
            
            # Should handle gracefully
            info = get_file_git_info(str(repo_path))
            
            assert info["git_repo"] == "", "Should handle broken repo gracefully"
            assert info["git_branch"] == "", "Should have no branch info"
            assert info["git_status"] == "", "Should have no status info"
    
    def test_permission_denied(self):
        """Test handling of permission denied scenarios"""
        # This test is limited as we can't easily create permission scenarios
        # We'll test with non-existent paths instead
        info = get_file_git_info("/nonexistent/path/file.txt")
        
        assert info["git_repo"] == "", "Should handle non-existent paths"
        assert info["git_branch"] == "", "Should have no branch info"
        assert info["git_status"] == "", "Should have no status info"
    
    def test_git_command_failure(self):
        """Test handling when git commands fail"""
        from nemo_git_status import _run_git_command
        
        with tempfile.TemporaryDirectory() as tmpdir:
            # Try to run git command in non-repo directory
            result = _run_git_command(tmpdir, ["status"])
            
            # Should handle failure gracefully
            assert result is None or isinstance(result, str), "Should handle git failure gracefully"
