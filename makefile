
all: uninstall install

prereq:
	sudo apt update && sudo apt install -y zenity git

install:
	cp -r ./icons ~/.local/share
	cp -r ./nemo ~/.local/share
	cp -r ./nemo-git-integration ~/.local/share

uninstall:
	@echo "Removing installed files"
	@for file in $(wildcard icons/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/icons/$$(basename $$file)"; done
	@for file in $(wildcard nemo/actions/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo/actions/$$(basename $$file)"; done
	@for file in $(wildcard nemo-git-integration/s01-create/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo-git-integration/s01-create/$$(basename $$file)"; done
	@for file in $(wildcard nemo-git-integration/s02-read/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo-git-integration/s02-read/$$(basename $$file)"; done
	@for file in $(wildcard nemo-git-integration/s03-update/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo-git-integration/s03-update/$$(basename $$file)"; done
	@for file in $(wildcard nemo-git-integration/s04-delete/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo-git-integration/s04-delete/$$(basename $$file)"; done
	@echo "Done."

dev:
	git clone https://github.com/bats-core/bats-core.git ~/repos/github.com/bats-core
	cd ~/repos/github.com/bats-core && sudo ./install.sh /usr/local

test:
	bats tests/*
