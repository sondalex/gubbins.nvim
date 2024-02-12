local stream = require("gubbins.stream")
local utils = require("gubbins.utils")

---@diagnostic disable-next-line: undefined-global
local uv = vim.loop

local test_fill_bucket = function()
    local stream_bucket = {}
    local stdout = assert(uv.new_pipe(false))
    local handle
    handle = stream.spawn({ "cat", "1" }, { stdio = { nil, stdout, nil } }, function(code, signal)
        assert.are.same({ "1\n" }, stream_bucket)
        stream.close_resource(stdout)
        stream.close_resource(handle)
    end)
    local callback = stream.fill_bucket(stdout, stream_bucket)
    -- test with stream command
    uv.read_start(stdout, callback)
end

describe("test fill_bucket", function()
    it("should fill the bucket with the stream data", test_fill_bucket)
end)
