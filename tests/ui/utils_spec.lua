local utils = require("gubbins.ui.utils")

describe("test merge_table", function()
    local function test_merge_table()
        local tbl1 = { a = "1", b = "2", c = 3 }
        local tbl2 = { d = 4 }
        local expected = { a = "1", b = "2", c = 3, d = 4 }

        utils.merge_table(tbl1, tbl2)
        assert.are.same(expected, tbl2)
    end
    local function test_raise_error()
        if not pcall(function()
            utils.merge_table({ "1", 2 }, { 3 })
        end) then
            assert.are.same(true, true)
        else
            assert.are.same(false, true)
        end
    end

    it("should merge tables inline", test_merge_table)
    it("should raise error", test_raise_error)
end)
