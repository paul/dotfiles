function bundle_exec(original_opts)
  return {
    command = "bundle",
    args = vim.list_extend({ "exec", original_opts._opts.command }, original_opts._opts.args),
  }
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        erb_lint = {
          command = "bundle",
          args = { "exec", "erblint", "--autocorrect", "$FILENAME" },
          cwd = require("conform.util").root_file({ ".erb-lint.yml" }),
          stdin = false,
        },
        rubocop = {
          -- This is the normal args, but with -a replaced with --autocorrect-all
          command = "bundle",
          args = {
            "exec",
            "rubocop",
            "--server",
            "--autocorrect-all",
            "--format",
            "quiet",
            "--stderr",
            "--stdin",
            "$FILENAME",
          },
        },
      },
      -- Define your formatters
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "standardjs" },
        ruby = { "rubocop" },
        eruby = { "erb_format" },
      },
      log_level = vim.log.levels.DEBUG,
      -- Customize formatters
      -- formatters = {
      --   shfmt = {
      --     prepend_args = { "-i", "2" },
      --   },
      -- },
      -- Don't set format-on-save, LazyVim handles it
      -- format_on_save = { timeout_ms = 500, lsp_fallback = true },
      -- LazyVim uses these instead
      format = {
        -- timeout_ms = 5000,
        -- async = true,
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      linters_by_ft = {
        markdown = { "vale" },
        -- ruby = { "rubocop" },
        eruby = { "erb_lint" },
        javascript = { "standardjs" },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      -- automatic_installation = { exclude = { "rubocop" } },
      automatic_installation = false,
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true, -- useful for debugging formatter issues
      format = {
        -- handled by conform
        formatting_options = nil,
        timeout_ms = nil,
        -- async = true,
        -- timeout_ms = 2000,
      },
      diagnostics = {
        virtual_text = {
          -- others show on cursor focus
          severity = vim.diagnostic.severity.ERROR,
          source = "if_many",
        },
      },
      servers = {
        ruby_lsp = {},
        -- standardrb = { autostart = false },
        rubocop = { mason = false, enabled = false, autostart = false },
      },
    },
  },
}
