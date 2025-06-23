-- Java Language Configuration
local lspconfig = require("lspconfig")

-- Mason setup for Java LSP servers
require("mason-lspconfig").setup({
  ensure_installed = { "jdtls" },
  automatic_installation = true,
})

-- Enhanced capabilities for better Java diagnostics
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

-- Java LSP configuration using jdtls (Eclipse JDT Language Server)
-- Note: nvim-jdtls provides better Java support than the standard lspconfig setup
local jdtls = require("jdtls")

-- Function to setup JDTLS
local function setup_jdtls()
  local home = os.getenv("HOME")
  local workspace_path = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  
  -- Get the current OS
  local os_config = "linux"
  if vim.fn.has("mac") == 1 then
    os_config = "mac"
  elseif vim.fn.has("win32") == 1 then
    os_config = "win"
  end

  local config = {
    cmd = {
      "java",
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xms1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens", "java.base/java.util=ALL-UNNAMED",
      "--add-opens", "java.base/java.lang=ALL-UNNAMED",
      "-jar", vim.fn.glob(home .. "/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
      "-configuration", home .. "/.local/share/nvim/mason/packages/jdtls/config_" .. os_config,
      "-data", workspace_path,
    },

    root_dir = require("jdtls.setup").find_root({".git", "mvnw", "gradlew", "pom.xml", "build.gradle"}),

    settings = {
      java = {
        eclipse = {
          downloadSources = true,
        },
        configuration = {
          updateBuildConfiguration = "interactive",
        },
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        referencesCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        format = {
          enabled = true,
          settings = {
            url = vim.fn.stdpath("config") .. "/lang-servers/intellij-java-google-style.xml",
            profile = "GoogleStyle",
          },
        },
        -- Enhanced compilation and error reporting
        compile = {
          nullAnalysis = {
            mode = "automatic",
          },
        },
        errors = {
          incompleteClasspath = {
            severity = "warning",
          },
        },
        -- Enhanced diagnostic settings for better error messages
        completion = {
          maxResults = 50,
          favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*",
          },
          filteredTypes = {
            "com.sun.*",
            "io.micrometer.shaded.*",
          },
        },
        -- More detailed error analysis
        cleanup = {
          actionsOnSave = {
            "addOverride",
            "addDeprecated",
            "stringConcatToTextBlock",
            "invertEquals",
            "addFinalModifier",
            "instanceofPatternMatch",
            "lambdaExpression",
            "switchExpression",
          },
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      extendedClientCapabilities = jdtls.extendedClientCapabilities,
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
    },

    flags = {
      allow_incremental_sync = true,
    },

    capabilities = capabilities,

    -- Enhanced Java specific keymaps and error handling
    on_attach = function(client, bufnr)
      local opts = { buffer = bufnr }
      
      -- Java-specific keymaps
      vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, { desc = "Organize imports", buffer = bufnr })
      vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, { desc = "Extract variable", buffer = bufnr })
      vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, { desc = "Extract constant", buffer = bufnr })
      vim.keymap.set("v", "<leader>jm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], { desc = "Extract method", buffer = bufnr })
      vim.keymap.set("n", "<leader>jt", jdtls.test_class, { desc = "Test class", buffer = bufnr })
      vim.keymap.set("n", "<leader>jn", jdtls.test_nearest_method, { desc = "Test nearest method", buffer = bufnr })
      
      -- Enhanced error handling with document highlights
      if client.server_capabilities.documentHighlightProvider then
        vim.api.nvim_create_augroup("java_lsp_document_highlight", { clear = true })
        vim.api.nvim_create_autocmd("CursorHold", {
          group = "java_lsp_document_highlight",
          buffer = bufnr,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd("CursorMoved", {
          group = "java_lsp_document_highlight",
          buffer = bufnr,
          callback = vim.lsp.buf.clear_references,
        })
      end
      
      -- Enhanced code lens for better context
      if client.server_capabilities.codeLensProvider then
        vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "InsertLeave"}, {
          buffer = bufnr,
          callback = vim.lsp.codelens.refresh,
        })
      end
    end,
  }

  jdtls.start_or_attach(config)
end

-- Auto command to setup JDTLS when opening Java files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    setup_jdtls()
    
    -- Java-specific settings
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "120"
  end,
})

-- Java debugging configuration
local dap = require("dap")

dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Debug (Attach) - Remote",
    hostName = "127.0.0.1",
    port = 5005,
  },
  {
    type = "java",
    request = "launch",
    name = "Debug (Launch) - Current File",
    program = "${file}",
  },
}

-- Additional Java settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    -- Enable word wrap for Java files
    vim.opt_local.wrap = false
    -- Set appropriate text width
    vim.opt_local.textwidth = 120
  end,
})