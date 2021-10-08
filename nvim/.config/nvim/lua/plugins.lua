
return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  -- Syntax/Languages
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use { 'tpope/vim-cucumber' }
  use { 'tpope/vim-markdown' }
  use { 'vim-ruby/vim-ruby' }
  use { 'tpope/vim-rails' }
  use { 'tpope/vim-endwise' }
  use { 'slim-template/vim-slim' }
  use { 'jez/vim-github-hub' }
  use { 'cespare/vim-toml'}
  use { 'fatih/vim-go' }
  use { 'hashivim/vim-terraform'}
  use { 'mechatroner/rainbow_csv' }

  -- UI
  -- use { 'akinsho/nvim-bufferline.lua', requires = 'kyazdani42/nvim-web-devicons'}
  use { 'romgrk/barbar.nvim', requires = 'kyazdani42/nvim-web-devicons' }
  use { 'lewis6991/gitsigns.nvim', requires =  'nvim-lua/plenary.nvim'  }
  use { 'hoob3rt/lualine.nvim', requires = 'kyazdani42/nvim-web-devicons' }
  use { 'nvim-telescope/telescope.nvim', requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}} }

  -- Completion
  use {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/vim-vsnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp"
    }
  }

  -- Util
  use { 'w0rp/ale' }

  use { 'tpope/vim-fugitive' }
  use { 'tpope/vim-rhubarb' } -- Enable :GBrowse
  use { 'tpope/vim-surround' }
  use { 'tpope/vim-repeat' }     -- Allow surround to be repeated with .

  use { 'tpope/vim-commentary' }
  use { 'tpope/vim-eunuch' }     -- Vim sugar for unix commands

  use { 'junegunn/vim-easy-align' }

  -- LSP
  use { 'neovim/nvim-lspconfig' }
  use { 'kabouzeid/nvim-lspinstall' }
  use { 'glepnir/lspsaga.nvim' }
  use { "folke/lsp-trouble.nvim", requires = "kyazdani42/nvim-web-devicons" }
  use { 'simrat39/rust-tools.nvim' }


  -- themes
  use 'folke/tokyonight.nvim'
  -- use 'EdenEast/nightfox.nvim'
  -- use 'mhartington/oceanic-next'
  -- use 'sainnhe/everforest'
end)
