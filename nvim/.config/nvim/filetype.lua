vim.g.do_filetype_lua = 1

vim.filetype.add({
  pattern = {
    [".env.*"] = "sh",
  },
})
