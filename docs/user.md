# User Guide

This guide explains how to use **Nemo Git Integration** as an end-user.  
It assumes you have **Nemo** (the Cinnamon file manager) installed.

---

![Screenshot from 2025-10-30 09-26-24.png](../Screenshot%20from%202025-10-30%2009-26-24.png)

---

## Using Git Actions

All Git actions are accessed via **right-click** on files or folders in Nemo.

### 1. Create

- **Git Init** – Initialize a folder as a Git repository.  
- **Git Clone** – Clone a remote repository.  
- **Git Branch** – Create and switch to a new branch.

### 2. Read

- **Git Status** – Shows working tree state.  
- **Git Log** – View recent commits.  
- **Git Fetch** – Sync with remote without merging.

### 3. Update

- **Git Pull** – Merge remote changes into the current branch.  
- **Git Add** – Stage selected files.  
- **Git Commit** – Commit staged changes.  
- **Git Push** – Push commits to the remote repository.

### 4. Delete / Undo

- **Git Reset** – Undo changes in the working directory.  
- **Git Uninit** – Remove `.git` directory.  
- **Git Unclone** – Delete cloned repository.  
- **Git Unbranch** – Delete a local branch.  
- **Git Unpull / Unadd / Uncommit / Unpush** – Roll back previous operations.

---

## Tips

- Zenity dialogs are used for confirmations and errors.  
- Columns show Git status in the Nemo list view.  

## More Resources

- [Uninstall Guide](user/uninstall.md) - Complete uninstallation instructions
- [Developer Guide](developer.md) - For modifying the scripts
- [Administrator Guide](admin.md) - For system setup and configuration
