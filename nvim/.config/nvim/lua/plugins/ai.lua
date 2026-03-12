return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      interactions = {
        chat = {
          adapter = {
            name = "openai",
            model = "gpt-5.2",
          },
        },
        inline = {
          adapter = "openai",
        },
        cmd = {
          adapter = "openai",
        },
        background = {
          adapter = "openai",
        },
      },
      -- extensions = {
      --   mcphub = {
      --     callback = "mcphub.extensions.codecompanion",
      --     opts = {
      --       show_result_in_chat = true, -- Show mcp tool results in chat
      --       make_vars = true, -- Convert resources to #variables
      --       make_slash_commands = true, -- Add prompts as /slash commands
      --     },
      --   },
      -- },
      opts = {
        log_level = "DEBUG",
      },
    },
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion: Actions", mode = { "n", "v" } },
      { "<leader>ax", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion: Open Chat", mode = { "n", "v" } },
      { "<leader>aq", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion: Open Inline Assistant", mode = { "n", "v" } },
    },
  },
  {
    "choplin/code-review.nvim",
    config = function()
      require("code-review").setup({
        comment = {
          storage = {
            backend = "file",
            file = {
              dir = ".code-review", -- Default: project root/.code-review/
            },
          },
          claude_code_author = "Review Agent",
          -- Enable filename-based status management (only works with file storage backend)
          -- When enabled, review files are prefixed with status (action-required_, waiting-review_, resolved_)
          status_management = true,
        },
        output = {
          format = "minimal",
        },
      })
    end,
  },
  { "sindrets/diffview.nvim" },
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
        providers = {
          -- copilot = {
          --   transform_items = function(ctx, items)
          --     for _, item in ipairs(items) do
          --       item.kind_icon = ""
          --       item.kind_name = "Copilot"
          --     end
          --     return items
          --   end,
          -- },
        },
      },
    },
  },
}
