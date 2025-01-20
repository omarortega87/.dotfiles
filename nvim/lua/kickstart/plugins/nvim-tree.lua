return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {}
  end,
  -- Define the key mapping for NvimTreeOpen
  vim.api.nvim_set_keymap('n', '<leader>t', ':NvimTreeOpen<CR>', { noremap = true, silent = true }),
  -- Define the key mapping for NvimTreeClose
  vim.api.nvim_set_keymap('n', '<leader>c', ':NvimTreeClose<CR>', { noremap = true, silent = true }),
}
