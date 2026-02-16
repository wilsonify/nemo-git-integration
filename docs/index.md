# Nemo Git Integration

Integrate Git directly into the Nemo file explorer via context menus. 

Perform common Git operations without opening a terminal or IDE. 

Tested primarily on Linux Mint Debian Edition.

![](Screenshot%20from%202025-10-14%2015-15-14.png)

# Get Started 

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

- [User Guide](user.md) - Installation and usage
- [Developer Guide](developer.md) - Development and contributing
- [Administrator Guide](admin.md) - System administration
- [User/Uninstall](user/uninstall.md) - Complete uninstallation instructions
- [Developer/Building](developer/building.md) - Test suite documentation
- [Developer/GPG Signing](developer/gpg-signing.md) - GPG signing process
- [Developer/Maintainer Validation](developer/maintainer-validation.md) - Maintainer validation

## Requirements

- Linux Mint or Debian-based system
- Cinnamon desktop environment
- Nemo file manager
- Git 2.0+
- Python 3.6+

## License

MIT License - see [LICENSE](../LICENSE) file for details.
