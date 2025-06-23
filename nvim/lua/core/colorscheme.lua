-- Color scheme configuration
local status, _ = pcall(vim.cmd, "colorscheme catppuccin")
if not status then
  print("Colorscheme not found!")
  return
end

-- Additional colorscheme settings
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  background = { -- :h background
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false,
  show_end_of_buffer = false, -- show the '~' characters after the end of buffers
  term_colors = false,
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  no_italic = false, -- Force no italic
  no_bold = false, -- Force no bold
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
  },
  color_overrides = {},
  custom_highlights = {},
  integrations = {
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    telescope = true,
    notify = false,
    mini = false,
    -- Enhanced LSP integrations
    native_lsp = {
      enabled = true,
      virtual_text = {
        errors = { "italic" },
        hints = { "italic" },
        warnings = { "italic" },
        information = { "italic" },
      },
      underlines = {
        errors = { "underline" },
        hints = { "underline" },
        warnings = { "underline" },
        information = { "underline" },
      },
      inlay_hints = {
        background = true,
      },
    },
  },
})

-- Enhanced LSP Diagnostic Configuration
vim.diagnostic.config({
  -- Enable virtual text with better formatting
  virtual_text = {
    enabled = true,
    source = "if_many", -- Show source if multiple sources
    prefix = "●", -- Use a nice bullet point
    format = function(diagnostic)
      -- Add more descriptive prefixes based on severity
      local severity_icons = {
        [vim.diagnostic.severity.ERROR] = "✗ Error",
        [vim.diagnostic.severity.WARN] = "⚠ Warning", 
        [vim.diagnostic.severity.INFO] = "ℹ Info",
        [vim.diagnostic.severity.HINT] = "💡 Hint",
      }
      local icon = severity_icons[diagnostic.severity] or "●"
      
      -- Include source information when available
      local source = diagnostic.source and (" [" .. diagnostic.source .. "]") or ""
      
      -- Truncate very long messages
      local message = diagnostic.message
      if #message > 80 then
        message = message:sub(1, 77) .. "..."
      end
      
      return string.format("%s: %s%s", icon, message, source)
    end,
  },
  
  -- Enhanced signs in the gutter
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✗",
      [vim.diagnostic.severity.WARN] = "⚠",
      [vim.diagnostic.severity.INFO] = "ℹ",
      [vim.diagnostic.severity.HINT] = "💡",
    },
  },
  
  -- Better underline style
  underline = true,
  
  -- Enhanced floating window configuration
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always", -- Always show the source
    header = "",
    prefix = "",
    format = function(diagnostic)
      local severity_names = {
        [vim.diagnostic.severity.ERROR] = "ERROR",
        [vim.diagnostic.severity.WARN] = "WARNING",
        [vim.diagnostic.severity.INFO] = "INFO", 
        [vim.diagnostic.severity.HINT] = "HINT",
      }
      
      local severity = severity_names[diagnostic.severity] or "UNKNOWN"
      local source = diagnostic.source and (" [" .. diagnostic.source .. "]") or ""
      local code = diagnostic.code and (" (" .. diagnostic.code .. ")") or ""
      
      return string.format("[%s]%s%s\n%s", severity, source, code, diagnostic.message)
    end,
  },
  
  -- Update diagnostics in insert mode
  update_in_insert = false,
  
  -- Sort diagnostics by severity
  severity_sort = true,
})

-- Configure LSP hover window appearance
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
  title = "Documentation",
})

-- Configure LSP signature help window
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded", 
  title = "Signature Help",
})