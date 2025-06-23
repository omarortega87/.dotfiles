-- Omar's Neovim Configuration
-- Created: June 20, 2025

-- General Settings
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.tabstop = 4           -- Number of spaces tabs count for
vim.opt.shiftwidth = 4        -- Size of an indent
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.smartindent = true    -- Insert indents automatically
vim.opt.wrap = false          -- Disable line wrap
vim.opt.ignorecase = true     -- Ignore case when searching
vim.opt.smartcase = true      -- Don't ignore case with capitals
vim.opt.termguicolors = true  -- True color support
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.backup = false        -- No backup files
vim.opt.writebackup = false   -- No backup files during write
vim.opt.swapfile = false      -- No swap files
vim.opt.updatetime = 300      -- Faster completion
vim.opt.mouse = "a"           -- Enable mouse support
vim.opt.cursorline = true     -- Highlight the current line
vim.opt.signcolumn = "yes"    -- Always show the signcolumn

-- Leader Key Configuration
vim.g.mapleader = " "         -- Set leader key to space

-- Load Core Configurations
require("core.keymaps")       -- Keymaps configuration
require("core.plugins")       -- Plugin manager and plugins list
require("core.colorscheme")   -- Color scheme configuration

-- Load Language Specific Configurations
require("langs.python")       -- Python configuration
require("langs.java")         -- Java configuration