---@diagnostic disable-next-line: undefined-global
local api = vim.api
local M = {}

function M.create_file(filename)
    api.nvim_command("edit " .. filename)
end

return M
