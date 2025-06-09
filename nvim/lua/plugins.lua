-- filepath: /Users/omarortega/.config/nvim-config/lua/plugins.lua
return {
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true, -- Enable transparent background
        integrations = {
          cmp = true,
          nvimtree = true,
          telescope = true,
          mason = true,
          treesitter = true,
        },
        custom_highlights = function(colors)
          return {
            Comment = { fg = colors.overlay1, style = { "italic" } },
            ["@keyword"] = { fg = colors.red, style = { "italic" } },
            ["@function"] = { fg = colors.blue, style = { "bold" } },
          }
        end,
      })
      vim.cmd([[colorscheme catppuccin]])
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "java", "python", "vim", "html", "css", "javascript" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "django-html", "htmldjango" },
        },
        indent = { enable = true },
      })
    end,
  },

  -- File tree plugin
  {
    "kyazdani42/nvim-tree.lua",
    dependencies = {
      "kyazdani42/nvim-web-devicons", -- optional, for file icons
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },

  -- LSP support
  {
    "neovim/nvim-lspconfig", -- Collection of configurations for built-in LSP client
  },
  
  -- Mason for managing LSP servers, DAP servers, linters, and formatters
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  
  -- Mason-lspconfig to integrate mason with lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"},
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {"jdtls", "pyright", "html", "cssls", "tailwindcss"},
        automatic_installation = true,
      })
    end,
  },
  
  -- Mason tools installer
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {"williamboman/mason.nvim"},
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSP
          "pyright",       -- Python LSP
          "html-lsp",      -- HTML LSP
          "css-lsp",       -- CSS LSP
          "tailwindcss-language-server", -- Tailwind CSS support
          "jdtls",         -- Java Language Server
          
          -- Linters
          "flake8",        -- Python linter
          "mypy",          -- Python type checker
          "djlint",        -- Django template linter
          
          -- Formatters
          "black",         -- Python code formatter
          "isort",         -- Python import formatter
          "prettier",      -- HTML/CSS/JS formatter
          
          -- Debug Adapters
          "debugpy",       -- Python debugging
          "java-debug-adapter", -- Java debugging
          "java-test",     -- Java testing
        },
        auto_update = true,
        run_on_start = true,
      })
    end,
  },
  
  -- JDTLS specific plugin for enhanced Java support
  {
    "mfussenegger/nvim-jdtls",
    ft = "java", -- Only load for Java files
  },

  -- Telescope for fuzzy finding
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.4", -- Use the latest stable release
    dependencies = { 
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      }
    },
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      
      -- Check if Tab is already being used by snippet navigation
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          
          -- Navigate the completion menu with Tab/S-Tab
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),
          
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = function(entry, vim_item)
            -- Add icons for different completion types
            local kind_icons = {
              Text = "󰉿",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰜢",
              Variable = "󰀫",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "󰑭",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "󰈇",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "󰙅",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "",
            }
            vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind] or "", vim_item.kind)
            
            -- Source name in the menu
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            
            return vim_item
          end
        },
        -- Auto-trigger completion after 3 characters
        completion = {
          keyword_length = 3,
          autocomplete = {
            require('cmp.types').cmp.TriggerEvent.TextChanged,
          },
        },
        -- Performance improvements
        performance = {
          max_view_entries = 20, -- Limit number of items in the completion window
          debounce = 50,         -- Debounce time for completion in milliseconds
          throttle = 30,         -- Throttle time for completion in milliseconds
          fetching_timeout = 100, -- Timeout for fetching completion items
        },
        experimental = {
          ghost_text = false,    -- Disable ghost text for better performance
        },
      })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local colors = require("catppuccin.palettes").get_palette()
      require("lualine").setup {
        options = {
          icons_enabled = true,
          theme = "catppuccin",
          component_separators = { left = "", right = ""},
          section_separators = { left = "", right = ""},
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
        },
        sections = {
          lualine_a = {
            { "mode", separator = { left = "" }, right_padding = 2 },
          },
          lualine_b = { 
            { "branch", icon = "" },
            { 
              "diff",
              symbols = {
                added = " ",
                modified = " ",
                removed = " "
              }
            },
            "diagnostics" 
          },
          lualine_c = { 
            { "filename", path = 1 },
            { "filesize" }
          },
          lualine_x = { 
            { 
              "filetype",
              icon_only = true,
              separator = "",
              padding = { left = 1, right = 0 }
            },
            { "encoding" },
            { "fileformat" },
            {
              function() return "  " .. vim.fn.line(".") .. "/" .. vim.fn.line("$") end,
              separator = "",
              padding = { left = 0, right = 1 }
            }
          },
          lualine_y = {
            { "progress", separator = "", padding = { left = 1, right = 1 } },
          },
          lualine_z = {
            { "location", separator = { right = "" }, left_padding = 2 },
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = { "nvim-tree", "fugitive" }
      }
    end
  },

  -- Git integration
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiff", "Gclog", "Gwrite", "Gcommit", "Gread" }
  },

  -- Django Development Tools
  {
    "mattn/emmet-vim", -- Helpful for HTML template editing
    ft = { "html", "css", "javascript", "htmldjango", "django-html" }
  },

  {
    "mfussenegger/nvim-dap-python", -- Debug Adapter for Python (official repo)
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require('dap-python').setup('python')
      -- Add Django configuration for debugging
      table.insert(require('dap').configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Django',
        program = vim.fn.getcwd() .. '/manage.py',
        args = { 'runserver', '--noreload' },
        django = true,
      })
    end,
    ft = { "python", "django-python" }
  },

  {
    "mfussenegger/nvim-lint", -- Linting
    config = function()
      require('lint').linters_by_ft = {
        python = {'flake8', 'mypy'},
        django_python = {'flake8', 'mypy'}
      }
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },

  {
    "stevearc/conform.nvim", -- Formatting
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "black", "isort" },
          django_python = { "black", "isort" },
          html = { "prettier" },
          ["django-html"] = { "prettier" },
          xml = { "xmlformat" }, -- Add XML formatting
        },
        formatters = {
          xmlformat = {
            command = "xmlformat",
            args = { "--indent", "2", "--preserve-comments", "--nsclean" },
            -- If you don't have xmlformat installed yet, this provides a helpful message
            condition = function(self, ctx)
              if vim.fn.executable("xmlformat") == 0 then
                vim.notify("xmlformat not found. Install with: brew install xmlformat", vim.log.levels.WARN)
                return false
              end
              return true
            end,
          }
        }
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.py", "*.html", "*.xml", "pom.xml" }, -- Add XML files to auto-format
        callback = function(args)
          require("conform").format({ bufnr = args.buf })
        end,
      })
    end,
  },

  {
    "roobert/tailwindcss-colorizer-cmp.nvim", -- CSS colorizer
    ft = { "html", "css", "django-html" },
    config = function()
      require("tailwindcss-colorizer-cmp").setup({
        color_square_width = 2,
      })
    end
  },

  {
    "weirongxu/plantuml-previewer.vim", -- UML diagrams for model visualization
    dependencies = {
      "aklt/plantuml-syntax",
      "tyru/open-browser.vim"
    },
    cmd = {"PlantumlOpen", "PlantumlSave"},
  },

  -- Debug Adapter Protocol
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui", -- UI for DAP
      "theHamsta/nvim-dap-virtual-text", -- Inline variable values
    },
    config = function()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
      })
    end,
  },

  -- Java Maven and Gradle enhanced support
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "kyazdani42/nvim-tree.lua",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },

  -- Testing Framework
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-java", -- Updated to the official neotest-java repository
      "nvim-neotest/nvim-nio", -- Add the missing nio dependency
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-java")({
            -- Use Junit 5 for new projects
            use_junit5 = true,
            -- Set to true if using TestNG
            use_testng = true,
          }),
        },
      })
      
      -- Keymaps for test runner
      vim.keymap.set("n", "<leader>tr", function() require("neotest").run.run() end, { desc = "Run nearest test" })
      vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run test file" })
      vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Toggle test summary" })
      vim.keymap.set("n", "<leader>to", function() require("neotest").output.open() end, { desc = "Show test output" })
    end,
  },

  -- Maven pom.xml syntax support
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        filetypes = { "html", "css", "xml", "java", "kotlin", "scala" },
        user_default_options = {
          RGB = true,
          RRGGBB = true,
          names = true,
          RRGGBBAA = true,
          AARRGGBB = true,
          rgb_fn = true,
          hsl_fn = true,
          css = true,
          css_fn = true,
          mode = "background",
        },
      })
    end,
  },

  -- Gradle build files syntax support
  {
    "tfnico/vim-gradle",
    ft = { "gradle", "groovy", "kotlin" },
  },

  -- XML/pom.xml improved support
  {
    "chrisbra/vim-xml-ftplugin",
    ft = { "xml" },
  },

  -- Additional plugins can be added here
}