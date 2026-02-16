nemo-git-integration
=====

Integrate Git directly into the Nemo file explorer via context menus.

Perform common Git operations without opening a terminal or IDE.

Tested primarily on Linux Mint Debian Edition.

Download the latest `.deb` from [Releases](https://github.com/wilsonify/nemo-git-integration/releases):

```bash
# Download and install
wget https://github.com/wilsonify/nemo-git-integration/releases/latest/download/nemo-git-integration_1.0.0-1_all.deb
sudo dpkg -i nemo-git-integration_*.deb
sudo apt-get install -f  # Fix dependencies if needed
```

Build from Source
-----------------

```bash
git clone https://github.com/wilsonify/nemo-git-integration.git
cd nemo-git-integration
make dev-deps     # Install build dependencies
make deb          # Build .deb package
make deb-install  # Install
```

User-only Installation (No Root)
-----------------

Ensure you're running **Debian** with **Cinnamon** as your window manager and **Nemo** as your file explorer.

[Documentation](https://wilsonify.github.io/nemo-git-integration/)

```bash
make install    # Copies *.nemo_action files to the ~/.local/share/nemo/actions folder
make uninstall  # Removes installed actions
```

For complete uninstallation instructions and troubleshooting, see [UNINSTALL.md](docs/UNINSTALL.md).

See [BUILDING.md](BUILDING.md) for detailed build and packaging instructions.

Usage
-----------------

Each action is accessed by right-clicking files or folders in Nemo.

[User Documentation](https://wilsonify.github.io/nemo-git-integration/01user.html)

Single Repo
![a single repo](docs/Screenshot%20from%202025-10-14%2015-15-14.png)

Multi-Repo
![with multiple repos](docs/Screenshot%20from%202025-10-30%2009-26-24.png)

How to Contribute
-----------------

[Developer Documentation](https://wilsonify.github.io/nemo-git-integration/02developer.html)

Managing the extension
-----------------

[Admin Documentation](https://wilsonify.github.io/nemo-git-integration/03admin.html)
