local anchored = require("gubbins.ui.anchored")

local M = {}

---@diagnostic disable-next-line: undefined-global
local api = vim.api

local get_line_number = function(winnr)
    ---@diagnostic disable-next-line: undefined-global
    local linnr = api.nvim_win_get_cursor(0)[1]
    return linnr
end

local repeat_empty_virt_line = function(n)
    local vlines = {}
    local vline = {}
    ---@diagnostic disable-next-line: undefined-global
    vim.list_extend(vline, { { "", "Normal" } })
    for i = 1, n do
        table.insert(vlines, vline)
    end
    return vlines
end

--- @return ns_id number The namespace id
local set_embed_container = function(frame_win, frame_buf, bufpos, height)
    local ns_id = api.nvim_create_namespace("gubbins.ui.embed")
    local virt_lines = repeat_empty_virt_line(height)

    local row = bufpos[1]
    local col = bufpos[2]

    api.nvim_buf_set_extmark(frame_buf, ns_id, row, col, { virt_lines = virt_lines })
    return ns_id
end

--- @param frame_win number|nil Window id
--- @param frame_buf number|nil Buffer id
--- @param bufpos table|nil A tuple with `{row, col}`. Zero indexed.
--- @param config table A config for new anchored window
--- @return number|nil new_win The anchored window id.
function M.create_embed_window(frame_win, frame_buf, bufpos, config)
    local rheight = config.height
    if config.border ~= "none" then
        rheight = rheight + 2
    end

    if frame_win == nil then
        frame_win = api.nvim_get_current_win()
    end
    if frame_buf == nil then
        frame_buf = api.nvim_get_current_buf()
    end

    if bufpos == nil then
        local linnr = get_line_number(frame_win)
        bufpos = { linnr - 1, 0 }
    end
    local ns_id = set_embed_container(frame_win, frame_buf, bufpos, rheight)
    local status, err = pcall(function()
        anchored.create_anchored_window(frame_win, frame_buf, bufpos, config)
    end)
    if not status then
        api.nvim_buf_clear_namespace(frame_buf, ns_id, bufpos[1], bufpos[1] + 1)
        api.nvim_err_writeln(err)
    end
end

return M
