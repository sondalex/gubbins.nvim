# gubbins.ui

## Anchored Window

Create an anchored window which stays inplace and hide if out of frame.

```lua
local anchored = require("gubbins.ui.anchored")
vim.keymap.set("n", "<leader>aw", function()
    anchored.create_anchored_window(nil, nil, nil, { height = 6, width = 80, border="single" })
end)
```

## Embed Window (Not yet Implemented)

```lua
local embed = require("gubbins.ui.embed")
vim.keymap.set("n", "<leader>ew", function()
    embed.create_embed_window(nil, nil, {height=6, border="single"})
end
)

```

## Nested Embed Window (Not yet Implemented)

A nested window consists of a window in a embed window.

```lua
```
