-- Python Language Configuration
local lspconfig = require("lspconfig")
local cmp = require("cmp")
local luasnip = require("luasnip")

-- Mason setup for automatic LSP server installation
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "ruff" },
  automatic_installation = true,
})

-- Enhanced capabilities for better diagnostics
local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.publishDiagnostics = vim.tbl_deep_extend("force", capabilities.textDocument.publishDiagnostics or {}, {
  relatedInformation = true,
  tagSupport = {
    valueSet = { 1, 2 }, -- Unnecessary and Deprecated
  },
  versionSupport = false,
  codeDescriptionSupport = true,
  dataSupport = true,
})

-- Python LSP configuration (Pyright)
lspconfig.pyright.setup({
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic",
        -- Enhanced diagnostic settings
        diagnosticSeverityOverrides = {
          reportMissingImports = "error",
          reportMissingTypeStubs = "warning",
          reportUnusedImport = "information",
          reportUnusedVariable = "warning",
          reportDuplicateImport = "warning",
          reportWildcardImportFromLibrary = "warning",
          reportOptionalSubscript = "warning",
          reportOptionalMemberAccess = "warning",
          reportOptionalCall = "warning",
          reportOptionalIterable = "warning",
          reportOptionalContextManager = "warning",
          reportOptionalOperand = "warning",
          reportTypedDictNotRequiredAccess = "warning",
        },
        -- Better error messages
        verboseOutput = true,
        logLevel = "Information",
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Enhanced on_attach for better error handling
    if client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
      vim.api.nvim_create_autocmd("CursorHold", {
        group = "lsp_document_highlight",
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = "lsp_document_highlight", 
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Ruff LSP for fast linting (updated from ruff_lsp)
lspconfig.ruff.setup({
  capabilities = capabilities,
  init_options = {
    settings = {
      -- Enhanced Ruff configuration for better error messages
      args = {
        "--extend-select=E,W,F,C,N,B,A,COM,C4,DTZ,T10,EM,EXE,ISC,ICN,G,INP,PIE,T20,PYI,PT,Q,RSE,RET,SLF,SIM,TID,TCH,INT,ARG,PTH,ERA,PD,PGH,PL,TRY,FLY,NPY,PERF,RUF",
        "--show-fixes",
        "--show-source",
      },
    },
  },
})

-- Autocompletion setup
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

-- Python debugging configuration
local dap = require("dap")
local dapui = require("dapui")

-- Configure DAP UI
dapui.setup()

-- Auto-open DAP UI when debugging starts
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Python DAP configuration
require("dap-python").setup("python") -- Uses system python by default

-- Neotest configuration for Python testing
require("neotest").setup({
  adapters = {
    require("neotest-python")({
      dap = { justMyCode = false },
      args = {"--log-level", "DEBUG"},
      runner = "pytest",
    }),
  },
})

-- Additional Python-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "88" -- Black's line length
  end,
})