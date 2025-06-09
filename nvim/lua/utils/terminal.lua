-- Floating terminal configuration
local M = {}

-- Terminal window options
local terminal_options = {
  relative = "editor",
  width = math.floor(vim.o.columns * 0.8),
  height = math.floor(vim.o.lines * 0.8),
  row = math.floor(vim.o.lines * 0.1),
  col = math.floor(vim.o.columns * 0.1),
  style = "minimal",
  border = "rounded",
  title = " Terminal ",
  title_pos = "center",
}

-- Terminal state
local terminal_bufnr = nil
local terminal_win_id = nil

-- Create a new floating terminal
function M.create_floating_terminal()
  -- Create a new buffer for the terminal
  terminal_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(terminal_bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(terminal_bufnr, "filetype", "terminal")
  
  -- Create the floating window
  terminal_win_id = vim.api.nvim_open_win(terminal_bufnr, true, terminal_options)
  
  -- Set window options
  vim.api.nvim_win_set_option(terminal_win_id, "winblend", 0)
  vim.api.nvim_win_set_option(terminal_win_id, "winhl", "Normal:Normal")
  vim.api.nvim_win_set_option(terminal_win_id, "cursorline", true)
  
  -- Open terminal in the buffer
  vim.fn.termopen(vim.o.shell, {
    on_exit = function()
      if terminal_win_id and vim.api.nvim_win_is_valid(terminal_win_id) then
        vim.api.nvim_win_close(terminal_win_id, true)
      end
      terminal_bufnr = nil
      terminal_win_id = nil
    end
  })
  
  -- Enter insert mode automatically
  vim.cmd("startinsert")
  
  -- Add mappings for the terminal buffer
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<C-\\><C-n>", "<C-\\><C-n>", { noremap = true })
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<ESC>", "<C-\\><C-n>", { noremap = true })
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<C-h>", "<C-\\><C-n><C-w>h", { noremap = true })
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<C-j>", "<C-\\><C-n><C-w>j", { noremap = true })
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<C-k>", "<C-\\><C-n><C-w>k", { noremap = true })
  vim.api.nvim_buf_set_keymap(terminal_bufnr, "t", "<C-l>", "<C-\\><C-n><C-w>l", { noremap = true })
end

-- Toggle the floating terminal
function M.toggle_floating_terminal()
  if terminal_bufnr ~= nil and vim.api.nvim_buf_is_valid(terminal_bufnr) then
    -- Terminal exists
    if terminal_win_id ~= nil and vim.api.nvim_win_is_valid(terminal_win_id) then
      -- Terminal window is open, close it
      vim.api.nvim_win_close(terminal_win_id, false)
      terminal_win_id = nil
    else
      -- Terminal window is closed, reopen it
      terminal_win_id = vim.api.nvim_open_win(terminal_bufnr, true, terminal_options)
      vim.api.nvim_win_set_option(terminal_win_id, "winblend", 0)
      vim.api.nvim_win_set_option(terminal_win_id, "winhl", "Normal:Normal")
      vim.cmd("startinsert")
    end
  else
    -- Terminal doesn't exist, create it
    M.create_floating_terminal()
  end
end

-- Execute a command in the floating terminal
function M.execute_command(command)
  M.toggle_floating_terminal()
  vim.api.nvim_chan_send(vim.b.terminal_job_id, command .. "\n")
end

return M