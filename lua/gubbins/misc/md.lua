--- Markdown and Quarto Files utilities
--
local M = {}
---[[
--- Go to specified code cell (uses treesitter)
--- @param number number codecell number (1 indexed)
--- @return nil
---]]
M.goto_codecell = function(number)
    local filetype = vim.bo.filetype
    if filetype ~= "quarto" and filetype ~= "markdown" then
        print("Only Quarto or Markdown files supported")
        return
    end

    local ts = vim.treesitter
    local parser = ts.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    local query_string = [[
        (fenced_code_block) @cell
    ]]
    local query = ts.query.parse(filetype, query_string)

    local code_cells = {}
    for id, node in query:iter_captures(root, 0) do
        local name = query.captures[id]
        if name == "cell" then
            table.insert(code_cells, node)
        end
    end

    if number < 1 or number > #code_cells then
        print("Code cell number out of range")
        return
    end

    local target_node = code_cells[number]
    local row, col, _, _ = target_node:range()
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

return M
