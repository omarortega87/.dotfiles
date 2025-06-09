-- Django HTML template settings
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2

-- Set commentstring for Django HTML templates
vim.opt_local.commentstring = '{# %s #}'

-- Configure emmet for Django HTML templates
if vim.fn.exists('g:loaded_emmet_vim') == 1 then
  vim.b.emmet_settings = {
    django_html = {
      extends = 'html',
      filters = 'html',
    }
  }
end

-- Useful snippets and abbreviations for Django templates
vim.cmd([[
  iabbrev <buffer> djb {% block %}{% endblock %}
  iabbrev <buffer> djif {% if %}{% endif %}
  iabbrev <buffer> djfor {% for in %}{% endfor %}
  iabbrev <buffer> djext {% extends '' %}
  iabbrev <buffer> djinc {% include '' %}
  iabbrev <buffer> djcom {# comment #}
  iabbrev <buffer> djvar {{ }}
  iabbrev <buffer> djurl {% url '' %}
  iabbrev <buffer> djcss {% load static %}<link rel="stylesheet" href="{% static '' %}">
  iabbrev <buffer> djjs {% load static %}<script src="{% static '' %}"></script>
  iabbrev <buffer> djform {% csrf_token %}{{ form }}
]])

-- Keybindings for template editing
local opts = { noremap = true, silent = true, buffer = true }
vim.keymap.set("n", "<leader>dtb", "i{% block %}<CR>{% endblock %}<Esc>k$hi", opts)
vim.keymap.set("n", "<leader>dti", "i{% if %}<CR>{% endif %}<Esc>k$hi", opts)
vim.keymap.set("n", "<leader>dtf", "i{% for  in %}<CR>{% endfor %}<Esc>k$F i", opts)
vim.keymap.set("n", "<leader>dte", "i{% extends '' %}<Esc>hi", opts)
vim.keymap.set("n", "<leader>dtn", "i{% include '' %}<Esc>hi", opts)