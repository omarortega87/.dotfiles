local dap = require('dap')

-- Java Debug configuration
dap.configurations.java = {
  -- Debug configurations for Java
  {
    type = 'java',
    request = 'attach',
    name = 'Debug (Attach) - Remote',
    hostName = '127.0.0.1',
    port = 5005,
  },
  {
    type = 'java',
    request = 'launch',
    name = 'Debug (Launch) - Current File',
    mainClass = "${file}",
    projectName = "${workspaceFolder}",
  },
  -- TestNG configuration
  {
    type = 'java',
    request = 'launch',
    name = 'Debug TestNG Tests',
    mainClass = 'org.testng.TestNG',
    projectName = "${workspaceFolder}",
    args = {
      '-testclass', "${java:testclass}",
    },
  },
  -- JUnit configuration
  {
    type = 'java',
    request = 'launch',
    name = 'Debug JUnit Tests',
    mainClass = 'org.junit.runner.JUnitCore',
    projectName = "${workspaceFolder}",
    args = { "${java:testclass}" },
  },
  -- Maven configuration
  {
    type = 'java',
    request = 'launch',
    name = 'Debug Maven Tests',
    mainClass = 'org.apache.maven.surefire.booter.ForkedBooter',
    projectName = "${workspaceFolder}",
  },
  -- Gradle configuration
  {
    type = 'java',
    request = 'launch',
    name = 'Debug Gradle Tests',
    mainClass = 'org.gradle.launcher.daemon.bootstrap.GradleDaemon',
    projectName = "${workspaceFolder}",
  },
}

-- Configure UI for debug
local dapui_status_ok, dapui = pcall(require, "dapui")
if dapui_status_ok then
  dapui.setup({
    icons = { expanded = "▾", collapsed = "▸" },
    mappings = {
      -- Use a table to apply multiple mappings
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    -- Expand lines larger than the window
    expand_lines = true,
    layouts = {
      {
        elements = {
          -- Elements can be strings or table with id and size keys.
          { id = "scopes", size = 0.25 },
          "breakpoints",
          "stacks",
          "watches",
        },
        size = 40, -- 40 columns
        position = "left",
      },
      {
        elements = {
          "repl",
          "console",
        },
        size = 0.25, -- 25% of total lines
        position = "bottom",
      },
    },
    floating = {
      max_height = nil, -- These can be integers or a float between 0 and 1.
      max_width = nil, -- Floats will be treated as percentage of your screen.
      border = "rounded", -- Border style. Can be "single", "double" or "rounded"
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    windows = { indent = 1 },
    render = {
      max_type_length = nil, -- Can be integer or nil.
    }
  })

  -- Add DAP event listeners to open and close the windows automatically
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end