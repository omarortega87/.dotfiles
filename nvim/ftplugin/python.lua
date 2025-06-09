-- Django-specific settings for Python files
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4

-- Set commentstring for Python files
vim.opt_local.commentstring = '# %s'

-- Django template detection
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = {"*.html", "*.htm"},
  callback = function()
    local content = vim.api.nvim_buf_get_lines(0, 0, 100, false)
    for _, line in ipairs(content) do
      if line:match("{{") or line:match("{%%") or line:match("{#") then
        vim.bo.filetype = "django-html"
        break
      end
    end
  end
})

-- Django-specific utilities
local django_utils = {}

-- Run Django management commands
function django_utils.run_django_command(cmd)
  local command = string.format("python manage.py %s", cmd)
  vim.cmd(string.format("terminal %s", command))
end

-- Create keymaps for common Django operations
local opts = { noremap = true, silent = true }

-- Run Django server
vim.keymap.set("n", "<leader>drs", function()
  django_utils.run_django_command("runserver")
end, opts)

-- Run Django tests
vim.keymap.set("n", "<leader>dts", function()
  django_utils.run_django_command("test")
end, opts)

-- Run migrations
vim.keymap.set("n", "<leader>dmm", function()
  django_utils.run_django_command("migrate")
end, opts)

-- Make migrations
vim.keymap.set("n", "<leader>dmk", function()
  django_utils.run_django_command("makemigrations")
end, opts)

-- Django shell
vim.keymap.set("n", "<leader>dsh", function()
  django_utils.run_django_command("shell")
end, opts)

-- Show migrations
vim.keymap.set("n", "<leader>dsm", function()
  django_utils.run_django_command("showmigrations")
end, opts)

-- Create a new app
vim.keymap.set("n", "<leader>dca", function()
  local app_name = vim.fn.input("Enter app name: ")
  if app_name ~= "" then
    django_utils.run_django_command("startapp " .. app_name)
  end
end, opts)

-- Create a superuser
vim.keymap.set("n", "<leader>dsu", function()
  django_utils.run_django_command("createsuperuser")
end, opts)

-- Collect static files
vim.keymap.set("n", "<leader>dcs", function()
  django_utils.run_django_command("collectstatic")
end, opts)