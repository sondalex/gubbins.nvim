-- @module gubbins.cmd
local utils = require("gubbins.utils")
local stream = require("gubbins.stream")

---@diagnostic disable-next-line: undefined-global
local api = vim.api

---@diagnostic disable-next-line: undefined-global
local uv = vim.loop

---@diagnostic disable-next-line: undefined-global
local schedule = vim.schedule

local M = {}

--- @param opts table|nil Options for the window. If nil, the default options are used.
--- The default options are:
--- <pre>
--- {
--- relative = "win",
--- width = 80,
--- height = 10,
--- row = 10,
--- col = 10,
--- border = "single",
--- style = "minimal",
--- bufpos = { 100, 10 }
--- }
--- </pre>
--- @return integer Window ID
local open_win = function(bufnr, opts)
    local defaults = {
        relative = "win",
        width = 80,
        height = 10,
        row = 10,
        col = 10,
        border = "single",
        style = "minimal",
        bufpos = { 100, 10 },
    }
    local new_opts
    if opts == nil then
        new_opts = defaults
    else
        new_opts = utils.copy(opts)
        for k, v in pairs(defaults) do
            if new_opts[k] == nil then
                new_opts[k] = v
            end
        end
    end
    local win = api.nvim_open_win(bufnr, true, new_opts)
    return win
end

--- @param text table
--- @param opts table|nil See `open_win` for options
--- @param useterm boolean|nil If true, use a terminal buffer
--- @return integer Buffer ID
--- @return integer Window ID
local text_window = function(text, useterm, opts)
    local buf = api.nvim_create_buf(false, true)
    local win = open_win(buf, opts)
    local text_table = utils.splitlines(text)
    if useterm then
        local term = api.nvim_open_term(buf, {})
        api.nvim_chan_send(term, table.concat(text_table, "\r\n"))
    else
        api.nvim_buf_set_lines(buf, 0, -1, false, text_table)
    end
    return buf, win
end

--- @param cmd string[]
--- @param useterm boolean|nil
--- @param winopts table|nil See `open_win` for options
--- @param wincallback function|nil Callback to run after the window is created.
---
--- Example:
---
--- <pre>
--- system2({ "ls", "-l" }, false, nil, function(buf, win)
---	api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
---		noremap = true,
---		silent = true,
---		callback = function()
---			api.nvim_win_close(win, false)
---		end,
---	})
--- end)
--- </pre>
local system2 = function(cmd, useterm, winopts, wincallback)
    if useterm == nil then
        useterm = true
    end

    local stdin = assert(uv.new_pipe(false))
    local stdout = assert(uv.new_pipe(false))
    local stderr = assert(uv.new_pipe(false))

    local buf = api.nvim_create_buf(false, true)

    local win = open_win(buf, winopts)
    if wincallback then
        wincallback(buf, win)
    end
    local term
    if useterm then
        term = api.nvim_open_term(buf, {})
    end

    local handle
    handle = stream.spawn(cmd, { stdio = { stdin, stdout, stderr } }, function(code, signal)
        stream.close_resources(stdin, stdout, stderr, handle)
    end)
    uv.read_start(stdout, stream.linebyline(stdout, buf, term))
    uv.read_start(stdin, stream.linebyline(stdin, buf, term))
    uv.read_start(stderr, stream.linebyline(stderr, buf, term))
end

--- @param cmd string[]
--- @param useterm boolean|nil
--- @param winopts table|nil See `open_win` for options
local system = function(cmd, useterm, winopts, wincallback)
    local stdin = assert(uv.new_pipe(false))
    local stdout = assert(uv.new_pipe(false))
    local stderr = assert(uv.new_pipe(false))

    local stdin_data = {}
    local stdout_data = {}
    local stderr_data = {}

    local handle
    handle = stream.spawn(cmd, { stdio = { stdin, stdout, stderr } }, function(code, signal)
        local out
        if #stderr_data > 0 then
            out = stderr_data
        elseif #stdout_data > 0 then
            out = stdout_data
        end
        schedule(function()
            if out then
                local bufnr, win = text_window(out, useterm, winopts)
                if wincallback ~= nil then
                    wincallback(bufnr, win)
                end
            end
        end)
        stream.close_resources(stdin, stdout, stderr, handle)
    end)
    uv.read_start(stdout, stream.fill_bucket(stdout, stdout_data))
    uv.read_start(stdin, stream.fill_bucket(stdin, stdin_data))
    uv.read_start(stderr, stream.fill_bucket(stderr, stderr_data))
end

--- @param cmd string[] A list of strings that make up the command to be executed
--- @param useterm boolean If true, the command will be executed in a terminal buffer. If you expect to run a command that outputs colour escape codes, you should set this to true.
--- @param waitcompletion boolean If true, stdout or stderr will be printed once command is completed. If false, stdout and stderr will be printed to window as they are received.
--- @param winopts table|nil See `open_win` for options
--- Example
---
--- <pre>
--- local cmd = require("gubbins.cmd")
--- cmd.run({ "ls", "-l" }, true, false, nil, nil)
--- </pre>
function M.run(cmd, useterm, waitcompletion, winopts, wincallback)
    if waitcompletion then
        system(cmd, useterm, winopts, wincallback)
    else
        system2(cmd, useterm, winopts, wincallback)
    end
end

return M
