hl.config({
  cursor = {
    no_hardware_cursors = true,
  },
})

hl.config({
  input = {
    kb_layout = "latam,es",
    kb_variant = "",
    kb_model = "",
    kb_options = "compose:caps",
    kb_rules = "",

    follow_mouse = 1,
    sensitivity = 0,
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
