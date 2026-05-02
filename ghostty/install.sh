#!/bin/zsh

if [ -d "$HOME/.config/ghostty" ]; then
    echo "Directory $HOME/.config/ghostty already exists."
else
  ln -s "$PWD/ghostty" "$HOME/.config/ghostty"
fi
