# nemo-git-integration

Use git commands from nemo file explorer

Nemo is the official file manager of the Cinnamon desktop environment. 

Cinnamon is a fork of GNOME Files (formerly Nautilus).


# Get Started 

```
make install
make uninstall
```

1. use debian as your operating system. probably works with red hat but it is not tested.  

2. use cinnnamon as you windows manager  

3. use nemo as your file explorer.
   
5. copy all *.nemo_action files to your ~/.local/share/nemo/actions or ```make install``` as mentioned above.

6. Zenity is used for graphical dialogs. if you don't have it then you can install it with apt ```sudo apt install zenity```

![image](https://github.com/wilsonify/nemo-git-integration/assets/26659886/e41bb677-e998-4b50-9ddc-af0f1370aff1)

# Usage

1a. **Initialize a Directory into a Repository**
   
   - Right-click on a folder and select "Git Initialize" from the context menu.
   - This action initializes the selected directory as a Git repository by creating a `.git` folder inside it, similar to running `git init` from the command line.

1b. **Clone an Existing Git Repository**
   
   - Right-click on a folder and select "Git Clone" from the context menu.
   - A dialog will pop up prompting you to specify the URL of the repository you want to clone.
   - After entering the URL, the repository will be cloned into the selected folder, similar to running `git clone <url>` from the command line.

2a. **Add a File to the Working Tree**
   
   - To add a file to the working tree, simply right-click on the file you want to add and select "Git Add" from the context menu.
   - This action stages the selected file for the next commit, similar to running `git add <file>` from the command line.

2b. **Remove a File from the Working Tree**
   
   - To remove a file from the working tree, right-click on the file you want to remove and select "Git Remove" from the context menu.
   - This action removes the selected file from both the working directory and the staging area, similar to running `git rm <file>` from the command line.

3a. **Commit a Change to a File**
   
   - To commit a change to a file, right-click on the file you've modified and select "Git Commit" from the context menu.
   - This action opens a dialog where you can enter a commit message for the change. Once you've entered the message and confirmed, the change will be committed to the repository, similar to running `git commit -m "<message>" <file>` from the command line.

3b. **Uncommit a Change to a File**
   
   - To uncommit a change to a file, right-click on the file and select "Git Undo Commit" from the context menu.
   - This action undoes the last commit that affected the selected file, effectively reverting the changes made in that commit, similar to running `git reset HEAD <file>` from the command line.

4a. **Push Changes to the Remote Named Origin**
   
   - To push changes to the remote repository named "origin", right-click on the folder containing the changes and select "Git Push" from the context menu.
   - This action pushes the committed changes from the local repository to the remote repository, similar to running `git push origin <branch>` from the command line.

4b. **Undo Changes to Match the HEAD of the Current Branch**
   
   - To undo changes to match the HEAD of the current branch, right-click on the folder containing the changes and select "Git Undo Changes" from the context menu.
   - This action discards all local changes and reverts the working directory to match the last commit on the current branch, similar to running `git reset --hard HEAD` from the command line.

5a. **Fetch Information About Remote Changes**
   
   - To fetch information about remote changes, right-click on the folder containing the repository and select "Git Fetch" from the context menu.
   - This action retrieves information about changes from the remote repository without merging them into the local branch, similar to running `git fetch` from the command line.

5b. **Pull Remote Changes into Your Local Copy**
   
   - To pull remote changes into your local copy, right-click on the folder containing the repository and select "Git Pull" from the context menu.
   - This action fetches changes from the remote repository and merges them into the current branch, updating your local copy with the latest changes, similar to running `git pull` from the command line.


![image](https://github.com/wilsonify/nemo-git-integration/assets/26659886/f0c17b0f-f2c7-4d94-9cb0-0abc031782e5)

# How to Contribute

Contributions are welcome! If you want to contribute to this project, follow these steps:

1. Open an Issue so that it can be discussed in the open.
2. Fork this repository.
3. Create a new branch for your feature
4. Make your changes
5. commit them
6. Push them
7. Submit a pull request from your remote into my remote

# Some useful nemo_action stuff to help understand the code

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

sm: Action is available when multiple items are selected and one of them is a folder.

af: Action is available when one or more files are selected.

ad: Action is available when one or more directories are selected.

adf: Action is available when one or more directories or files are selected.


## Run Nemo in Debug Mode

see nemo --help for more details
```
NEMO_DEBUG=Actions,Window nemo --debug
```
