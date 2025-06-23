-- Java filetype specific settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true
vim.opt_local.colorcolumn = "120"
vim.opt_local.textwidth = 120

-- Java specific keymaps for this buffer
local keymap = vim.keymap.set
local opts = { buffer = true }

-- Compile Java file
keymap("n", "<leader>jc", ":!javac %<CR>", vim.tbl_extend("force", opts, { desc = "Compile Java file" }))

-- Run Java class (assumes main method)
keymap("n", "<leader>jr", function()
  local filename = vim.fn.expand("%:t:r")
  vim.cmd("!java " .. filename)
end, vim.tbl_extend("force", opts, { desc = "Run Java class" }))

-- Run with Maven
keymap("n", "<leader>jm", ":!mvn exec:java<CR>", vim.tbl_extend("force", opts, { desc = "Run with Maven" }))

-- Run with Gradle
keymap("n", "<leader>jg", ":!./gradlew run<CR>", vim.tbl_extend("force", opts, { desc = "Run with Gradle" }))

-- Maven test
keymap("n", "<leader>jmt", ":!mvn test<CR>", vim.tbl_extend("force", opts, { desc = "Run Maven tests" }))

-- Gradle test
keymap("n", "<leader>jgt", ":!./gradlew test<CR>", vim.tbl_extend("force", opts, { desc = "Run Gradle tests" }))