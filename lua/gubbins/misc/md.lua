--- Markdown and Quarto Files utilities
local ts = vim.treesitter

local api = vim.api

local get_filetype = function(bufnr)
    return api.nvim_buf_get_option(bufnr, "filetype")
end

local validate_filetype = function(filetype)
    if filetype ~= "quarto" and filetype ~= "markdown" then
        error("Unsupported cell")
    end
end

local starts_with = function(s, pattern)
    return s:find("^" .. pattern) ~= nil
end

local M = {}
---[[
--- Go to specified code cell (uses treesitter)
--- @param number number codecell number (1 indexed)
--- @param bufnr number|nil The buffer id (0 indexed)
--- @return nil
---]]
M.goto_codecell = function(number, bufnr)
    local bufnr = bufnr or 0
    local filetype = get_filetype(bufnr)
    validate_filetype(filetype)

    local parser = ts.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    local query_string = [[
        (fenced_code_block) @cell
    ]]
    local query = ts.query.parse(filetype, query_string)

    local code_cells = {}
    for id, node in query:iter_captures(root, bufnr) do
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

M.highlight_cell = function(bufnr, ns_id, cell_number, hl_group)
    local hl_group = hl_group or "Normal"

    local ns_id = ns_id or api.nvim_create_namespace("gubbins.misc.md")
    local filetype = get_filetype(bufnr)
    validate_filetype(filetype)

    local parser = ts.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    local query_string = [[
        (fenced_code_block) @cell
    ]]
    local query = ts.query.parse(filetype, query_string)

    for _, node in query:iter_captures(root, bufnr, cell_number, cell_number) do
        local row1, col1, _, _ = node:range()
        local virt_text = { { "#" .. tostring(cell_number), hl_group } }

        api.nvim_buf_set_extmark(bufnr, ns_id, row1, col1, { virt_text = virt_text, virt_text_pos = "eol" })
    end
    return ns_id
end

M.highlight_cells = function(bufnr, hl_group)
    local hl_group = hl_group or "BlueText"
    api.nvim_set_hl(0, "BlueText", { fg = "#0000ff" }) -- HACK: move this in a init function
    local bufnr = bufnr or 0

    local ns_id = ns_id or api.nvim_create_namespace("gubbins.misc.md")
    local filetype = get_filetype(bufnr)
    validate_filetype(filetype)

    local parser = ts.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    local query_string = [[
        (fenced_code_block) @cell
    ]]
    local query = ts.query.parse(filetype, query_string)
    local i = 1
    for id, node in query:iter_captures(root, bufnr) do
        local row1, col1, _, _ = node:range()
        local text_tbl = api.nvim_buf_get_text(bufnr, row1, col1, row1, -1, {})
        assert(#text_tbl == 1, "expected one match")
        local text = text_tbl[1]
        if starts_with(text, "```{") then
            local virt_text = { { "#" .. tostring(i), hl_group } }
            api.nvim_buf_set_extmark(bufnr, ns_id, row1, col1, { virt_text = virt_text, virt_text_pos = "eol", ephemeral=false})
            i = i + 1
        end
    end
    -- TODO: delete mark on line delete
    return ns_id
end

vim.keymap.set("n", "<leader>hlc", function()
    M.highlight_cells(0)
end)

return M
