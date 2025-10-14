# Nemo Git Integration – Developer Guide

This guide is for developers who want to understand, modify, and test the **Nemo Git Integration** scripts and extensions.

---

## Project Structure

.
├── icons/ # PNG icons for visual enhancements
├── nemo/ # .nemo_action files for context menu integration
│ └── actions/ # Each file corresponds to a specific Git operation
├── nemo-git-integration/ # Scripts grouped by CRUD-like categories
│ ├── s01-create/ # Scripts for repo creation (init, clone, branch)
│ ├── s02-read/ # Scripts for reading repo state (status, log, fetch)
│ ├── s03-update/ # Scripts for updating (pull, add, commit, push)
│ └── s04-delete/ # Scripts for undoing changes (reset, uninit, etc.)
├── nemo-python/ # Python extension columns and helpers
│ └── extensions/
├── tests/ # Bats-compatible shell tests
├── makefile # Install/uninstall and dev commands
├── LICENSE # Licensing information
└── README.md # User-facing documentation


---

## Installation for Development

1. Clone the repository:

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration

    Install dependencies (system + Python):

sudo apt-get update
sudo apt-get install -y git zenity nemo-python python3-pip bats
python3 -m pip install --upgrade pip pytest

    Install the Nemo actions and extensions:

make install

Testing
Bats Tests (Shell scripts)

make test          # Runs Bats tests in `tests/`

Example of a Bats test setup:

#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  cp ../nemo-git-integration/s01-create/s01a-init.sh "$TEST_DIR"
  chmod +x "$TEST_DIR/s01a-init.sh"
}

@test "initializes a git repository" {
  run "$TEST_DIR/s01a-init.sh" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.git" ]
}

Python Tests (Nemo extension)

cd nemo-python
export PYTHONPATH=$PWD/extensions
pytest tests/

Script Development Guidelines

    Scripts are organized by CRUD-like categories:

Folder	Purpose
s01-create	init, clone, branch
s02-read	status, log, fetch
s03-update	pull, add, commit, push
s04-delete	reset, uninit, unbranch

    Scripts use Zenity for dialogs; you can mock zenity in tests:

export PATH="$TEST_DIR:$PATH"
echo '#!/bin/bash' > "$TEST_DIR/zenity"
echo 'echo "[Zenity Mock] $@" >&2' >> "$TEST_DIR/zenity"
chmod +x "$TEST_DIR/zenity"

    Caching of branch state uses ~/.cache/nemo_git_*.

Nemo Extension Development

    Python scripts in nemo-python/extensions/ define columns for Git repo, branch, and status.

    Use PYTHONPATH to include extensions/ for testing.

    Columns are implemented with Nemo.ColumnProvider, Nemo.InfoProvider, and Nemo.NameAndDescProvider.

Example:

from gi.repository import Nemo, GObject

class NemoGitIntegration(GObject.GObject, Nemo.ColumnProvider):
    def get_columns(self):
        return (
            Nemo.Column(
                name="NemoGitIntegration::git_status",
                attribute="git_status",
                label="Git Status",
                description="Working tree state"
            ),
        )

Running in CI (GitHub Actions)

    Set Git user/email to avoid commit errors in temporary repos:

- name: Configure Git
  run: |
    git config --global user.name "CI Runner"
    git config --global user.email "ci@example.com"

    Cache dependencies (e.g., bats) to speed up workflows.

    Run shell tests and Python tests sequentially:

- name: Run Bats tests
  run: make test

- name: Run Pytest
  working-directory: nemo-python
  env:
    PYTHONPATH: ${{ github.workspace }}/nemo-python/extensions
  run: pytest tests/

Debugging

    For shell scripts: Use set -x to trace commands.

    For Python extensions: Run Nemo with debug flags:

NEMO_DEBUG=Actions,Window nemo --debug

    Zenity logs can be captured via:

export ZENITY_LOG=~/zenity_debug.log