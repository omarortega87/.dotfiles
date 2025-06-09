local telescope = require("telescope")
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

-- Configure Telescope
telescope.setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "smart" },
    file_ignore_patterns = {
      ".git/",
      "node_modules/",
      "target/",
      "build/",
      "dist/",
      "%.lock",
    },
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-c>"] = actions.close,
        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
      },
      n = {
        ["<esc>"] = actions.close,
        ["j"] = actions.move_selection_next,
        ["k"] = actions.move_selection_previous,
        ["q"] = actions.close,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
      },
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    live_grep = {
      additional_args = function()
        return { "--hidden" }
      end,
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

-- Load telescope extensions
telescope.load_extension("fzf")

-- Set up keymaps for Telescope
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>fc", builtin.colorscheme, { desc = "Colorscheme picker" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>fs", builtin.grep_string, { desc = "Find string under cursor" })
vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume last search" })

-- Git specific keymaps
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })