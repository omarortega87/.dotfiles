require('tokyonight').setup({
    style = 'night',
    transparent = true,
    terminal_colors = true,
    styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = { bold = true },
        variables = { italic = true },
        sidebars = 'dark',
        floats = 'dark',
    },
    on_colors = function(colors) end,
    on_highlights = function(hl, c) end,
})

vim.cmd('colorscheme tokyonight')