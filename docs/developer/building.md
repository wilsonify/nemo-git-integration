---
layout: default
title: Building and Installing
parent: Developer Guide
nav_order: 1
---

# Building and Installing

This document explains how to build and install the Nemo Git Integration package.

## Quick Install (Debian/Ubuntu)

### From Release (Recommended)

Download the latest `.deb` file from the [Releases](https://github.com/wilsonify/nemo-git-integration/releases) page:

```bash
# Download the latest release
wget https://github.com/wilsonify/nemo-git-integration/releases/latest/download/nemo-git-integration_1.0.0-1_all.deb

# Install
sudo dpkg -i nemo-git-integration_*_all.deb

# Fix any dependency issues
sudo apt-get install -f
```

### From Source

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration

# Install build dependencies
make dev-deps

# Build the .deb package
make deb

# Install
make deb-install
```

## User Installation (No Root Required)

If you prefer not to use the system package manager:

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration
make install
```

This installs to `~/.local/share/nemo/` for the current user only.

## Build Requirements

To build the Debian package, you need:

```bash
sudo apt-get install dpkg-dev debhelper devscripts fakeroot lintian
```

Or simply run:

```bash
make dev-deps
```

## Runtime Dependencies

The package requires:

- `nemo` (>= 3.0) - The Nemo file manager
- `git` - Git version control
- `jq` - JSON processor
- `zenity` - GTK+ dialog boxes
- `coreutils`, `sed`, `findutils` - Standard Unix utilities

Optional:

- `python3-nemo` - For the git status column extension
- `gitk`, `git-gui` - Git graphical tools

## Build Commands

| Command | Description |
| ------- | ----------- |
| `make deb` | Build unsigned .deb package |
| `make deb-signed` | Build signed .deb package |
| `make deb-install` | Build and install .deb |
| `make deb-remove` | Remove installed package |
| `make lint-deb` | Run lintian checks |
| `make clean-deb` | Clean build artifacts |
| `make release` | Full release build with tests |

## Package Contents

When installed via the `.deb` package, files are placed in:

| Location | Contents |
| -------- | -------- |
| `/usr/share/nemo/actions/` | Nemo action files (`.nemo_action`) |
| `/usr/share/nemo-git-integration/` | Shell scripts for git operations |
| `/usr/share/nemo-python/extensions/` | Python extension for git status |
| `/etc/xdg/nemo/actions/` | Actions menu configuration |

## Uninstalling

### Debian Package

```bash
# Remove package
sudo dpkg -r nemo-git-integration

# Or purge (removes config files too)
sudo dpkg -P nemo-git-integration
```

### User Installation

```bash
make uninstall
```

## Troubleshooting

### Restart Nemo

After installation, restart Nemo for changes to take effect:

```bash
nemo -q && nemo &
```

### Check Installation

```bash
# Verify actions are installed
ls /usr/share/nemo/actions/git*.nemo_action

# Verify scripts are installed
ls /usr/share/nemo-git-integration/

# Check Python extension
ls /usr/share/nemo-python/extensions/nemo_git_status.py
```

### Enable Python Extension

In Nemo, go to **Edit → Plugins** and enable the Git Status extension.

## CI/CD

This project uses GitHub Actions for continuous integration:

- **ci.yml**: Tests package build on Ubuntu 22.04 and 24.04
- **build.yml**: Creates release artifacts when tags are pushed

To create a new release:

```bash
# Update version in debian/changelog
dch -v 1.1.0-1 "New release"

# Commit and tag
git add debian/changelog
git commit -m "Release v1.1.0"
git tag v1.1.0
git push origin main --tags
```

The GitHub Action will automatically build the `.deb` and create a release.
