local dates = require("gubbins.dates.utils")
local M = {}

---@diagnostic disable-next-line: undefined-global
local api = vim.api
function M.setup()
    -- Define the ISO8601 command
    api.nvim_create_user_command("ISO8601", function(opts)
        local start_line = (opts.line1 or 1) - 1
        local end_line = opts.line2 or -1

        local lines = api.nvim_buf_get_lines(0, start_line, end_line, false)
        local converted_lines = dates.convert_dates(lines, "iso8601")
        api.nvim_buf_set_lines(0, start_line, end_line, false, converted_lines)
    end, { range = true })
end

return M
