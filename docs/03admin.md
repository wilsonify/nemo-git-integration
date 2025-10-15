Administrator Guide
=====

This guide covers administrative tasks, system setup, and configuration for **Nemo Git Integration**.

---

## System Requirements

- **Operating System:** Debian-based Linux (tested on Linux Mint Debian Edition)  
- **Window Manager:** Cinnamon  
- **File Manager:** Nemo (>= 5.6.4)  
- **Dependencies:**  
  - `nemo-python` – provides Nemo Python extension support  
  - `zenity` – provides graphical dialogs  
  - `git` – version control system  

Install dependencies via:

```bash
sudo apt-get update
sudo apt-get install -y git zenity nemo-python python3-pip

Installation & Updates

Use the provided Makefile for installation and updates:

make install     # Copies *.nemo_action files and scripts to correct locations
make uninstall   # Removes installed actions

Verify Installation

Ensure the following directories and files exist:

ls ~/.local/share/nemo/actions/
ls ~/.local/share/nemo-python/extensions/

Enable the extension in Nemo:

    Open Nemo → Edit → Plugins

    Enable Nemo Git Integration (or nemo-git-status)

Restart Nemo if needed:

nemo -q
nemo &

Configuration
Git User Identity

Many scripts perform Git commits; ensure Git is configured in the CI/user environment:

git config --global user.name "Admin Name"
git config --global user.email "admin@example.com"

For per-repo configuration:

cd /path/to/repo
git config user.name "Repo Admin"
git config user.email "repo@example.com"

Logging & Cache

    Temporary cache files for branch state are stored in:

~/.cache/nemo_git_prev_branch
~/.cache/nemo_git_current_branch

    Zenity logs can be captured for debugging:

export ZENITY_LOG=~/zenity_debug.log

Advanced CI Setup

For automated testing in GitHub Actions:

Configure Git user in the workflow:

Troubleshooting
Issue	Resolution
Scripts not visible in Nemo	Verify nemo-python installed and files exist in ~/.local/share/nemo-python/extensions/
Git commands fail in scripts	Check Git user identity (git config) and permissions
Zenity dialogs fail	Ensure zenity is installed and executable in $PATH
CI tests fail	Make sure the CI runner sets Git user/email and HOME environment correctly