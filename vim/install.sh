pip3 install unidecode neovim
if [[ ! -d ~/.vim/undo ]]; then
  mkdir ~/.vim/undo
fi
if [[ ! -d ~/.config/nvim ]]; then
  mkdir -p ~/.config/nvim
fi
if [[ ! -f ~/.config/nvim/init.vim ]]; then
  ln -s `pwd`/vim/vimrc.symlink `pwd`/../.config/nvim/init.vim
fi
