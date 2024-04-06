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

describe("get_number_virt_lines", function()
    local setup = function(bufnr)
        local ns_id = vim.api.nvim_create_namespace("gubbins_test")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line1", "line2", "line3" })
        vim.api.nvim_buf_set_extmark(
            bufnr,
            ns_id,
            0,
            0,
            { virt_lines = { { { "1", "Normal" } }, { { "2", "Normal" } } } }
        )
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, 1, 0, { virt_lines = { { { "3", "Normal" } } } })
    end
    local teardown = function(bufnr)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end

    it("returns the number of virtual lines in a buffer", function()
        local bufnr = vim.api.nvim_create_buf(false, true)
        setup(bufnr)
        local virt_lines_extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { type = "virt_lines", details = true })
        local result = utils.get_number_virt_lines(bufnr)
        assert.are.equals(result, 3)
        teardown(bufnr)
    end)
end)
