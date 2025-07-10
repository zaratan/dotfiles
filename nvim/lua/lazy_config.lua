-- vim.cmd([[
-- if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
--   silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
--         \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
--   autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
-- endif
--
-- call plug#begin('~/.vim/plugged')
-- Plug 'tpope/vim-commentary'
-- Plug 'bling/vim-airline'
-- Plug 'm4xshen/hardtime.nvim'
-- Plug 'ggandor/leap.nvim'
-- Plug 'tris203/precognition.nvim'
--
-- call plug#end()
-- ]])

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "solarized-osaka" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
