local options = {
    number = true,                -- Show line numbers
    relativenumber = true,        -- Show relative line numbers
    tabstop = 4,                 -- Number of spaces tabs count for
    softtabstop = 4,             -- Number of spaces to insert for a tab
    shiftwidth = 4,              -- Number of spaces to use for each step of (auto)indent
    expandtab = true,            -- Use spaces instead of tabs
    smartindent = true,          -- Smart indenting
    wrap = false,                -- Disable line wrapping
    cursorline = true,           -- Highlight the current line
    termguicolors = true,        -- Enable 24-bit RGB colors
    background = "dark",         -- Set background to dark
    clipboard = "unnamedplus",   -- Use system clipboard
    mouse = "a",                 -- Enable mouse support
    splitbelow = true,           -- Split windows below
    splitright = true,           -- Split windows to the right
}

for k, v in pairs(options) do
    vim.opt[k] = v
end