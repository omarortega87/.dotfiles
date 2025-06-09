local M = {}

function M.setup()
  local lspconfig = require('lspconfig')
  local util = require('lspconfig.util')

  -- Set up Pyright for Python files
  lspconfig.pyright.setup {
    on_attach = function(client, bufnr)
      -- Set keybindings when the language server attaches
      local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
      local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

      -- Enable completion triggered by <c-x><c-o>
      buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

      -- VS Code-like keybindings
      local opts = { noremap = true, silent = true }
      buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
      buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
      buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
      buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
      buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
      buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
      buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
      buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
      
      -- Python specific commands
      buf_set_keymap('n', '<space>pi', '<cmd>!pip install -r requirements.txt<CR>', opts)
      buf_set_keymap('n', '<space>pv', '<cmd>!python -m venv venv<CR>', opts)
      
      -- Add ability to easily run current Python file (like VS Code)
      buf_set_keymap('n', '<F5>', '<cmd>!python %<CR>', opts)
      
      -- Open terminal with Python REPL
      buf_set_keymap('n', '<space>ps', '<cmd>terminal python<CR>', opts)
    end,
    
    settings = {
      python = {
        analysis = {
          -- Basic VS Code-like defaults
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "workspace",
          
          -- Common issues in VS Code are handled with reasonable defaults
          diagnosticSeverityOverrides = {
            -- Handle None attribute issues (like in VS Code)
            reportOptionalMemberAccess = "warning",
            reportOptionalSubscript = "warning",
            
            -- Other common overrides
            reportGeneralTypeIssues = "warning",
            reportUnknownMemberType = "information",
            reportUnknownArgumentType = "information",
            reportUnknownVariableType = "information",
            reportDuplicateImport = "warning"
          },
          
          -- VS Code Python excludes common directories
          ignore = {
            "**/node_modules",
            "**/__pycache__",
            "**/venv",
            "**/.venv",
            "**/env",
            "**/.env",
            "**/.git"
          }
        },
        
        -- VS Code style formatting
        formatting = {
          provider = "black",
          blackPath = "black",
          autopep8Path = "autopep8",
          yapfPath = "yapf"
        },
        
        -- Enable linting like in VS Code
        linting = {
          enabled = true,
          pylintEnabled = true,
          flake8Enabled = true,
          mypyEnabled = true,
          pylintPath = "pylint",
          flake8Path = "flake8",
          mypyPath = "mypy"
        }
      }
    },
    
    -- Find project root similar to VS Code behavior
    root_dir = function(fname)
      return util.root_pattern(
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
        "manage.py"  -- For Django projects
      )(fname) or util.path.dirname(fname)
    end,
    
    -- File types to enable Python language server on
    filetypes = { "python" },
    
    -- Like VS Code, debounce changes for better performance
    flags = {
      debounce_text_changes = 150
    }
  }
  
  -- Also set up Python debugger if installed (similar to VS Code's debug)
  local has_dap, dap = pcall(require, "dap")
  if has_dap then
    dap.adapters.python = {
      type = 'executable',
      command = 'python',
      args = { '-m', 'debugpy.adapter' },
    }
    
    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = "Launch file",
        program = "${file}",
        pythonPath = function()
          -- VS Code style venv detection
          local venv_path = os.getenv("VIRTUAL_ENV")
          if venv_path then
            return venv_path .. "/bin/python"
          end
          
          -- Check for virtualenv in current directory
          local cwd = vim.fn.getcwd()
          if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
            return cwd .. "/venv/bin/python"
          elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
            return cwd .. "/.venv/bin/python"
          end
          
          -- Default to system Python
          return 'python'
        end,
      },
    }
  end
end

return M