local Util = require("lazyvim.util")
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {

      -- By default, looks for files in the "root" dir, which is annoying in a monorepo
      -- Look in the cwd instead
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    },
  },
}
