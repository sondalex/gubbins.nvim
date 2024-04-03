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

return M
