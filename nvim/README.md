# Omar's Neovim Configuration

A comprehensive Neovim configuration optimized for Python and Java development, inspired by modern development workflows.

## Features

### Core Features
- **Plugin Manager**: Lazy.nvim for fast plugin loading
- **Color Scheme**: Tokyo Night theme with customizations
- **File Explorer**: Nvim-tree with web devicons
- **Fuzzy Finder**: Telescope for file and text search
- **Syntax Highlighting**: Treesitter for advanced syntax highlighting
- **Status Line**: Lualine with theme integration
- **Git Integration**: Gitsigns for git status in gutter
- **Auto Pairs**: Automatic bracket/quote pairing
- **Comments**: Easy commenting with Comment.nvim

### Language Support

#### Python
- **LSP**: Pyright for type checking and IntelliSense
- **Linting**: Ruff LSP for fast linting
- **Formatting**: Black and isort integration
- **Testing**: Neotest with pytest support
- **Debugging**: DAP with Python support
- **Auto-completion**: nvim-cmp with LSP integration

#### Java
- **LSP**: Eclipse JDT Language Server (JDTLS)
- **Formatting**: Google Java Format
- **Debugging**: DAP for Java
- **Build Tools**: Maven and Gradle support
- **Refactoring**: Extract methods, variables, constants
- **Testing**: JUnit support via JDTLS

## Installation

1. **Backup existing configuration** (if any):
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. **The configuration is already installed** in `~/.config/nvim`

3. **Install dependencies**:
   
   **For Python development**:
   ```bash
   pip install black isort pytest debugpy
   ```
   
   **For Java development**:
   - Install Java 17+ (required for JDTLS)
   - Install Maven or Gradle (optional, for project management)

4. **First launch**: Open Neovim and let Lazy.nvim install all plugins automatically.

## Key Mappings

### Leader Key
- Leader key is set to `<Space>`

### File Navigation
- `<leader>e` - Toggle file explorer
- `<leader>ef` - Find current file in explorer
- `<leader>ff` - Find files
- `<leader>fs` - Live grep search
- `<leader>fb` - Browse open buffers
- `<leader>fr` - Recent files

### LSP Operations
- `gd` - Go to definition
- `gr` - Show references
- `gi` - Go to implementation
- `K` - Show hover documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `<leader>d` - Show line diagnostics
- `[d` / `]d` - Navigate diagnostics

### Python Specific
- `<leader>pr` - Run Python file
- `<leader>pi` - Run Python interactively
- `<leader>pf` - Format with Black
- `<leader>ps` - Sort imports with isort
- `<leader>pt` - Run nearest test
- `<leader>pT` - Run all tests in file

### Java Specific
- `<leader>jo` - Organize imports
- `<leader>jv` - Extract variable
- `<leader>jc` - Extract constant
- `<leader>jm` - Extract method (visual mode)
- `<leader>jr` - Run Java class
- `<leader>jt` - Test class
- `<leader>jn` - Test nearest method

### Debugging
- `<F5>` - Start/Continue debugging
- `<F1>` - Step into
- `<F2>` - Step over
- `<F3>` - Step out
- `<leader>b` - Toggle breakpoint

### Window Management
- `<leader>sv` - Split vertically
- `<leader>sh` - Split horizontally
- `<leader>se` - Make splits equal
- `<leader>sx` - Close split

### Buffer Navigation
- `<S-l>` - Next buffer
- `<S-h>` - Previous buffer
- `<leader>bd` - Delete buffer

## Configuration Structure

```
~/.config/nvim/
├── init.lua                 # Main configuration entry point
├── lua/
│   ├── core/
│   │   ├── plugins.lua      # Plugin specifications
│   │   ├── keymaps.lua      # Key mappings
│   │   └── colorscheme.lua  # Color scheme settings
│   └── langs/
│       ├── python.lua       # Python-specific configuration
│       └── java.lua         # Java-specific configuration
└── ftplugin/
    ├── python.lua           # Python filetype settings
    └── java.lua             # Java filetype settings
```

## Customization

### Adding New Plugins
Edit `lua/core/plugins.lua` and add your plugin specification to the plugins table.

### Modifying Keymaps
Edit `lua/core/keymaps.lua` to add or modify key mappings.

### Language-Specific Settings
Add new files in `lua/langs/` and `ftplugin/` for additional language support.

## Troubleshooting

### Python Issues
- Ensure Python and pip are installed
- Install Python dependencies: `pip install black isort pytest debugpy`
- Check Python path in DAP configuration

### Java Issues
- Ensure Java 17+ is installed
- JDTLS will be automatically installed via Mason
- For project support, ensure Maven or Gradle is installed

### Plugin Issues
- Run `:Lazy sync` to update plugins
- Run `:Mason` to check LSP server installations
- Run `:checkhealth` for general health check

## Credits

This configuration was inspired by modern Neovim setups and best practices from the community, with specific inspiration from dotfiles repositories and the Neovim ecosystem.