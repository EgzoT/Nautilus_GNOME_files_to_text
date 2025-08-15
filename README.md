# Nautilus GNOME files to text

A Bash script that generates a Markdown-formatted directory tree and file contents listing, ignoring hidden files and directories

## 📁 Adding Scripts to Nautilus (GNOME)

* Copy your files
Place files **Files to text** inside **~/.local/share/nautilus/scripts/** folder

* Make them executable:

```bash
chmod +x ~/.local/share/nautilus/scripts/Files\ to\ text/*.sh
```

## 🖱️ How to use in Nautilus

Open Nautilus (GNOME file manager)

Right-click on any folder

Choose: Scripts → Files to text → Echo | Save to file

### Echo

> The script will open a terminal, generate the text, and wait for you to press Enter.

### Save to file

> The script will saves its output to a file in the same directory as the selection.
