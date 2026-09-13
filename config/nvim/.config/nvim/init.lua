-- Avant tout require : le leader est résolu à la création de chaque mapping,
-- pas à la frappe. Un mapping posé avant serait rattaché à "\".
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("settings")
require("lazy_config")
