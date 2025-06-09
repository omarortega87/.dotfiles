-- Java-specific LSP settings using nvim-jdtls
local status_ok, jdtls = pcall(require, "jdtls")
if not status_ok then
  vim.notify("JDTLS not found, please install it with Mason", vim.log.levels.ERROR)
  return
end

-- Get the Mason installation path
local mason_registry = require("mason-registry")
local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason")
local jdtls_path = mason_path .. "/packages/jdtls"

-- Find configuration directory based on OS
local config_dir
if vim.fn.has("mac") == 1 then
  config_dir = jdtls_path .. "/config_mac"
elseif vim.fn.has("unix") == 1 then
  config_dir = jdtls_path .. "/config_linux"
else
  config_dir = jdtls_path .. "/config_win"
end

-- Project name for project-specific settings
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.expand('~/.cache/jdtls/workspace/') .. project_name

-- Determine the proper launcher jar
local launcher_path = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Path to java-debug and java-test bundles
local java_debug_path = mason_path .. "/packages/java-debug-adapter"
local java_test_path = mason_path .. "/packages/java-test"

-- Check if we are in a Maven or Gradle project
local is_maven = vim.fn.filereadable(vim.fn.getcwd() .. "/pom.xml") == 1
local is_gradle = vim.fn.filereadable(vim.fn.getcwd() .. "/build.gradle") == 1 or 
                  vim.fn.filereadable(vim.fn.getcwd() .. "/build.gradle.kts") == 1

-- Get bundles for java-debug and java-test
local bundles = {}

-- Java Debug bundles
local java_debug_bundles = vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n")
vim.list_extend(bundles, java_debug_bundles)

-- Java Test bundles
local java_test_bundle_patterns = {
  "/extension/server/com.microsoft.java.test.plugin-*.jar",
  "/extension/server/com.microsoft.java.test.runner-jar-with-dependencies.jar",
  "/extension/server/junit-platform-launcher-*.jar"
}

for _, pattern in ipairs(java_test_bundle_patterns) do
  local bundle_path = vim.fn.glob(java_test_path .. pattern)
  if bundle_path ~= "" then
    table.insert(bundles, bundle_path)
  end
end

