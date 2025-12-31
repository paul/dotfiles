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
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    -- uncomment the following line to load hub lazily
    --cmd = "MCPHub",  -- lazy load
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    -- uncomment this if you don't want mcp-hub to be available globally or can't use -g
    -- build = "bundled_build.lua", -- Use this and set use_bundled_binary = true in opts  (see Advanced configuration)
    config = function()
      require("mcphub").setup({
        extensions = {
          codecompanion = {
            -- Show the mcp tool result in the chat buffer
            show_result_in_chat = true,
            -- Make chat #variables from MCP server resources
            make_vars = true,
            -- Create slash commands for prompts
            make_slash_commands = true,
          },
        },
      })
    end,
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
