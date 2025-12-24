"""
pytest configuration and fixtures for nemo-git-integration tests
"""

import os
import sys

import pytest

# Add the extensions directory to sys.path so nemo_git_status can be imported
extensions_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'extensions')
if extensions_dir not in sys.path:
    sys.path.insert(0, extensions_dir)


# Create mock classes first
class MockColumn:
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)

class MockColumnProvider:
    pass

class MockInfoProvider:
    pass

class MockNameAndDescProvider:
    pass

class MockOperationResult:
    COMPLETE = "complete"

class MockGObjectBase:
    pass

class MockGObject:
    GObject = MockGObjectBase

# Create mock modules
class MockNemo:
    Column = MockColumn
    ColumnProvider = MockColumnProvider
    InfoProvider = MockInfoProvider
    NameAndDescProvider = MockNameAndDescProvider
    OperationResult = MockOperationResult

class MockRepository:
    Nemo = MockNemo
    GObject = MockGObject

class MockGi:
    repository = MockRepository

# Install mocks in sys.modules
sys.modules['gi'] = MockGi
sys.modules['gi.repository'] = MockRepository
sys.modules['gi.repository.Nemo'] = MockNemo
sys.modules['gi.repository.GObject'] = MockGObject


@pytest.fixture(autouse=True)
def setup_gi_mocks():
    """Automatically setup gi mocks for all tests"""
    # This ensures mocks are available in all test modules
    pass
