return {
  "nvim-lua/plenary.nvim",
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken",
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}
