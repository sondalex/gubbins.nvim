local M = {}

---@diagnostic disable-next-line: undefined-global
local split = vim.split

---@diagnostic disable-next-line: undefined-global
M.nvim_err = vim.api.nvim_err_writeln

function M.split(line, sep)
    return split(line, sep)
end

function M.splitlines(lines)
    local res = {}
    for _, line in ipairs(lines) do
        for _, v2 in ipairs(M.split(line, "\n")) do
            table.insert(res, v2)
        end
    end
    return res
end

--- @param opts table
function M.copy(opts)
    local res = {}
    for k, v in pairs(opts) do
        res[k] = v
    end
    return res
end

--- @param tbl table
--- @param start integer
--- @param stop integer|nil
--- # Example:
---   ```lua
---   slice({"ls", "-l", "-h"}, 2, nil) => {"-l", "-h"}
---   ```
function M.slice(tbl, start, stop)
    local res = {}
    local slice_end = stop
    if stop == nil then
        slice_end = #tbl
    end
    for i = start, slice_end do
        table.insert(res, tbl[i])
    end
    return res
end

return M
