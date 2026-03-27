local M = {}

---@param opts? {cwd?: string, border?: string}
function M.open(opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
  })

  -- open LazyGit inside a terminal
  vim.fn.termopen("lazygit", {
    cwd = opts.cwd or vim.fn.getcwd(),
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  -- better UX
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "terminal"
  vim.cmd.startinsert()
end

-- Keymap example:
vim.keymap.set("n", "<leader>lg", function()
  require("lazygit_float").open()
end, { desc = "Open LazyGit in float" })

return M
