local M = {}
function M.now(format)
    return os.date(format)
end
return M
