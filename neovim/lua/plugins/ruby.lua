return {
  "joker1007/vim-ruby-heredoc-syntax",
  {
    "HoganMcDonald/rails-rspec-toggle.nvim",
    config = function()
      vim.keymap.set("n", "tt", function()
        require("rails-rspec-toggle").toggle()
      end, { desc = "rails-rspec-toggle.nvim (toggle)" })
    end,
  },
}
