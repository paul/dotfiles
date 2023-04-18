return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function()
      local nls = require("null-ls")
      return {
        sources = {
          nls.builtins.diagnostics.dotenv_linter,

          nls.builtins.diagnostics.rubocop,
          nls.builtins.formatting.rubocop,

          nls.builtins.diagnostics.reek,

          -- enabled by project-local .nvim.lua files
          -- nls.builtins.diagnostics.standardrb,
          -- nls.builtins.formatting.standardrb,
        },
        -- debug = true,
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      format = {
        async = true,
        -- timeout_ms = 2000,
      },
      servers = {
        ruby_ls = {},
        standardrb = { autostart = false }
      }
    },
  },
}
