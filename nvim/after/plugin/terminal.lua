-- Floating terminal plugin configuration

-- Load the terminal utility module
local terminal = require("utils.terminal")

-- Create user commands for the terminal
vim.api.nvim_create_user_command("TerminalToggle", function()
  terminal.toggle_floating_terminal()
end, { desc = "Toggle floating terminal" })

vim.api.nvim_create_user_command("TerminalExec", function(opts)
  terminal.execute_command(opts.args)
end, { nargs = "*", desc = "Execute command in floating terminal" })

-- Set up keymaps
vim.keymap.set("n", "<leader>tt", function()
  terminal.toggle_floating_terminal()
end, { desc = "Toggle floating terminal" })

vim.keymap.set("n", "<leader>tr", function()
  vim.ui.input({ prompt = "Command: " }, function(input)
    if input then
      terminal.execute_command(input)
    end
  end)
end, { desc = "Run command in terminal" })

-- Terminal-specific settings
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    -- Hide line numbers in terminal buffers
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    
    -- Start in insert mode
    vim.cmd("startinsert")
    
    -- Add ESC mapping to exit terminal mode
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = true })
    
    -- Easy navigation out of terminal
    vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { buffer = true })
    vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { buffer = true })
    vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { buffer = true })
    vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { buffer = true })
  end,
})