-- Maven project commands and keymaps

-- Define common Maven commands
local maven_commands = {
  compile = "mvn compile",
  clean = "mvn clean",
  install = "mvn install",
  test = "mvn test",
  package = "mvn package",
  clean_install = "mvn clean install",
  clean_package = "mvn clean package",
  verify = "mvn verify",
  exec = "mvn exec:java",
  spring_run = "mvn spring-boot:run",
}

-- Detect if current directory has a pom.xml file (Maven project)
local function is_maven_project()
  local handle = io.popen("find . -maxdepth 1 -name 'pom.xml' | wc -l")
  if not handle then return false end
  local result = handle:read("*a")
  handle:close()
  return tonumber(result) > 0
end

-- Create Maven command to run in terminal
vim.api.nvim_create_user_command("Maven", function(opts)
  local cmd = maven_commands[opts.args] or opts.args
  if string.find(cmd, "^mvn") then
    -- Command is already prefixed with mvn
    vim.cmd("terminal " .. cmd)
  else
    -- Add mvn prefix if not a predefined command
    vim.cmd("terminal mvn " .. cmd)
  end
end, {
  nargs = "*",
  desc = "Run Maven command",
  complete = function()
    local completion = {}
    for k, _ in pairs(maven_commands) do
      table.insert(completion, k)
    end
    return completion
  end
})

-- Set up keymaps for Maven commands (only in Java files or Maven projects)
vim.api.nvim_create_autocmd({"FileType", "BufEnter", "BufWinEnter"}, {
  pattern = {"java", "xml"},
  callback = function()
    -- Only set up keymaps if we're in a Maven project
    if is_maven_project() then
      -- Maven keymap prefix: <leader>m
      vim.keymap.set("n", "<leader>mc", ":Maven compile<CR>", { desc = "Maven compile" })
      vim.keymap.set("n", "<leader>mt", ":Maven test<CR>", { desc = "Maven test" })
      vim.keymap.set("n", "<leader>mi", ":Maven install<CR>", { desc = "Maven install" })
      vim.keymap.set("n", "<leader>mp", ":Maven package<CR>", { desc = "Maven package" })
      vim.keymap.set("n", "<leader>mcl", ":Maven clean<CR>", { desc = "Maven clean" })
      vim.keymap.set("n", "<leader>mci", ":Maven clean_install<CR>", { desc = "Maven clean install" })
      vim.keymap.set("n", "<leader>mcp", ":Maven clean_package<CR>", { desc = "Maven clean package" })
      vim.keymap.set("n", "<leader>mv", ":Maven verify<CR>", { desc = "Maven verify" })
      vim.keymap.set("n", "<leader>me", ":Maven exec<CR>", { desc = "Maven exec:java" })
      vim.keymap.set("n", "<leader>ms", ":Maven spring_run<CR>", { desc = "Maven Spring Boot run" })
      
      -- Add a custom command for running with specific goals/options
      vim.keymap.set("n", "<leader>mm", ":Maven ", { desc = "Maven custom command" })
    end
  end
})

-- Make Maven task output in terminal look better
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    -- Check if the terminal command contains 'mvn'
    local cmd = vim.fn.getbufvar("%", "term_command") or ""
    if cmd:match("mvn") then
      -- Set local options for Maven terminal buffers
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = true
      vim.opt_local.signcolumn = "no"
      
      -- Add a buffer local keymap to close the terminal with q
      vim.keymap.set("n", "q", ":q<CR>", { buffer = true, noremap = true })
    end
  end
})