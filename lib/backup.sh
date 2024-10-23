#!/usr/bin/env bash

# Backup files that are provided by the dotfiles into a ~/dotfiles-backup directory

DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"

set -e # Exit immediately if a command exits with a non-zero status

echo "Creating backup directory at $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to backup a file or directory
backup_item() {
    local target="$1"
    local backup_name="$2"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up $backup_name"
        if [ -d "$target" ]; then
            cp -rf "$target" "$BACKUP_DIR"
        else
            mv "$target" "$BACKUP_DIR"
        fi
    else
        echo "$backup_name does not exist at this location or is a symlink"
    fi
}

# Backup symlink files
linkables=$(find -H "$DOTFILES" -maxdepth 3 -name '*.symlink')
for file in $linkables; do
    filename=".$(basename "$file" '.symlink')"
    backup_item "$HOME/$filename" "$filename"
done

# Backup specific files and directories
files=("$HOME/.config/nvim" "$HOME/.vim" "$HOME/.vimrc")
for filename in "${files[@]}"; do
    backup_item "$filename" "$filename"
done
