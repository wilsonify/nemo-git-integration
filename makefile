
all: uninstall install

prereq:
	sudo apt update && sudo apt install -y zenity git

install:
	@echo "Running install script..."
	@./install.sh || { echo "Installation failed"; exit 1; }

uninstall:
	@echo "Running uninstall script..."
	@./uninstall.sh || { echo "Uninstallation failed"; exit 1; }

dev:
	git clone https://github.com/bats-core/bats-core.git ~/repos/github.com/bats-core
	cd ~/repos/github.com/bats-core && sudo ./install.sh /usr/local

test:
	bats tests/*
