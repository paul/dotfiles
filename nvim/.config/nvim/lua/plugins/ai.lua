-- Resolve the repository root for the current file, worktree-aware.
-- git rev-parse --show-toplevel is authoritative: it returns the linked
-- worktree's root, not the parent repo's. This matters because
-- code-review.nvim's own get_project_root() uses vim.fn.finddir(".git"),
-- which only finds directories -- but in a git worktree .git is a FILE
-- (gitlink), so the plugin walks past it and all worktrees share the
-- parent's .code-review. Fall back to a pure-Lua walk-up (vim.uv.fs_stat
-- matches both files and dirs) for non-git directories.
local function find_project_root()
  local here = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  if here == "" then
    here = vim.fn.getcwd()
  end
  local root = vim.fn.systemlist("git -C " .. vim.fn.fnameescape(here) .. " rev-parse --show-toplevel")[1]
  if root and root ~= "" then
    return root
  end
  local dir = here
  while dir ~= "/" do
    if vim.uv.fs_stat(dir .. "/.git") then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd()
end

return {
  {
    "choplin/code-review.nvim",
    config = function()
      require("code-review").setup({
        comment = {
          storage = {
            backend = "file",
            file = {
              dir = find_project_root() .. "/.code-review",
            },
          },
          claude_code_author = "Review Agent",
          -- Enable filename-based status management (only works with file storage backend)
          -- When enabled, review files are prefixed with status (action-required_, waiting-review_, resolved_)
          status_management = true,
        },
        output = {
          format = "minimal",
        },
      })
    end,
  },
  { "sindrets/diffview.nvim" },
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    -- Load the plugin whenever a codediff:// buffer is read (e.g. session
    -- restore), so its BufReadCmd guard + content loader always run before
    -- filetype detection can attach LSP clients to the custom URI scheme.
    event = { "BufReadCmd codediff:///*" },
    opts = {
      highlights = {
        char_brightness = 1.0,
      },
      explorer = {
        view_mode = "tree",
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)
      -- The semantic-token bridge sends the virtual buffer's codediff:// URI
      -- to the real file's LSP client; file-URI-only servers like terraform-ls
      -- panic and exit with code 2. No upstream fix through 2.67.0.
      require("codediff.ui.semantic_tokens").apply_semantic_tokens = function() end
    end,
  },
}
