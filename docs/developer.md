---
layout: default
title: Developer Guide
nav_order: 4
has_children: true
---

# Developer Guide

This extension is designed for the **Nemo File Manager**.

It provides additional columns in the **List View** related to the Git status of files.

This guide is for developers who want to understand, modify, and test the **Nemo Git Integration** actions and extensions.

## 7. Contributing

1. Open an Issue to discuss proposed changes.
1. Fork the repository.
1. Create a feature branch.
1. Implement and test your changes.
1. Commit and push your branch.
1. Submit a Pull Request to the main repository.

## More Resources

- [Building & Installation](developer/building.md)
- [GPG Signing](developer/gpg-signing.md)
- [Maintainer Validation](developer/maintainer-validation.md)
- [Public Key](developer/public-key.asc)

---

## 1. Project Structure

```txt
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

## 2. Development Quick Start

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration
sudo apt-get install -y git zenity nemo-python bats
make install
export PYTHONPATH=$PWD/extensions
make test-all
```

## 3. Development Guidelines

Scripts are organized into CRUD-style categories for clarity:

Category Folder Example Scripts
Create s01-create init, clone, branch
Read s02-read status, log, fetch
Update s03-update pull, add, commit, push
Delete s04-delete reset, uninit, unbranch

### 3.1 Zenity Dialogs

Scripts use Zenity for user dialogs.
To mock Zenity during testing:

```commandline
export PATH="$TEST_DIR:$PATH"
echo '#!/bin/bash' > "$TEST_DIR/zenity"
echo 'echo "[Zenity Mock] $@" >&2' >> "$TEST_DIR/zenity"
chmod +x "$TEST_DIR/zenity"
```

### 3.2 Caching

Branch state is cached in: ```~/.cache/nemo_git_*```

## 4. Developing Nemo Extensions (Python)

The Python-based Nemo extensions add Git-related columns such as repository name, branch, and status.
Reference: [Nemo source code on GitHub](https://github.com/linuxmint/nemo/tree/master/libnemo-extension)

4.1 Key Interfaces from nemo-python

from gi.repository import Nemo, GObject

Nemo.ColumnProvider
Nemo.InfoProvider
Nemo.NameAndDescProvider

Run Tests with Make:

```bash
make test-all                # Shell + Python
make test                    # Shell
make test-python             # All Python tests
make test-python-security    # Security-only tests
make test-python-performance # Performance tests
make test-python-unit        # Unit-only
make test-python-integration # Integration tests
```

## 6. Debugging

### 6.1 Run Nemo in Debug Mode

NEMO_DEBUG=Actions,Window nemo --debug

### 6.2 Capture Zenity Logs

export ZENITY_LOG=~/zenity_debug.log

### Prevent commit errors by setting a Git identity

```bash
git config --global user.name "CI Runner"
git config --global user.email "ci@example.com"
```

## Action Syntax Cheatsheet

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

## Explanation

"$1" is the path to the current directory (%P in .nemo_action).

"$@" handles the selected files (%F in .nemo_action).
