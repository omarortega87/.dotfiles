require'nvim-treesitter.configs'.setup {
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  
  -- Automatically install missing parsers when entering buffer
  auto_install = true,
  
  -- List of parsers to ignore installing (for "all")
  ignore_install = { "phpdoc" },
  
  -- A list of parser names, or "all"
  ensure_installed = {
    "java",
    "javascript", 
    "typescript",
    "tsx",
    "python",
    "lua",
    "vim",
    "html",
    "css",
    "json",
    "markdown",
    "markdown_inline",
    "bash",
    "c",
    "cpp",
    "go",
    "rust"
  },

  highlight = {
    enable = true,
    disable = { "php", "phpdoc" },  -- list of language that will be disabled
    additional_vim_regex_highlighting = false,
  },
  
  indent = {
    enable = true,
    disable = { "python" }  -- Python indentation can be tricky with treesitter
  },
  
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
  },
}
