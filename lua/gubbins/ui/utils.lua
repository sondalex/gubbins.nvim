---@diagnostic disable-next-line: undefined-global
local api = vim.api
local M = {}

--- Merge tbl1 and tbl2. tbl2 gets updated inplace.
---@param tbl1 table
---@param tbl2 table
---@return nil
function M.merge_table(tbl1, tbl2)
    for k, v in pairs(tbl1) do
        if type(k) == "number" then
            error("tbl1 appears to be an array. Expected an associative array")
        end
        tbl2[k] = v
    end
end

--- @param bufnr number|nil If nil, default to current buffer
--- @param upper_bound table|nil (row, col)|nil
--- @param lower_bound table|nil (row, col)|nil
function M.get_number_virt_lines(bufnr, upper_bound, lower_bound)
    if bufnr == nil then
        bufnr = 0 -- current buffer
    end

    if upper_bound == nil then
        upper_bound = { 0, 0 }
    end

    if lower_bound == nil then
        lower_bound = { -1, 0 }
    end

    local virt_lines_extmarks =
        api.nvim_buf_get_extmarks(bufnr, -1, upper_bound, lower_bound, { type = "virt_lines", details = true })
    local n = 0
    for _, virt_lines_extmark in ipairs(virt_lines_extmarks) do
        local opts = virt_lines_extmark[4]
        n = n + #opts["virt_lines"]
    end
    return n
end

return M
