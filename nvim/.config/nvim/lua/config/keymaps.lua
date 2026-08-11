-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.api.nvim_set_keymap

-- Write file on <Enter>
map("n", "<CR>", ":write!<CR>", {})

vim.keymap.set("n", "<leader>cp", function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Copy file path to clipboard" })

vim.keymap.set("v", "<leader>cp", function()
  local path = vim.fn.expand("%")
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  local range = start_line == end_line and tostring(start_line) or (start_line .. "-" .. end_line)
  local result = path .. ":" .. range
  vim.fn.setreg("+", result)
  print("Copied: " .. result)
end, { desc = "Copy relative path with line range" })