-- Configure the JDTLS
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
    '-jar', launcher_path,
    '-configuration', config_dir,
    '-data', workspace_dir,
  },

  -- Root directory detection prioritizing Maven and Gradle files
  root_dir = require('jdtls.setup').find_root({
    -- Order matters: look for these files first
    'pom.xml', 'build.gradle', 'build.gradle.kts', 
    -- Then fall back to these
    '.git', 'mvnw', 'gradlew', 'settings.gradle'
  }),
  
  -- Initialize bundles for test and debug support
  init_options = {
    bundles = bundles,
  },
  
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      format = {
        enabled = true,
        settings = {
          url = jdtls_path .. "/formatter.xml",
          profile = "GoogleStyle",
        },
      },
      saveActions = {
        organizeImports = true,
      },
      completion = {
        favoriteStaticMembers = {
          -- JUnit 5
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.junit.jupiter.api.DynamicContainer.*",
          "org.junit.jupiter.api.DynamicTest.*",
          -- JUnit 4
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          -- TestNG
          "org.testng.Assert.*",
          "org.testng.AssertJUnit.*",
          -- Mockito
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
          "org.mockito.Answers.*",
          "org.mockito.BDDMockito.*",
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
        hashCodeEquals = {
          useJava7Objects = true,
        },
        generateComments = true,
      },
      configuration = {
        -- Maven and Gradle specific settings
        maven = {
          downloadSources = true,
          updateSnapshots = is_maven,
        },
        gradle = {
          enabled = is_gradle,
          wrapper = {
            enabled = is_gradle,
          },
        },
        updateBuildConfiguration = "automatic",
        runtimes = {
          {
            name = "JavaSE-17",
            path = vim.fn.expand("~/.sdkman/candidates/java/17.0.8-tem"),
          },
        }
      },
      -- Better test support
      junit = {
        enabled = true,
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
      -- Debug settings
      debug = {
        logLevel = {
          default = "info",
        },
      },
    }
  },

  -- Improved capabilities with diagnostic support
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("cmp_nvim_lsp").default_capabilities()
  ),

  on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    
    -- Automatic diagnostics on save
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        vim.diagnostic.enable(bufnr)
        vim.lsp.buf.format({ async = false })
        vim.defer_fn(function()
          vim.diagnostic.show(nil, bufnr)
        end, 100)
      end,
      group = vim.api.nvim_create_augroup("JavaLSPAutocmds", { clear = true }),
      buffer = bufnr
    })
    
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
    
    -- Additional diagnostics navigation
    vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, bufopts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
    vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, bufopts)
    
    -- Java specific
    vim.keymap.set('n', '<leader>oi', jdtls.organize_imports, bufopts)
    vim.keymap.set('n', '<leader>ev', jdtls.extract_variable, bufopts)
    vim.keymap.set('v', '<leader>ev', function() jdtls.extract_variable(true) end, bufopts)
    vim.keymap.set('n', '<leader>ec', jdtls.extract_constant, bufopts)
    vim.keymap.set('v', '<leader>ec', function() jdtls.extract_constant(true) end, bufopts)
    vim.keymap.set('v', '<leader>em', function() jdtls.extract_method(true) end, bufopts)
    
    -- Set up testing and debugging key bindings
    local test_setup_ok, jdtls_dap = pcall(require, "jdtls.dap")
    if test_setup_ok then
      jdtls_dap.setup_dap_main_class_configs()
      
      -- Test related bindings
      vim.keymap.set('n', '<leader>jtt', function() require('jdtls').test_nearest_method() end, bufopts)
      vim.keymap.set('n', '<leader>jtc', function() require('jdtls').test_class() end, bufopts)
      vim.keymap.set('n', '<leader>jtf', function() require('jdtls').pick_test() end, bufopts)

      -- DAP debugging related bindings
      vim.keymap.set('n', '<leader>jdb', function() require('dap').toggle_breakpoint() end, bufopts)
      vim.keymap.set('n', '<leader>jdc', function() require('dap').continue() end, bufopts)
      vim.keymap.set('n', '<leader>jdi', function() require('dap').step_into() end, bufopts)
      vim.keymap.set('n', '<leader>jdo', function() require('dap').step_over() end, bufopts)
      vim.keymap.set('n', '<leader>jdO', function() require('dap').step_out() end, bufopts)
    end
    
    -- Maven/Gradle specific bindings
    if is_maven then
      -- Maven specific commands
      vim.keymap.set('n', '<leader>jmc', function()
        vim.cmd('terminal mvn clean')
      end, bufopts)
      vim.keymap.set('n', '<leader>jmi', function()
        vim.cmd('terminal mvn install')
      end, bufopts)
      vim.keymap.set('n', '<leader>jmp', function()
        vim.cmd('terminal mvn package')
      end, bufopts)
      vim.keymap.set('n', '<leader>jmt', function()
        vim.cmd('terminal mvn test')
      end, bufopts)
    elseif is_gradle then
      -- Gradle specific commands
      vim.keymap.set('n', '<leader>jgc', function()
        vim.cmd('terminal ./gradlew clean')
      end, bufopts)
      vim.keymap.set('n', '<leader>jgb', function()
        vim.cmd('terminal ./gradlew build')
      end, bufopts)
      vim.keymap.set('n', '<leader>jgt', function()
        vim.cmd('terminal ./gradlew test')
      end, bufopts)
    end
  end,

  -- Command to start the language server
  cmd_env = {
    PATH = vim.fn.getenv("PATH"),
  },
}

-- Start the JDTLS server
jdtls.start_or_attach(config)
