return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        numbers = "ordinal",
      }
    },
    keys = {
      { "<leader>]", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
      { "<leader>[", "<Cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
      { "<leader>}", "<Cmd>BufferLineMoveNext<CR>",  desc = "Move buffer forward" },
      { "<leader>{", "<Cmd>BufferLineMovePrev<CR>",  desc = "Move buffer backward" },
      {
        "<leader>1",
        function()
          require("bufferline").go_to_buffer(1, true)
        end,
        desc = "Go to Buffer 1",
      },
      {
        "<leader>2",
        function()
          require("bufferline").go_to_buffer(2, true)
        end,
        desc = "Go to Buffer 2",
      },
      {
        "<leader>3",
        function()
          require("bufferline").go_to_buffer(3, true)
        end,
        desc = "Go to Buffer 3",
      },
      {
        "<leader>4",
        function()
          require("bufferline").go_to_buffer(4, true)
        end,
        desc = "Go to Buffer 4",
      },
      {
        "<leader>5",
        function()
          require("bufferline").go_to_buffer(5, true)
        end,
        desc = "Go to Buffer 5",
      },
      {
        "<leader>6",
        function()
          require("bufferline").go_to_buffer(6, true)
        end,
        desc = "Go to Buffer 6",
      },
      {
        "<leader>7",
        function()
          require("bufferline").go_to_buffer(7, true)
        end,
        desc = "Go to Buffer 7",
      },
      {
        "<leader>8",
        function()
          require("bufferline").go_to_buffer(8, true)
        end,
        desc = "Go to Buffer 8",
      },
      {
        "<leader>9",
        function()
          require("bufferline").go_to_buffer(9, true)
        end,
        desc = "Go to Buffer 9",
      },
    },
  },
}
