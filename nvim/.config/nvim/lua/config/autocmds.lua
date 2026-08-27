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

-- Prevent LSP clients from attaching to codediff:// virtual buffers.
-- codediff.nvim guards its own buffers, but it is lazy-loaded on the
-- :CodeDiff command, so a session restore (persistence.nvim) can read a
-- codediff:// URL before the plugin exists. Without this guard, builtin
-- filetype detection matches the .tf/.rb suffix and LSP servers attach to
-- a URI scheme they cannot handle (terraform-ls panics and exits with
-- code 2). Idempotent with the plugin's own BufReadCmd handler.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("_codediff_lsp_guard", { clear = true }),
  pattern = "codediff:///*",
  callback = function(ev)
    vim.bo[ev.buf].buftype = "nowrite"
    vim.bo[ev.buf].bufhidden = "wipe"
    vim.cmd("noautocmd setlocal filetype=")
  end,
})
