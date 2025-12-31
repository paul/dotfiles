-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

require("snacks").util.lsp.on(function(_, buffer)
  -- Show diagnostics in hover window on current line
  -- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#show-line-diagnostics-automatically-in-hover-window
  -- https://github.com/LazyVim/LazyVim/discussions/616#discussioncomment-5669287
  -- create the autocmd to show diagnostics
  vim.api.nvim_create_autocmd("CursorHold", {
    group = vim.api.nvim_create_augroup("_auto_diag", { clear = true }),
    -- buffer = buffer,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = "rounded",
        source = "always",
        prefix = " ",
        scope = "cursor",
      }
      vim.diagnostic.open_float(nil, opts)
    end,
  })

  -- Write buffer when focus is lost
  -- vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  -- vim.api.nvim_create_autocmd({ "BufLeave" }, {
  --   command = "silent! write!",
  -- })
end)
