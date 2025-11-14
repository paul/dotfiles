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
          args = { "exec", "erb_lint", "--autocorrect", "$FILENAME" },
          cwd = require("conform.util").root_file({ ".erb-lint.yml" }),
          stdin = false,
        },
        rubocop = {
          -- This is the normal args, but with -a replaced with --autocorrect-all
          command = "rubocop",
          args = {
            "--no-server",
            "--autocorrect-all",
            "--format",
            "quiet",
            "--stderr",
            "--stdin",
            "$FILENAME",
          },
        },
        ruboclean = {
          condition = function(self, ctx)
            return string.find(vim.fs.basename(ctx.filename), ".rubocop.yml$")
          end,
          command = "ruboclean",
          args = { "$FILENAME", "--preserve-comments", "--preserve-paths", "--silent" },
          stdin = false,
        },
        ameba = {
          command = "ameba",
          args = { "--silent", "--fix", "$FILENAME" },
          cwd = require("conform.util").root_file({ "shard.yml" }),
          stdin = false,
        },
      },
      -- Define your formatters
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "biome" },
        typescript = { "biome" },
        ruby = { "rubocop" },
        eruby = { "erb_lint" },
        yaml = { "ruboclean" },
        crystal = { "crystal", "ameba" },
      },
      log_level = vim.log.levels.DEBUG,
      -- Don't set format-on-save, LazyVim handles it
      -- format_on_save = { timeout_ms = 500, lsp_fallback = true },
      -- LazyVim uses these instead
      default_format_opts = {
        timeout_ms = 10000,
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
        javascript = { "biomejs" },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- automatic_installation = { exclude = { "rubocop", "ruby-lsp" } },
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
        ruby_lsp = {
          mason = false,
          init_options = {
            addon_settings = {
              enabledFeatures = {
                formatting = false,
              },
            },
          },
        },
        -- standardrb = { autostart = false },
        rubocop = { mason = false, enabled = false, autostart = false },
        -- solargraph = { mason = false, enabled = false, autostart = false },
        erb_formatter = { mason = false, enabled = false, autostart = false },
        erb_lint = { mason = false, enabled = false, autostart = false },
        yamlls = {
          redhat = { telemetry = { enabled = false } },
          yaml = {
            format = {
              enable = true,
            },
          },
        },
      },
    },
  },
}
