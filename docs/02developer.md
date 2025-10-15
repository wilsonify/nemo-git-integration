Developer Guide
=====

This extension is designed for the **Nemo File Manager**. 

It provides additional columns in the **List View** related to the Git status of files.

This guide is for developers who want to understand, modify, and test the **Nemo Git Integration** actions and extensions.

---

## Project Structure

```
.
├── icons/                 # PNG icons and README for visual enhancements
├── nemo/                 # Contains .nemo_action files for context menu integration
│   └── actions/          # Each file corresponds to a specific Git operation
├── nemo-git-integration/ # Backing scripts grouped by CRUD-like categories
│   ├── s01-create/       # Scripts for repo creation (init, clone, branch)
│   ├── s02-read/         # Scripts for reading repo state (status, log, fetch)
│   ├── s03-update/       # Scripts for updating (pull, add, commit, push)
│   └── s04-delete/       # Scripts for undoing changes (reset, uninit, etc.)
├── nemo-python/ # Python extension columns and helpers
│ └── extensions/
├── tests/                # Bats-compatible test scripts for integration logic
├── makefile              # Install/uninstall .nemo_action files
├── LICENSE               # Licensing information
└── README.md             # This documentation
```

---

## Installation for Development

1. Clone the repository:

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration
```

2. Install dependencies (system + Python):

```
sudo apt-get update
sudo apt-get install -y git zenity nemo-python python3-pip bats
python3 -m pip install --upgrade pip pytest
```

3. Install the Nemo actions and extensions:

```
make install
```

4. run the tests
```
make test          # Runs Bats tests in `tests/`
```


5. Python Tests (Nemo extension)

```
cd nemo-python
export PYTHONPATH=$PWD/extensions
pytest tests/
```

# Script Development Guidelines


Scripts are organized by CRUD-like categories:

* s01-create: init, clone, branch
* s02-read: status, log, fetch
* s03-update: pull, add, commit, push
* s04-delete: reset, uninit, unbranch

Scripts use Zenity for dialogs; 

you can mock zenity in tests:
```
export PATH="$TEST_DIR:$PATH"
echo '#!/bin/bash' > "$TEST_DIR/zenity"
echo 'echo "[Zenity Mock] $@" >&2' >> "$TEST_DIR/zenity"
chmod +x "$TEST_DIR/zenity"
```

Caching of branch state uses ~/.cache/nemo_git_*.

# Nemo Extension Development

Python scripts in nemo-python/extensions/ define columns for Git repo, Git branch, and Git status.

Use PYTHONPATH to include extensions/ for testing.

```
from gi.repository import Nemo, GObject
```
* Nemo.ColumnProvider
* Nemo.InfoProvider
* Nemo.NameAndDescProvider

[nemo source code](https://github.com/linuxmint/nemo/tree/master/libnemo-extension)

# Running in CI (GitHub Actions)

Set Git user/email to avoid commit errors in temporary repos:

```
git config --global user.name "CI Runner"
git config --global user.email "ci@example.com"
```


# Debugging

Run Nemo with debug flags:
```
NEMO_DEBUG=Actions,Window nemo --debug
```

capture Zenity logs with:
```
export ZENITY_LOG=~/zenity_debug.log
```


Contributions are welcome! If you want to contribute to this project, follow these steps:

1. Open an Issue so that it can be discussed in the open.
2. Fork this repository.
3. Create a new branch for your feature
4. Make your changes
5. commit them
6. Push them
7. Submit a pull request from your remote into my remote

## Testing

Scripts under `tests/` use [Bats](https://github.com/bats-core/bats-core) for shell testing. Each test corresponds to a script under `nemo-git-integration/`.

```bash
make dev # installs bats
make test # bats tests/*
```

## Run Nemo in Debug Mode

see nemo --help for more details
```
NEMO_DEBUG=Actions,Window nemo --debug
```


# Action Syntax Cheatsheet

Some useful nemo_action stuff to help understand the code

%P: This placeholder represents the full path to the directory containing the selected file or folder. This ensures that the command navigates to the correct directory before executing the Git command.

%F: This represents the full path to the selected file.

%N: This represents the filename without the path, useful for commit messages.

## valid Selection(s)

s: Action is available when only one item is selected.

m: Action is available when multiple items are selected.

a: Action is available when one or more items are selected.

f: Action is available when files are selected.

d: Action is available when directories are selected.

You can combine these values to create more specific conditions. For example:

af: Action is available when one or more files are selected.

ad: Action is available when one or more directories are selected.

adf: Action is available when one or more directories or files are selected.

# Explanation

"$1" is the path to the current directory (%P in .nemo_action).

"$@" handles the selected files (%F in .nemo_action).

Uses zenity --question to confirm reset, which is destructive.

Aggregates errors to show at the end if anything failed.

