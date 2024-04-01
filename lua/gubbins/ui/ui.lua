---@diagnostic disable-next-line: undefined-global
local vim = vim

local M = {}

--- Merge tbl1 and tbl2. tbl2 gets updated.
local merge_table = function(tbl1, tbl2)
    for k, v in pairs(tbl1) do
        tbl2[k] = v
    end
end

local out_of_frame_factory = function(frame_win, win, opts)
    return function()
        if vim.api.nvim_win_is_valid(win) then
            local current_height = vim.api.nvim_win_get_height(win)
            local bottom_limit = vim.fn.line("w$", frame_win) - 1 -- -1 to transform in zero indexed.
            local top_limit = vim.fn.line("w0", frame_win) - 1 -- ibid.
            local row = opts.config.bufpos[1] -- bufpos --> zero indexed
            local height_offset = 0
            if opts.border ~= "none" then
                height_offset = 2
            end
            if row < top_limit - 1 or row + opts.height + height_offset > bottom_limit then
                if opts.border ~= "none" then
                    opts.config.border = "none"
                    vim.api.nvim_win_set_config(win, opts.config)
                end

                vim.api.nvim_win_set_height(win, 0)
                vim.api.nvim_win_set_width(win, 0)
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

---@param opts
--- * previous_lines
--- * bufpos
--- * penalty
--- * config
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
local hide_out_of_frame_window = function(frame_win, frame_buf, win, opts)
    local height = opts.height
    local width = opts.width

    local config = vim.api.nvim_win_get_config(win)
    local border = config.border
    vim.api.nvim_create_autocmd("WinScrolled", {
        buffer = frame_buf,
        once = false,
        callback = out_of_frame_factory(
            frame_win,
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
            out_of_frame_factory(frame_win, win, { height = height, width = width, config = config, border = border })()
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
            out_of_frame_factory(frame_win, win, { height = height, width = width, config = config, border = border })()
        end,
    })
end

local check_win_in_main_frame = function(frame_win, bufpos, height)
    local top_limit = vim.fn.line("w0", frame_win)
    local top_limit_row = top_limit - 1
    local bottom_limit = vim.fn.line("w$", frame_win)
    local bottom_limit_row = bottom_limit - 1
    if bufpos[1] < top_limit_row - 1 or bufpos[1] > bottom_limit_row - height then
        vim.api.nvim_err_writeln("Window creation failed. Tried setting out of focus window")
        return false
    end
    return true
end
--- Create an anchored window which stays inplace and hide if out of frame.
--- @param frame_win number|nil Window id
--- @param frame_buf number|nil Buffer id
--- @param bufpos table|nil A tuple with `{row, col}`
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
    merge_table(config, win_config)
    local new_win = vim.api.nvim_open_win(new_buf, true, win_config)
    hide_out_of_frame_window(frame_win, frame_buf, new_win, {
        height = config.height,
        width = config.width,
        bufpos = bufpos,
    })
    return new_win
end

vim.keymap.set("n", "<leader>aw", function()
    M.create_anchored_window(nil, nil, nil, { height = 6, width = 80, border = "single" })
end)

vim.keymap.set("n", "<leader>av", function()
    local new_buf = vim.api.nvim_create_buf(false, true)
    local current_win = vim.api.nvim_get_current_win()
    local current_cursor = vim.api.nvim_win_get_cursor(current_win)[1]
    local row = current_cursor - (vim.fn.line("w0", current_win) - 1)
    --[[vim.api.nvim_open_win(new_buf, true, {
        relative = "cursor",
        -- win = current_win,
        row = row,
        col = -100,
        height = 6,
        width = 80
    })--]]
    vim.api.nvim_open_win(new_buf, true, {
        relative = "cursor",
        -- win = current_win,
        bufpos = { current_cursor - 1, 0 },
        height = 6,
        width = 80,
    })
end)
return M
