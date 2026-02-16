---
layout: home
title: Home
nav_order: 1
---

# Nemo Git Integration

Integrate Git directly into the Nemo file explorer via context menus.

Perform common Git operations without opening a terminal or IDE.

Tested primarily on Linux Mint Debian Edition.

![right-click menu](Screenshot%20from%202025-10-14%2015-15-14.png)

## Get Started

## Installation

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration
make install
```

## Features

- Right-click git operations in Nemo
- Git status columns in list view
- Support for common git workflows
- Security-hardened command execution
- Performance optimized with caching

## Documentation

- [User Guide]({% link user.md %}) - Installation and usage
- [Administrator Guide]({% link admin.md %}) - System administration
- [Developer Guide]({% link developer.md %}) - Development and contributing
  - [Building & Installation]({% link developer/building.md %}) - Build and test suite
  - [GPG Signing]({% link developer/gpg-signing.md %}) - GPG signing process
  - [Maintainer Validation]({% link developer/maintainer-validation.md %}) - Maintainer validation
- [Uninstall Guide]({% link user/uninstall.md %}) - Complete uninstallation instructions

## Requirements

- Linux Mint or Debian-based system
- Cinnamon desktop environment
- Nemo file manager
- Git 2.0+
- Python 3.6+

## License

MIT License - see [LICENSE](../LICENSE) file for details.
