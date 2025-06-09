-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load options and keymaps before plugins
require('options')
require('keymaps')

-- Set up diagnostic signs globally
local signs = {
  { name = "Error", text = " ", texthl = "DiagnosticSignError" },
  { name = "Warn", text = " ", texthl = "DiagnosticSignWarn" },
  { name = "Hint", text = " ", texthl = "DiagnosticSignHint" },
  { name = "Info", text = " ", texthl = "DiagnosticSignInfo" }
}

-- Configure diagnostics display with modern sign configuration
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    source = "if_many",
  },
  float = {
    source = "always",
    border = "rounded",
    header = "",
    prefix = "",
  },
  signs = {
    priority = 10,
    text = {
      [vim.diagnostic.severity.ERROR] = signs[1].text,
      [vim.diagnostic.severity.WARN] = signs[2].text,
      [vim.diagnostic.severity.HINT] = signs[3].text,
      [vim.diagnostic.severity.INFO] = signs[4].text,
    }
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Initialize lazy.nvim with plugins from lua/plugins.lua
require("lazy").setup("plugins")

-- Ensure treesitter is properly configured
vim.defer_fn(function()
  require'nvim-treesitter.configs'.setup {
    ensure_installed = { "lua", "java", "python" },
    highlight = {
      enable = true,
    },
    indent = {
      enable = true
    }
  }
end, 0)

-- Load custom snippets
require("config.snippets")

-- Load other configuration
require('lsp.init').setup()

-- Additional setup can be added here if needed.