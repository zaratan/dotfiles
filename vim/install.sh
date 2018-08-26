pip3 install unidecode neovim
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
if [[ ! -d ~/.vim/undo ]]; then
  mkdir ~/.vim/undo
fi
