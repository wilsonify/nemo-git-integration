"""
pytest configuration and fixtures for nemo-git-integration tests
"""

import sys

import pytest


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
