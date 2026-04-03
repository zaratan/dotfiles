return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        "fzf-vim",
      })

      vim.keymap.set("n", ";", require("fzf-lua").buffers)

      vim.keymap.set("n", "<Leader>e", function()
        local ok = pcall(require("fzf-lua").git_files, { show_untracked = true })
        if not ok then
          require("fzf-lua").files()
        end
      end, { desc = "Find files (git or fallback)" })

      vim.keymap.set("n", "<Leader>f", require("fzf-lua").live_grep, { desc = "Live grep" })

      vim.api.nvim_create_user_command("Ag", function(opts)
        require("fzf-lua").grep({ search = opts.args })
      end, { nargs = "?", desc = "Grep (fzf-lua)" })
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
    "tris203/precognition.nvim",
    opts = {
      startVisible = false,
    },
    config = function(_, opts)
      require("precognition").setup(opts)
      vim.keymap.set("n", "<LEADER>?", require("precognition").toggle)
    end,
  },
}
