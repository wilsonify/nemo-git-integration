
all: uninstall install

prereq:
	sudo apt update && sudo apt install -y zenity git nemo-python

install:
	@echo "Running install script..."
	@./install.sh || { echo "Installation failed"; exit 1; }

uninstall:
	@echo "Running uninstall script..."
	@./uninstall.sh || { echo "Uninstallation failed"; exit 1; }

dev:
	sudo true
	apt-get update
	apt-get install -y git zenity nemo-python python3-pip
	python -m pip install --upgrade pip
	python -m pip install --upgrade pytest
	git clone https://github.com/bats-core/bats-core.git ~/repos/github.com/bats-core
	cd ~/repos/github.com/bats-core && sudo ./install.sh /usr/local

test:
	bats tests/*
