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
	bats tests/*
