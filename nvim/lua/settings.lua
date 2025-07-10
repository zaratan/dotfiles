vim.cmd([[
set expandtab
set number
set shiftwidth=2
set showmatch
set smartindent
set softtabstop=2
set tw:1337

" Persistent undo !
set undofile                 "turn on the feature  
set undodir=$HOME/.vim/undo  "directory where the undo files will be stored.

set clipboard=unnamed

autocmd Filetype gitcommit setlocal spell textwidth=72
autocmd Filetype eruby.yaml set filetype=yaml

" Magic compatability with tmux
nnoremap ¬      :tabnext<CR>
nnoremap ˙      :tabprevious<CR>
nnoremap <C-t>  :tabnew<CR> 
inoremap ¬      <Esc>:tabnext<CR>i
inoremap ˙      <Esc>:tabprevious<CR>i
inoremap <C-t>  <Esc>:tabnew<CR>

" movement mappings
"let g:tmux_navigator_no_mappings = 1

"nnoremap <silent> <C-L> :TmuxNavigateLeft<cr>
"nnoremap <silent> <C-K> :TmuxNavigateDown<cr>
"nnoremap <silent> <C-J> :TmuxNavigateUp<cr>
"nnoremap <silent> <C-H> :TmuxNavigateRight<cr>

set laststatus=2
let g:airline_powerline_fonts = 1
let g:rustfmt_autosave = 1

set rtp+=/usr/local/opt/fzf

set regexpengine=1

set re=0

if filereadable($HOME . "/.nvimrc.local")
  source $HOME/.nvimrc.local
endif
]])
