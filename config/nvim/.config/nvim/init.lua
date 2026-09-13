-- The leader is resolved when a mapping is created, so set it before any require
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("settings")
require("lazy_config")
