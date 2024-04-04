-- @module gubbins.stream
local utils = require("gubbins.utils")

---@diagnostic disable-next-line: undefined-global
local api = vim.api
---@diagnostic disable-next-line: undefined-global
local uv = vim.loop
---@diagnostic disable-next-line: undefined-global
local schedule = vim.schedule

local M = {}

--- Function that returns a callback. Once callback is called, the stream_bucket is filled with the stream data.
--- @param stream unknown
--- @param stream_bucket table
--- @return function
function M.fill_bucket(stream, stream_bucket)
    return function(err, data)
        if err then
            utils.nvim_err(err)
        end

        if data ~= nil then
            stream_bucket[#stream_bucket + 1] = data
        else
            stream:read_stop()
            stream:close()
        end
    end
end

function M.linebyline(stream, bufnr, term)
    return function(err, data)
        if err then
            utils.nvim_err(err)
        end
        if data ~= nil then
            schedule(function()
                local text_table = {}
                local splitted_data = utils.split(data, "\n")
                for _, line in ipairs(splitted_data) do
                    if term ~= nil then
                        table.insert(text_table, line)
                    else
                        if line ~= "" then
                            table.insert(text_table, line)
                        end
                    end
                end
                if term ~= nil then
                    api.nvim_chan_send(term, table.concat(text_table, "\r\n"))
                else
                    local linecount = api.nvim_buf_line_count(bufnr)
                    api.nvim_buf_set_lines(bufnr, linecount, -1, false, text_table)
                end
            end)
        else
            stream:read_stop()
            stream:close()
        end
    end
end

--- Spawn a new process
---
--- @param cmd string[]
--- @param callback function
--- @param opts table The options fields are:
---
---
--- - stdio
---
--- - env
---
--- - cwd
---
--- - uid
---
--- - gid
---
--- - verbatim
---
--- - detached
---
--- - hide
---
--- @return number pid The handle
function M.spawn(cmd, opts, callback)
    local new_opts = utils.copy(opts)
    new_opts["args"] = utils.slice(cmd, 2, nil)
    local handle, pid = uv.spawn(cmd[1], new_opts, callback)
    if handle == nil then
        utils.nvim_err("Error: " .. pid)
    end
    return handle, pid
end

--- @param resource unknown A stream or a handle
--- @return nil
function M.close_resource(resource)
    if resource then
        if resource:is_closing() then
            return
        end
        uv.close(resource)
    end
end

function M.close_resources(stdin, stdout, stderr, handle)
    M.close_resource(stdin)
    M.close_resource(stdout)
    M.close_resource(stderr)
    M.close_resource(handle)
end

return M
