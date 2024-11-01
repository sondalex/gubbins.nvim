---@diagnostic disable-next-line: undefined-global
local vim = vim

local utils = require("gubbins.ui.utils")
local M = {}

local hide_window = function(win, opts)
    if opts.border ~= "none" then
        opts.config.border = "none"
        vim.api.nvim_win_set_config(win, opts.config)
    end
    vim.api.nvim_win_set_height(win, 0)
    vim.api.nvim_win_set_width(win, 0)
end

--- @param frame_win number The main window
--- @param win number The floating window to anchor
--- @param opts table Table with fields:
---
--- - config table See :help nvim_win_get_config
---
--- - border string|nil
---
--- - height number
---
--- - width  number
local out_of_frame_factory = function(frame_win, frame_buf, win, opts)
    return function()
        if vim.api.nvim_win_is_valid(win) then
            local current_height = vim.api.nvim_win_get_height(win)
            local bottom_limit = vim.fn.line("w$", frame_win) - 1 -- -1 to transform in zero indexed.
            local top_limit = vim.fn.line("w0", frame_win) - 1 -- ibid.
            local row = opts.config.bufpos[1] -- bufpos --> zero indexed
            local height_offset = 0
            local extmark_offset = utils.get_number_virt_lines(frame_buf, { row, 0 }, { bottom_limit, 0 })
            print(
                "top_limit: "
                    .. top_limit
                    .. ", bottom_limit: "
                    .. bottom_limit
                    .. ", extmark_offset: "
                    .. extmark_offset
                    .. ", row: "
                    .. row
            )
            if opts.border ~= "none" then
                height_offset = 2
            end
            local has_extmark = 0
            if extmark_offset > 0 then
                has_extmark = 1
            end
            if row < top_limit - 1 + has_extmark then
                hide_window(win, opts)
            elseif row + opts.height + height_offset - extmark_offset + has_extmark > bottom_limit then
                hide_window(win, opts)
            else
                if opts.config.border ~= opts.border then
                    opts.config.border = opts.border
                    vim.api.nvim_win_set_config(win, opts.config)
                end
                local current_width = vim.api.nvim_win_get_width(win)
                if current_height ~= opts.height or current_width ~= opts.width then
                    vim.api.nvim_win_set_width(win, opts.width)
                    vim.api.nvim_win_set_height(win, opts.height)
                end
            end
        end
    end
end

--- @param opts table Table with fields:
---
--- - previous_lines
---
--- - bufpos
---
--- - penalty
---
--- - config table See :help nvim_win_get_config
local text_changed_factory = function(frame_win, frame_buf, win, opts)
    return function()
        if opts.penalty == nil then
            opts.penalty = 0
        end
        if vim.api.nvim_win_is_valid(win) then
            local cursor_line = vim.api.nvim_win_get_cursor(frame_win)[1]
            local current_lines = vim.api.nvim_buf_line_count(frame_buf)

            if current_lines ~= opts.previous_lines then
                local offset = current_lines - opts.previous_lines
                if offset < 0 then
                    if (cursor_line - 1) <= opts.config.bufpos[1] + offset + 1 then
                        opts.config.bufpos = { opts.config.bufpos[1] + offset - opts.penalty, opts.config.bufpos[2] }

                        vim.api.nvim_win_set_config(win, opts.config)
                        opts.penalty = 0
                    else
                        opts.penalty = opts.penalty + offset + 1
                    end
                    opts.previous_lines = current_lines
                end
                if offset > 0 then
                    if (cursor_line - 1) < opts.config.bufpos[1] + offset + 1 then
                        opts.config.bufpos = { opts.config.bufpos[1] + offset - opts.penalty, opts.config.bufpos[2] }

                        vim.api.nvim_win_set_config(win, opts.config)
                        opts.penalty = 0
                    else
                        opts.penalty = opts.penalty + offset - 1
                    end
                    opts.previous_lines = current_lines
                end
            end
            return opts.previous_lines, opts.penalty
        end
        return nil, nil
    end
end

--- @param frame_win number The main window id
--- @param win number The floating window id
--- @param frame_buf number The buffer of the main window, on which scroll event should be listened on
local hide_out_of_frame_window = function(frame_win, frame_buf, win)
    local config = vim.api.nvim_win_get_config(win)
    local height = config.height
    local width = config.width
    local border = config.border
    vim.api.nvim_create_autocmd("WinScrolled", {
        buffer = frame_buf,
        once = false,
        callback = out_of_frame_factory(
            frame_win,
            frame_buf,
            win,
            { height = height, width = width, config = config, border = border }
        ),
    })
    local lines_count = vim.api.nvim_buf_line_count(frame_buf)
    local penalty = 0
    vim.api.nvim_create_autocmd("TextChanged", {
        buffer = frame_buf,
        once = false,
        callback = function()
            if vim.api.nvim_win_is_valid(win) then
                lines_count, penalty = text_changed_factory(
                    frame_win,
                    frame_buf,
                    win,
                    { penalty = penalty, previous_lines = lines_count, config = config }
                )()
            end
            out_of_frame_factory(
                frame_win,
                frame_buf,
                win,
                { height = height, width = width, config = config, border = border }
            )()
        end,
    })

    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = frame_buf,
        once = false,
        callback = function()
            if vim.api.nvim_win_is_valid(win) then
                lines_count, penalty = text_changed_factory(
                    frame_win,
                    frame_buf,
                    win,
                    { penalty = penalty, previous_lines = lines_count, config = config }
                )()
            end
            out_of_frame_factory(
                frame_win,
                frame_buf,
                win,
                { height = height, width = width, config = config, border = border }
            )()
        end,
    })
end

local check_win_in_main_frame = function(frame_win, bufpos, height)
    local top_limit = vim.fn.line("w0", frame_win)
    local top_limit_row = top_limit - 1
    local bottom_limit = vim.fn.line("w$", frame_win)
    local bottom_limit_row = bottom_limit - 1
    if bufpos[1] < top_limit_row - 1 or bufpos[1] > bottom_limit_row - height then
        error("Window creation failed. Tried setting out of focus window")
        return false
    end
    return true
end
--- Create an anchored window which stays inplace and hide if out of frame.
--- @param frame_win number|nil Window id
--- @param frame_buf number|nil Buffer id
--- @param bufpos table|nil A tuple with `{row, col}`. Zero indexed.
--- @param config table A config for new anchored window
--- @return number|nil new_win The anchored window id.
function M.create_anchored_window(frame_win, frame_buf, bufpos, config)
    if frame_win == nil then
        frame_win = vim.api.nvim_get_current_win()
    end
    if frame_buf == nil then
        frame_buf = vim.api.nvim_get_current_buf()
    end
    if bufpos == nil then
        local bufpos_row = vim.api.nvim_win_get_cursor(frame_win)[1] - 1
        local bufpos_col = 0
        bufpos = { bufpos_row, bufpos_col }
    end

    if check_win_in_main_frame(frame_win, bufpos, config.height) == false then
        return nil
    end

    local new_buf = vim.api.nvim_create_buf(false, true)
    local win_config = {
        bufpos = bufpos,
        win = frame_win,
        relative = "win",
    }
    utils.merge_table(config, win_config)
    local new_win = vim.api.nvim_open_win(new_buf, true, win_config)
    hide_out_of_frame_window(frame_win, frame_buf, new_win)
    return new_win
end

return M
