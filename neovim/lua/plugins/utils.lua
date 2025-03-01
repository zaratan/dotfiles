return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        "fzf-vim",
      })

      vim.keymap.set("n", ";", require("fzf-lua").buffers)

      vim.cmd([[
        silent! !git rev-parse --is-inside-work-tree
        if v:shell_error == 0
          nmap <Leader>e :GFiles --cached --others --exclude-standard<CR>
        else
          nmap <Leader>e :Files<CR>
        endif
      ]])
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<C-L>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<C-K>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<C-J>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<C-H>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    config = function()
      vim.cmd([[nnoremap \ :Neotree toggle<cr>]])
      require("neo-tree").setup()
    end,
  },
  "rking/ag.vim",
  "tpope/vim-repeat",
  "kshenoy/vim-signature",
  {
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    opts = {
      startVisible = false,
      -- showBlankVirtLine = true,
      -- highlightColor = { link = "Comment" },
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     G = { text = "G", prio = 10 },
      --     gg = { text = "gg", prio = 9 },
      --     PrevParagraph = { text = "{", prio = 8 },
      --     NextParagraph = { text = "}", prio = 8 },
      -- },
      -- disabled_fts = {
      --     "startify",
      -- },
    },
    config = function(_, opts)
      require("precognition").setup(opts)
      vim.keymap.set("n", "<LEADER>?", require("precognition").toggle)
    end,
  },
}
