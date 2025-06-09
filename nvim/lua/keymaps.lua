local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General key mappings
map('n', '<leader>e', ':NvimTreeToggle<CR>', opts)  -- Toggle file tree with leader+e
map('n', '<C-f>', ':Telescope find_files<CR>', opts)  -- Find files
map('n', '<C-g>', ':Telescope live_grep<CR>', opts)  -- Live grep
map('n', '<C-b>', ':Telescope buffers<CR>', opts)  -- List buffers

-- LSP key mappings
map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)  -- Go to definition
map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)  -- Hover documentation
map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)  -- Go to implementation
map('n', '<C-space>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)  -- Signature help
map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)  -- Rename symbol
map('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)  -- Code action

-- Python specific mappings
map('n', '<leader>py', ':!python3 %<CR>', opts)  -- Run Python file

-- Java specific mappings
map('n', '<leader>javac', ':!javac %<CR>', opts)  -- Compile Java file
map('n', '<leader>java', ':!java %<CR>', opts)  -- Run Java file

-- Add Maven keymap group (if using which-key)
local status_ok, wk = pcall(require, "which-key")
if status_ok then
  wk.register({
    m = {
      name = "Maven",
      c = { ":Maven compile<CR>", "Compile" },
      t = { ":Maven test<CR>", "Test" },
      i = { ":Maven install<CR>", "Install" },
      p = { ":Maven package<CR>", "Package" },
      cl = { ":Maven clean<CR>", "Clean" },
      ci = { ":Maven clean_install<CR>", "Clean Install" },
      cp = { ":Maven clean_package<CR>", "Clean Package" },
      v = { ":Maven verify<CR>", "Verify" },
      e = { ":Maven exec<CR>", "Execute (exec:java)" },
      s = { ":Maven spring_run<CR>", "Spring Boot Run" },
      m = { ":Maven ", "Custom Command" },
    },
  }, { prefix = "<leader>" })
end