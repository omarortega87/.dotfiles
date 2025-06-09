require'nvim-tree'.setup {
  view = {
    width = 30,
    side = 'left',
  },
  filters = {
    dotfiles = false,
  },
  git = {
    enable = true,
    ignore = false,
  },
  renderer = {
    highlight_opened_files = "all",
    icons = {
      glyphs = {
        default = "",
        symlink = "",
        git = {
          unstaged = "✗",
          staged = "✓",
          untracked = "★",
        },
      },
    },
  },
}