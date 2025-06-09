# Neovim Configuration

This repository contains a Neovim configuration setup designed for a pleasant development experience with support for Java and Python programming languages, along with a file tree plugin for easy navigation.

## Project Structure

The project is organized as follows:

```
nvim-config
├── init.lua               # Main configuration file for Neovim
├── lua
│   ├── plugins.lua        # Plugin management
│   ├── options.lua        # Neovim options and settings
│   ├── keymaps.lua        # Custom key mappings
│   ├── colorscheme.lua    # Theme configuration
│   └── lsp
│       ├── init.lua       # LSP initialization
│       ├── java.lua       # Java LSP configuration
│       └── python.lua     # Python LSP configuration
├── after
│   └── plugin
│       ├── nvim-tree.lua  # File tree plugin configuration
│       └── lspconfig.lua  # Additional LSP configurations
└── README.md              # Documentation for the configuration
```

## Installation

1. Clone this repository to your local machine.
2. Ensure you have Neovim installed (version 0.5 or higher).
3. Install the required plugins using your preferred plugin manager (e.g., `packer.nvim`, `vim-plug`).
4. Open Neovim and run `:source %` in the `init.lua` file to load the configuration.

## Features

- **Java LSP Support**: Provides autocompletion, error checking, and other language features for Java development.
- **Python LSP Support**: Offers similar features for Python programming.
- **File Tree Plugin**: Easily navigate your project files with the integrated file explorer.

## Usage

- Use the configured key mappings for quick access to various features.
- Customize the options in `lua/options.lua` to suit your preferences.
- Modify the theme in `lua/colorscheme.lua` to change the visual appearance of Neovim.

## Contributing

Feel free to submit issues or pull requests if you have suggestions or improvements for this configuration.