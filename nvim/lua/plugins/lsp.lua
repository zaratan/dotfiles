return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable("ruby_lsp")
      vim.lsp.enable("vtsls")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("prismals")

      vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { silent = true, noremap = true, desc = "LSP rename" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostics" })
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

      vim.lsp.inlay_hint.enable(true)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Go to references" })
          vim.keymap.set("n", "gv", "<cmd>vs | lua vim.lsp.buf.definition()<cr>", { buffer = ev.buf, desc = "Go to definition (vsplit)" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover" })
        end,
      })
    end,
  },
}
