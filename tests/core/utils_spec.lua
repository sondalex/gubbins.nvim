local utils = require("gubbins.utils")

describe("test splitlines", function()
	local function test_splitlines()
		local expected = { "first line", "second line", "", "", "third line" }
		local actual = { "first line\nsecond line", "\n", "third line" }
		local result = utils.splitlines(actual)
		assert.are.same(expected, result)
	end

	it("should split lines", test_splitlines)
end)

local test_slice = function()
	local expected = { "-l", "-h" }
	local actual = { "ls", "-l", "-h" }
	local result = utils.slice(actual, 2, nil)
	assert.are.same(expected, result)

	expected = { "-l" }
	result = utils.slice(actual, 2, 2)
	assert.are.same(expected, result)
end

describe("test slice", function()
	it("should slice the table", test_slice)
end)
