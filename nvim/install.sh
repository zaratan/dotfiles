#!/bin/zsh

if [ -d "$HOME/.config/nvim" ]; then
    echo "Directory $HOME/.config/nvim already exists."
else
  ln -s "$PWD/nvim" "$HOME/.config/nvim"
fi
