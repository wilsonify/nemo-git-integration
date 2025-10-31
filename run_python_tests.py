#!/usr/bin/env python3
"""
Test runner for nemo-git-integration Python tests
"""

import sys
import os
import subprocess
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent
extensions_path = project_root / "nemo-python" / "extensions"
sys.path.insert(0, str(extensions_path))

# Mock the gi module before importing anything else
sys.modules['gi'] = type(sys)('gi')
sys.modules['gi.repository'] = type(sys)('gi.repository')
sys.modules['gi.repository.Nemo'] = type(sys)('Nemo')
sys.modules['gi.repository.GObject'] = type(sys)('GObject')

# Set environment variable for tests
os.environ['PYTHONPATH'] = str(extensions_path) + ':' + os.environ.get('PYTHONPATH', '')


def run_tests(test_type="all"):
    """
    Run tests based on type
    
    Args:
        test_type: Type of tests to run
                  - "all": Run all tests
                  - "unit": Run unit tests only
                  - "integration": Run integration tests only
                  - "security": Run security tests only
                  - "performance": Run performance tests only
                  - "regression": Run regression tests only
    """
    
    test_dir = project_root / "nemo-python" / "tests"
    
    if test_type == "all":
        pytest_args = [str(test_dir)]
    elif test_type == "unit":
        pytest_args = [
            str(test_dir / "test_git.py"),
            str(test_dir / "test_parse_status.py"),
            str(test_dir / "test_paths.py")
        ]
    elif test_type == "integration":
        pytest_args = [str(test_dir / "test_integration.py")]
    elif test_type == "security":
        pytest_args = [str(test_dir / "test_security.py")]
    elif test_type == "performance":
        pytest_args = [str(test_dir / "test_performance.py")]
    elif test_type == "regression":
        pytest_args = [str(test_dir / "test_regression.py")]
    else:
        print(f"Unknown test type: {test_type}")
        return 1
    
    # Add pytest configuration
    pytest_args.extend([
        "-v",
        "--tb=short",
        "--color=yes"
    ])
    
    print(f"Running {test_type} tests...")
    print(f"Command: pytest {' '.join(pytest_args)}")
    print("-" * 60)
    
    try:
        # Set environment for subprocess
        env = os.environ.copy()
        env['PYTHONPATH'] = str(extensions_path)
        
        result = subprocess.run([sys.executable, "-m", "pytest"] + pytest_args, 
                              cwd=project_root, env=env)
        return result.returncode
    except FileNotFoundError:
        print("pytest not found. Installing...")
        subprocess.run([sys.executable, "-m", "pip", "install", "pytest"], check=True)
        # Retry after installation
        env = os.environ.copy()
        env['PYTHONPATH'] = str(extensions_path)
        result = subprocess.run([sys.executable, "-m", "pytest"] + pytest_args, 
                              cwd=project_root, env=env)
        return result.returncode


def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        test_type = sys.argv[1]
    else:
        test_type = "all"
    
    return run_tests(test_type)


if __name__ == "__main__":
    sys.exit(main())
