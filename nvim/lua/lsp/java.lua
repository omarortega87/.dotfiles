local M = {}

function M.setup()
  -- We'll use nvim-jdtls for Java setup instead of lspconfig directly
  -- The actual JDTLS setup will be in an ftplugin file to be loaded when Java files are opened
  
  -- Create an ftplugin directory if it doesn't exist
  local ftplugin_dir = vim.fn.stdpath("config") .. "/ftplugin"
  if vim.fn.isdirectory(ftplugin_dir) == 0 then
    vim.fn.mkdir(ftplugin_dir, "p")
  end
  
  -- Create the Java ftplugin file
  local java_config_path = ftplugin_dir .. "/java.lua"
  
  -- Only create the file if it doesn't exist
  if vim.fn.filereadable(java_config_path) == 0 then
    local file = io.open(java_config_path, "w")
    if file then
      file:write([[
-- Java-specific LSP settings using nvim-jdtls
local jdtls_ok, jdtls = pcall(require, "jdtls")
if not jdtls_ok then
  vim.notify("JDTLS not found, please install it with Mason", vim.log.levels.ERROR)
  return
end

-- Get the Mason installation path
local mason_registry = require("mason-registry")
local jdtls_pkg = mason_registry.get_package("jdtls")
if not jdtls_pkg:is_installed() then
  vim.notify("JDTLS is not installed. Please install it with :Mason", vim.log.levels.WARN)
  return
end

local jdtls_path = jdtls_pkg:get_install_path()
local path_separator = vim.loop.os_uname().sysname:match("Windows") and "\\" or "/"
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Find configuration directory based on OS
local config_dir
if vim.loop.os_uname().sysname:match("Linux") then
  config_dir = jdtls_path .. "/config_linux"
elseif vim.loop.os_uname().sysname:match("Darwin") then
  config_dir = jdtls_path .. "/config_mac"
elseif vim.loop.os_uname().sysname:match("Windows") then
  config_dir = jdtls_path .. "/config_win"
end

-- Project name for project-specific settings
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.expand('~/.cache/jdtls/workspace/') .. project_name

-- Set up JDTLS config
local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-jar', launcher_jar,
    '-configuration', config_dir,
    '-data', workspace_dir,
  },
  
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),
  
  settings = {
    java = {
      format = {
        enabled = true,
      },
      configuration = {
        updateBuildConfiguration = 'automatic',
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
      inlayHints = {
        parameterNames = {
          enabled = "all", -- literals, all, none
        },
      },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*"
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*", 
          "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
        },
        useBlocks = true,
      },
    }
  },
  
  flags = {
    allow_incremental_sync = true,
  },
  
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  
  on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    
    -- Mappings
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
    
    -- Java-specific mappings using nvim-jdtls
    vim.keymap.set('n', '<A-o>', jdtls.organize_imports, bufopts)
    vim.keymap.set('n', '<space>ev', jdtls.extract_variable, bufopts)
    vim.keymap.set('v', '<space>ev', function() jdtls.extract_variable(true) end, bufopts)
    vim.keymap.set('n', '<space>ec', jdtls.extract_constant, bufopts)
    vim.keymap.set('v', '<space>ec', function() jdtls.extract_constant(true) end, bufopts)
    vim.keymap.set('v', '<space>em', function() jdtls.extract_method(true) end, bufopts)
    
    -- If using DAP for Java debugging, uncomment these lines
    -- jdtls.setup_dap()
    -- jdtls.setup.add_commands()
  end
}

-- Start the JDTLS server
jdtls.start_or_attach(config)
]])
      file:close()
    end
  end
  
  -- Don't call lspconfig.jdtls.setup() since it will be handled by nvim-jdtls
  -- in the ftplugin when a Java file is opened
end

return M