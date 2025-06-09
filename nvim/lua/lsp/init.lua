local M = {}

function M.setup()
  local lspconfig = require('lspconfig')

  -- Set default LSP configurations
  lspconfig.util.default_config = {
    on_attach = function(client, bufnr)
      -- Custom on_attach function can be defined here
    end,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
  }

  -- Setup LSP configurations for specific languages
  require('lsp.java').setup()
  require('lsp.python').setup()

  -- Additional LSP settings can be added here if needed
end

return M