pip3 install unidecode neovim
if [[ ! -d ~/.vim/undo ]]; then
  mkdir ~/.vim/undo
fi
if [[ ! -d ~/.config/nvim ]]; then
  mkdir -p ~/.config/nvim
fi
ln -s ./vimrc.symlink ~/.config/nvim/init.vim
