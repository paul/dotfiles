
return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  -- Syntax/Languages
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use { 'tpope/vim-cucumber' }
  use { 'tpope/vim-markdown' }
  use { 'vim-ruby/vim-ruby' }
  use { 'tpope/vim-rails' }
  use { 'tpope/vim-endwise' }

  -- UI
  use { 'akinsho/nvim-bufferline.lua', requires = 'kyazdani42/nvim-web-devicons'}
  use { 'lewis6991/gitsigns.nvim', requires =  'nvim-lua/plenary.nvim'  }
  use { 'hoob3rt/lualine.nvim', requires = 'kyazdani42/nvim-web-devicons' }
  use { 'nvim-telescope/telescope.nvim', requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}} }

  use { 'hrsh7th/nvim-compe' }

  -- Util
  use { 'w0rp/ale' }

  use { 'tpope/vim-fugitive' }
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

  -- themes
  use 'folke/tokyonight.nvim'
end)
