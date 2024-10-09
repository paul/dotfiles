return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "storm" },
  },
  {
    "EdenEast/nightfox.nvim",
    opts = {
      options = {
        styles = {
          comments = "italic",
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
