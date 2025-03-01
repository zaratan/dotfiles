return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = false,
          },
        },
        filetypes = {
          yaml = true,
        },
      })

      vim.keymap.set("i", "<Tab>", function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Super Tab" })
    end,
  },
  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     -- add any options here
  --     notify = {},
  --   },
  --   dependencies = {
  --     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
  --     "MunifTanjim/nui.nvim",
  --     -- OPTIONAL:
  --     --   `nvim-notify` is only needed, if you want to use the notification view.
  --     --   If not available, we use `mini` as the fallback
  --     {
  --       "rcarriga/nvim-notify",
  --     },
  --   },
  -- },
  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = "rafamadriz/friendly-snippets",

    -- use a release tag to download pre-built binaries
    -- version = "v0.*",
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    build = "cargo build --release",
    -- On musl libc based systems you need to add this flag
    -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "normal",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      cmdline = {
        enabled = false,
      },

      -- experimental auto-brackets support
      -- accept = { auto_brackets = { enabled = true } }

      -- experimental signature help support
      keymap = { preset = "enter" },
      completion = {
        documentation = {
          -- Controls whether the documentation window will automatically show when selecting a completion item
          auto_show = true,
        },
      },
    },
  },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     "hrsh7th/cmp-nvim-lsp",
  --     "hrsh7th/cmp-buffer",
  --     "hrsh7th/cmp-path",
  --     -- "hrsh7th/cmp-cmdline",
  --     {
  --       "SirVer/ultisnips",
  --       dependencies = {
  --         "honza/vim-snippets",
  --         "epilande/vim-es2015-snippets",
  --         "epilande/vim-react-snippets",
  --       },
  --       config = function()
  --         vim.cmd([[
  --           let g:UltiSnipsSnippetDirectories = ['~/.vim/UltiSnips']
  --           let g:UltiSnipsJumpForwardTrigger="<c-b>"
  --           let g:UltiSnipsJumpBackwardTrigger="<c-z>"
  --         ]])
  --       end,
  --     },
  --     "quangnguyen30192/cmp-nvim-ultisnips",
  --   },
  --   config = function()
  --     local cmp = require("cmp")
  --     cmp.setup({
  --       snippet = {
  --         expand = function(args)
  --           vim.fn["UltiSnips#Anon"](args.body)
  --         end,
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         ["<C-b>"] = cmp.mapping.scroll_docs(-4),
  --         ["<C-f>"] = cmp.mapping.scroll_docs(4),
  --         ["<C-Space>"] = cmp.mapping.complete(),
  --         ["<C-e>"] = cmp.mapping.abort(),
  --         ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --       }),
  --       sources = cmp.config.sources({
  --         { name = "nvim_lsp" },
  --         { name = "ultisnips" },
  --         {
  --           name = "buffer",
  --           option = {
  --             get_bufnrs = function()
  --               return vim.api.nvim_list_bufs()
  --             end,
  --           },
  --         },
  --       }),
  --     })
  --     -- -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  --     -- cmp.setup.cmdline({ "/", "?" }, {
  --     --   mapping = cmp.mapping.preset.cmdline(),
  --     --   sources = {
  --     --     { name = "buffer" },
  --     --   },
  --     -- })
  --     --
  --     -- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  --     -- cmp.setup.cmdline(":", {
  --     --   mapping = cmp.mapping.preset.cmdline(),
  --     --   sources = cmp.config.sources({
  --     --     { name = "path" },
  --     --   }, {
  --     --     { name = "cmdline" },
  --     --   }),
  --     --   matching = { disallow_symbol_nonprefix_matching = false },
  --     -- })
  --   end,
  -- },
}
