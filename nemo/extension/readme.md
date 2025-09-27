# Nemo Git Integration Extension

This extension is designed for the **Nemo File Manager**. It provides additional columns in the **List View** related to the Git status of files and integrates Git actions using emblems.

---

## Requirements

- **Nemo** (>= 5.6.4)  

- **Development libraries** (if building or extending the extension):

```bash
sudo apt-get install libglib2.0-dev
```

---

## Installation

Run the top-level install script from the repository root:

```bash
./install.sh
```

This script will:

- Copy the Python extension to `~/.local/share/nemo-python/extensions/`  
- Install the GSettings schema (`org.nemo.extensions.nemo-file-checker.gschema.xml`) into `/usr/share/glib-2.0/schemas/` (requires `sudo`)  
- Recompile schemas and restart Nemo automatically  

If Nemo doesn’t restart automatically, you can manually restart it:

```bash
nemo -q && nemo &
```

---

## Managing the Extension

In Nemo, enable or disable extensions via:  

**Edit → Plugins**

You should see **Nemo Git Integration** (or `nemo-git-status`) in the plugin list.

---

## Troubleshooting

- **Extension not visible**:  
  Ensure `python3-nemo` is installed and the extension files exist in the correct directory:

```bash
ls ~/.local/share/nemo-python/extensions/
```

- **Schema errors**:  
  Verify the schema XML is installed in `/usr/share/glib-2.0/schemas/` and recompile schemas:

```bash
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
```

- **Missing dependencies**:  
  Install any required development packages (e.g., `libglib2.0-dev`) if building or extending Nemo extensions.

---

## References

- [Ask Ubuntu: How to install Nemo extensions?](https://askubuntu.com/questions/824719/how-to-install-nemo-extensions)  
- [Nemo extensions on GitHub](https://github.com/linuxmint/nemo-extensions)

