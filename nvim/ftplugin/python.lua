-- Python filetype specific settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.colorcolumn = "88"
vim.opt_local.textwidth = 88

-- Python specific keymaps for this buffer
local keymap = vim.keymap.set
local opts = { buffer = true }

-- Run Python file
keymap("n", "<leader>pr", ":!python %<CR>", vim.tbl_extend("force", opts, { desc = "Run Python file" }))

-- Python REPL
keymap("n", "<leader>pi", ":!python -i %<CR>", vim.tbl_extend("force", opts, { desc = "Run Python interactively" }))

-- Format with Black
keymap("n", "<leader>pf", function()
  vim.cmd("!black %")
  vim.cmd("edit!")
end, vim.tbl_extend("force", opts, { desc = "Format with Black" }))

-- Sort imports with isort
keymap("n", "<leader>ps", function()
  vim.cmd("!isort %")
  vim.cmd("edit!")
end, vim.tbl_extend("force", opts, { desc = "Sort imports with isort" }))