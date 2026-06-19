hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "DP-3",
  mode = "3840x2160@60",
  position = "1920x0",
  scale = 1.5,
})

for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
  hl.workspace_rule({ workspace = tostring(i), monitor = "DP-3" })
end
