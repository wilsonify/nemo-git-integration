Developer Guide
=====

This guide is for developers who want to understand, modify, and test the **Nemo Git Integration** scripts and extensions.

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

Folder	Purpose
s01-create	init, clone, branch
s02-read	status, log, fetch
s03-update	pull, add, commit, push
s04-delete	reset, uninit, unbranch

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

Python scripts in nemo-python/extensions/ define columns for Git repo, branch, and status.

Use PYTHONPATH to include extensions/ for testing.

Columns are implemented with 

* Nemo.ColumnProvider
* Nemo.InfoProvider
* Nemo.NameAndDescProvider


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