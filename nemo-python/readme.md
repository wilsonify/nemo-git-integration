# Python Tests for Nemo Git Integration

This directory contains comprehensive Python tests for the Nemo Git Integration extension.

## Test Structure

### Test Files

- **`test_git.py`** - Core git functionality tests
- **`test_parse_status.py`** - Git status parsing tests  
- **`test_paths.py`** - Path resolution and URI handling tests
- **`test_regression.py`** - Regression tests for critical functionality
- **`test_security.py`** - Security-related tests (injection prevention, validation)
- **`test_performance.py`** - Performance and caching tests
- **`test_integration.py`** - End-to-end integration tests with real git repos

### Test Categories

1. **Unit Tests** - Test individual functions and classes in isolation
2. **Integration Tests** - Test complete workflows with real git repositories
3. **Security Tests** - Verify security measures and input validation
4. **Performance Tests** - Ensure caching and optimizations work correctly
5. **Regression Tests** - Prevent regressions in critical functionality

## Running Tests

### Using the Test Runner Script

```bash
# Run all Python tests
./run_python_tests.py

# Run specific test types
./run_python_tests.py unit
./run_python_tests.py integration
./run_python_tests.py security
./run_python_tests.py performance
./run_python_tests.py regression
```

### Using Make

```bash
# Run all Python tests
make test-python

# Run specific test types
make test-python-unit
make test-python-integration
make test-python-security
make test-python-performance
make test-python-regression

# Run both shell and Python tests
make test-all
```

### Using pytest Directly

```bash
# Run all tests
pytest nemo-python/tests/

# Run specific test file
pytest nemo-python/tests/test_security.py

# Run with verbose output
pytest -v nemo-python/tests/

# Run only security tests
pytest -m security nemo-python/tests/
```

## Test Features

### Security Testing
- Path traversal prevention
- Command injection protection
- Input validation
- URI parsing security
- Environment sanitization

### Performance Testing
- Cache effectiveness
- Memory usage limits
- Response time validation
- Thread safety
- Large repository handling

### Integration Testing
- Real git repository operations
- Multi-branch scenarios
- Dirty/clean status detection
- Remote repository handling
- Nested directory structures

### Error Handling
- Broken repositories
- Permission issues
- Network failures
- Invalid inputs
- Git command failures

## Test Configuration

Tests are configured via `pytest.ini` with the following settings:
- Verbose output
- Colorized results
- Short traceback format
- Custom markers for test categorization
- Warning suppression

## Mock Dependencies

Tests mock the GNOME/gi dependencies to run in headless environments:
- `gi.repository.GObject`
- `gi.repository.Nemo`

This allows tests to run without requiring a full GNOME desktop environment.

## Coverage

The test suite covers:
- ✅ All public functions and classes
- ✅ Error handling paths
- ✅ Security validations
- ✅ Performance optimizations
- ✅ Cache functionality
- ✅ Git command execution
- ✅ URI and path handling
- ✅ Status parsing logic

## Adding New Tests

1. Create test functions starting with `test_`
2. Use descriptive test names
3. Group related tests in classes
4. Add appropriate markers (`@pytest.mark.security`, etc.)
5. Include both positive and negative test cases
6. Test error conditions and edge cases
7. Use fixtures for common setup

Example:
```python
@pytest.mark.security
def test_path_injection_prevention():
    dangerous_path = "/safe/path$rm -rf"
    assert not _is_safe_path(dangerous_path)
```

## Continuous Integration

These tests are designed to run in CI/CD environments and provide:
- Fast feedback (most tests complete in seconds)
- Reliable results (no external dependencies)
- Clear output for debugging
- Comprehensive coverage reporting
