
all: uninstall install

install:
	cp -r ./*.nemo_action ~/.local/share/nemo/actions
	cp -r ./*.sh ~/.local/share/nemo/actions

uninstall:
	for f in ./*.nemo_action; do rm -f ~/.local/share/nemo/actions/$$(basename $$f); done;
	for f in ./*.sh; do rm -f ~/.local/share/nemo/actions/$$(basename $$f); done;
