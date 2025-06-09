-- Add XML specific settings in after/ftplugin directory
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"xml", "xsd", "xslt", "svg", "pom", "ant", "xhtml", "jrxml"},
  callback = function()
    -- Set formatting options for XML files
    vim.bo.formatexpr = "xmlformat#Format()"
    
    -- Format XML with gq command using built-in formatter
    vim.keymap.set("n", "<leader>fx", ":%!xmllint --format -<CR>", { buffer = true, silent = true, desc = "Format XML" })
    
    -- Enable auto-indentation for XML
    vim.bo.autoindent = true
    vim.bo.smartindent = true
    vim.bo.cindent = true
    
    -- Set appropriate indentation
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
  end,
})

-- Auto-format XML files on save using xmllint
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {
    "*.xml", "*.xsd", "*.xslt", "*.svg", "pom.xml", 
    "*.ant", "*.xhtml", "*.jrxml", "*.wsdl", "*.config",
    "*.rss", "*.project", "*.classpath", "*.mxml"
  },
  callback = function()
    -- Only proceed if xmllint is available
    if vim.fn.executable("xmllint") == 1 then
      -- Save cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      -- Format the file
      vim.cmd("silent %!xmllint --format --noblanks -")
      -- Restore cursor position
      vim.api.nvim_win_set_cursor(0, cursor_pos)
    else
      vim.notify("xmllint not found. Please install it for XML formatting.", vim.log.levels.WARN)
    end
  end,
})

-- Add command to toggle XML auto-format on save
local xml_format_enabled = true
vim.api.nvim_create_user_command("XmlFormatToggle", function()
  xml_format_enabled = not xml_format_enabled
  if xml_format_enabled then
    vim.notify("XML auto-format on save enabled", vim.log.levels.INFO)
  else
    vim.notify("XML auto-format on save disabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle XML auto-format on save" })