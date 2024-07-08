local api = vim.api

--[[
-- Returns true if line has one or more dates detected
--]]
local has_dates = function(line)
    local date_pattern = "%d%d?[%./%-]%d%d?[%./%-]%d%d%d%d"
    local iso_pattern = "%d%d%d%d[%./%-]%d%d[%./%-]%d%d"
    if string.match(line, date_pattern) then
        return true
    end
    if string.match(line, iso_pattern) then
        return true
    end
    return false
end

--[[
-- Extract dates spans (start and end positions)
--]]
local get_dates_span = function(line)
    local spans = {}
    local patterns = {
        "%d%d?[%./%-]%d%d?[%./%-]%d%d%d%d", -- mdy and dmy
        "%d%d%d%d[%./%-]%d%d[%./%-]%d%d", -- iso8601
    }
    for _, pattern in ipairs(patterns) do
        for start_pos, end_pos in line:gmatch("()" .. pattern .. "()") do
            table.insert(spans, { start_pos, end_pos - 1 })
        end
    end
    return spans
end

--[[
-- Convert MM/DD/YYYY to YYYY-MM-DD
--]]
local mdy_iso8601 = function(date, separator)
    local m, d, y = date:match("(%d%d?)" .. separator .. "(%d%d?)" .. separator .. "(%d%d%d%d)")
    return string.format("%04d-%02d-%02d", y, m, d)
end

--[[
-- Convert DD/MM/YYYY to YYYY-MM-DD
--]]
local dmy_iso8601 = function(date, separator)
    local d, m, y = date:match("(%d%d?)" .. separator .. "(%d%d?)" .. separator .. "(%d%d%d%d)")
    return string.format("%04d-%02d-%02d", y, m, d)
end

--[[
-- Convert YYYY-MM-DD to MM/DD/YYYY
--]]
local iso8601_mdy = function(date, separator)
    local y, m, d = date:match("(%d%d%d%d)" .. separator .. "(%d%d)" .. separator .. "(%d%d)")
    return string.format("%02d/%02d/%04d", m, d, y)
end

--[[
-- Convert YYYY-MM-DD to DD/MM/YYYY
--]]
local iso8601_dmy = function(date, separator)
    local y, m, d = date:match("(%d%d%d%d)" .. separator .. "(%d%d)" .. separator .. "(%d%d)")
    return string.format("%02d/%02d/%04d", d, m, y)
end

--[[
-- Get date separator
--]]
local get_date_separator = function(date)
    if date:match("%d%d?/%d%d?/%d%d%d%d") then
        return "/"
    elseif date:match("%d%d?%-%d%d?%-%d%d%d%d") then
        return "-"
    elseif date:match("%d%d?%.%d%d?%.%d%d%d%d") then
        return "."
    elseif date:match("%d%d%d%d%-%d%d%-%d%d") then
        return "-"
    else
        return nil
    end
end

--[[
-- Infer date format
--]]
local infer_date_form = function(date)
    local separator = get_date_separator(date)
    if not separator then
        return nil
    end

    local p1, p2, y = date:match("(%d%d?)" .. separator .. "(%d%d?)" .. separator .. "(%d%d%d%d)")
    if p1 and p2 and y then
        p1, p2, y = tonumber(p1), tonumber(p2), tonumber(y)
        if p1 <= 12 and p2 <= 31 and p2 > 12 then
            return "mdy"
        elseif p1 > 12 and p1 <= 31 and p2 <= 12 then
            return "dmy"
        else
            -- assuming mdy if ambiguous
            return "mdy"
        end
    end

    local y, m, d = date:match("(%d%d%d%d)" .. separator .. "(%d%d)" .. separator .. "(%d%d)")
    if y and m and d then
        return "iso8601"
    end

    return nil
end

local contains = function(t, x)
    for _, v in ipairs(t) do
        if v == x then
            return true
        end
    end
    return false
end

--[[
-- Validate and convert dates in lines to specified format
--]]
local convert_dates = function(lines, to)
    local valid_formats = { "mdy", "dmy", "iso8601" }
    if not contains(valid_formats, to) then
        error("Invalid `to` date format: " .. to .. "accepted `mdy`,`dmy`,`iso8601`")
    end

    local converted_lines = {}
    for _, line in ipairs(lines) do
        local new_line = line
        if has_dates(line) then
            local spans = get_dates_span(line)
            for _, span in ipairs(spans) do
                local date = line:sub(span[1], span[2])
                local separator = get_date_separator(date)
                local form = infer_date_form(date)
                if form == "mdy" and to == "iso8601" then
                    new_line = new_line:sub(1, span[1] - 1) .. mdy_iso8601(date, separator) .. new_line:sub(span[2] + 1)
                elseif form == "dmy" and to == "iso8601" then
                    new_line = new_line:sub(1, span[1] - 1) .. dmy_iso8601(date, separator) .. new_line:sub(span[2] + 1)
                elseif form == "iso8601" and to == "mdy" then
                    new_line = new_line:sub(1, span[1] - 1) .. iso8601_mdy(date, separator) .. new_line:sub(span[2] + 1)
                elseif form == "iso8601" and to == "dmy" then
                    new_line = new_line:sub(1, span[1] - 1) .. iso8601_dmy(date, separator) .. new_line:sub(span[2] + 1)
                end
            end
        end
        table.insert(converted_lines, new_line)
    end
    return converted_lines
end

local M = {}
M.convert_dates = convert_dates
M.has_dates = has_dates
M.get_dates_span = get_dates_span
M.mdy_iso8601 = mdy_iso8601
M.dmy_iso8601 = dmy_iso8601
M.iso8601_dmy = iso8601_dmy
M.iso8601_mdy = iso8601_mdy
M.get_date_separator = get_date_separator
M.infer_date_form = infer_date_form
return M
