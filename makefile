
all: uninstall install

prereq:
	sudo apt update && sudo apt install -y zenity git

install:
	cp -r ./icons ~/.local/share
	cp -r ./nemo ~/.local/share
	cp -r ./nemo-git-integration ~/.local/share
	# Replace __HOME__ with the explicit path in all .nemo_action files
	find $(HOME)/.local/share/nemo -type f -name "*.nemo_action" -exec sed -i "s|__HOME__|$(HOME)|g" {} \;


uninstall:
	@echo "Removing installed files"
	@for file in $(wildcard icons/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/icons/$$(basename $$file)"; done
	@for file in $(wildcard nemo/actions/*); do echo "removing $(basename $$file)"; rm -f "$(HOME)/.local/share/nemo/actions/$$(basename $$file)"; done
	@rm -rf "$(HOME)/.local/share/nemo-git-integration/"
	@echo "Done."

dev:
	git clone https://github.com/bats-core/bats-core.git ~/repos/github.com/bats-core
	cd ~/repos/github.com/bats-core && sudo ./install.sh /usr/local

test:
	bats tests/*
