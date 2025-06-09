-- Snippet Configuration

local ls = require("luasnip")
local types = require("luasnip.util.types")

-- Configure LuaSnip options
ls.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = false,
  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { "●", "GruvboxOrange" } },
      },
    },
  },
})

-- Load TestNG snippets for Java files
ls.add_snippets("java", require("snippets.java-testng"))

-- Key mappings for snippet navigation
vim.keymap.set({ "i", "s" }, "<C-k>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-j>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true })

-- Import snippets from friendly-snippets if available
pcall(require, "luasnip.loaders.from_vscode")