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
    -- optional: provides snippets for the snippet source
    dependencies = { 
      'rafamadriz/friendly-snippets', 
    },

    -- use a release tag to download pre-built binaries
    version = '1.*',

    -- On musl libc based systems you need to add this flag
    -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      appearance = {
        nerd_font_variant = "normal",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer"},
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },

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
    opts_extend = { "sources.default" }
  },
  {
  "giuxtaposition/blink-cmp-copilot",
}
}
