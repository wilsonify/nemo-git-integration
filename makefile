# Makefile

all: uninstall install

install:
	@echo "Running install script..."
	@./install.sh || { echo "Installation failed"; exit 1; }

uninstall:
	@echo "Running uninstall script..."
	@./uninstall.sh || { echo "Uninstallation failed"; exit 1; }

dev:
	@echo "Setting up project environment..."
	python -m pip install --upgrade pip
	python -m pip install --upgrade pytest

test:
	@echo "Running shell script tests..."
	bats tests/*

test-python:
	@echo "Running Python tests..."
	@./run_python_tests.py all

test-python-unit:
	@echo "Running Python unit tests..."
	@./run_python_tests.py unit

test-python-integration:
	@echo "Running Python integration tests..."
	@./run_python_tests.py integration

test-python-security:
	@echo "Running Python security tests..."
	@./run_python_tests.py security

test-python-performance:
	@echo "Running Python performance tests..."
	@./run_python_tests.py performance

test-python-regression:
	@echo "Running Python regression tests..."
	@./run_python_tests.py regression

test-all: test test-python
	@echo "All tests completed!"

.PHONY: all install uninstall dev test test-python test-python-unit test-python-integration test-python-security test-python-performance test-python-regression test-all
