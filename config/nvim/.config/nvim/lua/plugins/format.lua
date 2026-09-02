-- Ruby : on suit le choix du projet plutôt que d'imposer le mien.
--   pas de Gemfile, ou Gemfile sans linter connu -> syntax_tree
--   rubocop et/ou syntax_tree déclarés           -> ceux-là, dans cet ordre
--   un autre linter déclaré                      -> rien d'automatique
-- On lit le Gemfile et pas le Gemfile.lock : le lock contient les dépendances
-- transitives (standard tire rubocop), ce qui ferait matcher rubocop sur un
-- projet qui a choisi autre chose.
local OTHER_RUBY_LINTERS = { "standard", "rufo", "rubyfmt", "prettier" }

local gemfile_cache = {}

local function declared_gems(gemfile)
  local stat = vim.uv.fs_stat(gemfile)
  local mtime = stat and stat.mtime.sec
  local cached = gemfile_cache[gemfile]
  if cached and cached.mtime == mtime then
    return cached.gems
  end

  local gems = {}
  local ok, lines = pcall(vim.fn.readfile, gemfile)
  if ok then
    for _, line in ipairs(lines) do
      local name = line:match("^%s*gem%s+['\"]([%w_.-]+)['\"]")
      if name then
        gems[name] = true
        -- rubocop-rails, syntax_tree-haml... valent pour leur gem parente
        local parent = name:match("^([%w_]+)%-")
        if parent then
          gems[parent] = true
        end
      end
    end
  end

  gemfile_cache[gemfile] = { mtime = mtime, gems = gems }
  return gems
end

local function ruby_formatters(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    path = vim.fn.getcwd()
  end

  local gemfile = vim.fs.find("Gemfile", { upward = true, path = path, type = "file" })[1]
  if not gemfile then
    return { "syntax_tree" }
  end

  local gems = declared_gems(gemfile)
  for _, linter in ipairs(OTHER_RUBY_LINTERS) do
    if gems[linter] then
      return {}
    end
  end

  local formatters = {}
  if gems.rubocop then
    table.insert(formatters, "rubocop")
  end
  if gems.syntax_tree then
    table.insert(formatters, "syntax_tree")
  end

  return #formatters > 0 and formatters or { "syntax_tree" }
end

return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ruby = ruby_formatters,
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
          scss = { "prettierd" },
          lua = { "stylua" },
        },

        format_on_save = function(bufnr)
          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          -- Projet équipé d'un autre linter : on ne touche à rien, pas même via
          -- le LSP — sans ça, lsp_format = "fallback" laisserait ruby-lsp formater.
          if vim.bo[bufnr].filetype == "ruby" and #ruby_formatters(bufnr) == 0 then
            return
          end
          return { timeout_ms = 2000, lsp_format = "fallback" }
        end,
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
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          -- FormatDisable! will disable formatting just for this buffer
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })
      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
    end,
  },
}
