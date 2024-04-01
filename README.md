# gubbins.nvim

[neovim](https://neovim.io/) plugin with utilities I commonly use. 

## System command

1. Run a system command asynchronously and display output to separated window in one batch

   ```lua
   local cmd = require("gubbins.cmd")
   local waitcompletion = true
   cmd.run({ "node", "example/ls.js", "--slow" }, true, waitcompletion, nil, nil)
   ```

   https://github.com/sondalex/gubbins.nvim/assets/61547150/c7010371-8618-4770-8c3c-1a389aa0c19e





2. Run a system command asynchronously and display output line by line.

   ```lua
   local cmd = require("gubbins.cmd")
   local waitcompletion = false
   cmd.run({ "node", "example/ls.js", "--slow" }, true, waitcompletion, nil, nil)
   ```

   https://github.com/sondalex/gubbins.nvim/assets/61547150/352a89c6-992b-4616-9b13-a85cf63ec490


## Advanced UI Layout

See [ui/README.md](lua/gubbins/ui/README.md)



## Example

Common usage consists of running command on keymap. Here's an example:

```lua
-- .config/lua/after/gubbins.lua
local cmd = require("gubbins.cmd")

local list_files = function()
  cmd.run({ "ls", "-l", "-h" }, true, false, nil, function(buf, win)
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
      noremap = true,
      silent = true,
      callback = function()
        vim.api.nvim_win_close(win, false)
      end,
    })
  end)
end
vim.keymap.set("n", "<leader>lfs", list_files)
```

## Installation

With packer:

```lua
use(
    "sondalex/gubbins.nvim"
})
```


## Testing (Unix based only)

```bash
./tests/run
```
