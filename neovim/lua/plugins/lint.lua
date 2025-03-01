return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ruby = { "rubocop", "prettierd" },
          javascript = { "eslint_d", "eslint", "prettierd", stop_after_first = true },
          javascriptreact = { "eslint_d", "eslint", "prettierd", stop_after_first = true },
          typescript = { "eslint_d", "eslint", "prettierd", stop_after_first = true },
          typescriptreact = { "eslint_d", "eslint", "prettierd", stop_after_first = true },
          json = { "prettierd" },
          jsonc = { "prettierd" },
          yaml = { "prettierd" },
          markdown = { "prettierd" },
          eruby = { "htmlbeautifier" },
          html = { "prettierd" },
          css = { "prettierd" },
          lua = { "stylua" },
        },

        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 1000,
          lsp_format = "fallback",
        },
      })
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format({ async = true, lsp_format = "fallback", range = range })
      end, { range = true })
    end,
  },
}
