# gubbins.ui

## Anchored Window

Create an anchored window which stays inplace and hide if out of frame.

```lua
require("gubbins.ui")
vim.keymap.set("n", "<leader>aw", function()
    M.create_anchored_window(nil, nil, nil, { height = 6, width = 80, border="single" })
end)
```

## Embed Window

```lua

```

## Nested Embed Window

```lua
```
