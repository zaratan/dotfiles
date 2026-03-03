vim.opt.expandtab = true
vim.opt.number = true
vim.opt.shiftwidth = 2
vim.opt.showmatch = true
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.textwidth = 1337

-- Persistent undo
local undodir = vim.env.HOME .. "/.vim/undo"
vim.fn.mkdir(undodir, "p")
vim.opt.undofile = true
vim.opt.undodir = undodir

vim.opt.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 72
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "eruby.yaml",
  callback = function()
    vim.bo.filetype = "yaml"
  end,
})

-- Tab navigation (magic compatibility with tmux)
vim.keymap.set("n", "¬", ":tabnext<CR>", { silent = true })
vim.keymap.set("n", "˙", ":tabprevious<CR>", { silent = true })
vim.keymap.set("n", "<C-t>", ":tabnew<CR>", { silent = true })
vim.keymap.set("i", "¬", "<Esc>:tabnext<CR>i", { silent = true })
vim.keymap.set("i", "˙", "<Esc>:tabprevious<CR>i", { silent = true })
vim.keymap.set("i", "<C-t>", "<Esc>:tabnew<CR>", { silent = true })

vim.opt.laststatus = 2

vim.g.rustfmt_autosave = 1

vim.opt.regexpengine = 0

if vim.fn.filereadable(vim.env.HOME .. "/.nvimrc.local") == 1 then
  vim.cmd.source(vim.env.HOME .. "/.nvimrc.local")
end
