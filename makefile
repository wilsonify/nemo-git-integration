# Makefile
# Nemo Git Integration Build System

VERSION := $(shell head -1 debian/changelog | grep -oP '\(\K[^)]+' | cut -d- -f1)
PACKAGE_NAME := nemo-git-integration
DEB_FILE := $(PACKAGE_NAME)_$(VERSION)_all.deb

# =============================================================================
# User Installation (local, per-user)
# =============================================================================

all: uninstall install

install:
	@echo "Running install script..."
	@./install.sh || { echo "Installation failed"; exit 1; }

uninstall:
	@echo "Running uninstall script..."
	@./uninstall.sh || { echo "Uninstallation failed"; exit 1; }

# =============================================================================
# Development Setup
# =============================================================================

dev:
	@echo "Setting up project environment..."
	python -m pip install --upgrade pip
	python -m pip install --upgrade pytest

dev-deps:
	@echo "Installing Debian build dependencies..."
	sudo apt-get update
	sudo apt-get install -y dpkg-dev debhelper devscripts fakeroot lintian bats

# =============================================================================
# Testing
# =============================================================================

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

# =============================================================================
# Debian Package Building
# =============================================================================

.PHONY: deb
deb: clean-deb
	@echo "Building Debian package..."
	dpkg-buildpackage -us -uc -b
	@echo "Package built: ../$(DEB_FILE)"

.PHONY: deb-signed
deb-signed: clean-deb
	@echo "Building signed Debian package..."
	dpkg-buildpackage -b
	@echo "Signed package built: ../$(DEB_FILE)"

.PHONY: deb-source
deb-source:
	@echo "Building source package..."
	dpkg-buildpackage -us -uc -S

.PHONY: lint-deb
lint-deb:
	@echo "Running lintian on package..."
	lintian ../$(DEB_FILE) || true

.PHONY: deb-install
deb-install: deb
	@echo "Installing Debian package..."
	sudo dpkg -i ../$(DEB_FILE) || sudo apt-get install -f -y

.PHONY: deb-remove
deb-remove:
	@echo "Removing Debian package..."
	sudo dpkg -r $(PACKAGE_NAME)

.PHONY: deb-purge
deb-purge:
	@echo "Purging Debian package..."
	sudo dpkg -P $(PACKAGE_NAME)

# =============================================================================
# Cleaning
# =============================================================================

.PHONY: clean
clean: clean-deb
	@echo "Cleaning build artifacts..."
	rm -rf __pycache__ .pytest_cache
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true

.PHONY: clean-deb
clean-deb:
	@echo "Cleaning Debian build artifacts..."
	rm -rf debian/.debhelper debian/nemo-git-integration debian/debhelper-build-stamp
	rm -f debian/files debian/*.substvars debian/*.debhelper.log
	rm -f ../$(PACKAGE_NAME)_*.deb ../$(PACKAGE_NAME)_*.changes ../$(PACKAGE_NAME)_*.buildinfo
	dh_clean 2>/dev/null || true

# =============================================================================
# Release Helpers
# =============================================================================

.PHONY: version
version:
	@echo "Current version: $(VERSION)"

.PHONY: bump-version
bump-version:
	@echo "To bump version, edit debian/changelog"
	@echo "Use: dch -i  (for increment)"
	@echo "Or:  dch -v VERSION  (for specific version)"

.PHONY: release
release: test-all deb lint-deb
	@echo "Release build complete!"
	@echo "Package: ../$(DEB_FILE)"
	@ls -la ../$(DEB_FILE)

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help:
	@echo "Nemo Git Integration - Build System"
	@echo ""
	@echo "User Installation:"
	@echo "  make install       - Install locally for current user"
	@echo "  make uninstall     - Remove local installation"
	@echo ""
	@echo "Debian Package:"
	@echo "  make deb           - Build unsigned .deb package"
	@echo "  make deb-signed    - Build signed .deb package"
	@echo "  make deb-install   - Build and install .deb package"
	@echo "  make deb-remove    - Remove installed .deb package"
	@echo "  make lint-deb      - Run lintian on .deb package"
	@echo ""
	@echo "Development:"
	@echo "  make dev           - Setup Python dev environment"
	@echo "  make dev-deps      - Install Debian build dependencies"
	@echo ""
	@echo "Testing:"
	@echo "  make test          - Run shell script tests"
	@echo "  make test-python   - Run all Python tests"
	@echo "  make test-all      - Run all tests"
	@echo ""
	@echo "Cleaning:"
	@echo "  make clean         - Clean all build artifacts"
	@echo "  make clean-deb     - Clean Debian build artifacts"
	@echo ""
	@echo "Release:"
	@echo "  make release       - Full release build with tests"
	@echo "  make version       - Show current version"

.PHONY: all install uninstall dev dev-deps test test-python test-python-unit test-python-integration test-python-security test-python-performance test-python-regression test-all help
