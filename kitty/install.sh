#!/bin/zsh

if [ -d "$HOME/.config/kitty" ]; then
    echo "Directory $HOME/.config/kitty already exists."
else
  ln -s "$PWD/kitty" "$HOME/.config/kitty"
fi
