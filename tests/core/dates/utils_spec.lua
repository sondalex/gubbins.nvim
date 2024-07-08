local dates = require("gubbins.dates.utils")

describe("Date functions", function()
    it("should detect dates in a line", function()
        assert.is_true(dates.has_dates("This is a date: 12/31/2022"))
        assert.is_true(dates.has_dates("This is a date: 2022-12-31"))
        assert.is_false(dates.has_dates("No date here"))
    end)

    it("should extract date spans correctly", function()
        local spans = dates.get_dates_span("This is a date: 12/31/2022 and another 01-01-2023")
        assert.same({ { 17, 26 }, { 40, 49 } }, spans)
    end)

    it("should convert MM/DD/YYYY to YYYY-MM-DD", function()
        assert.are.equal("2022-12-31", dates.mdy_iso8601("12/31/2022", "/"))
    end)

    it("should convert DD/MM/YYYY to YYYY-MM-DD", function()
        assert.are.equal("2022-12-31", dates.dmy_iso8601("31/12/2022", "/"))
    end)

    it("should convert YYYY-MM-DD to MM/DD/YYYY", function()
        assert.are.equal("12/31/2022", dates.iso8601_mdy("2022-12-31", "-"))
    end)

    it("should convert YYYY-MM-DD to DD/MM/YYYY", function()
        assert.are.equal("31/12/2022", dates.iso8601_dmy("2022-12-31", "-"))
    end)

    it("should get date separator correctly", function()
        assert.are.equal("/", dates.get_date_separator("12/31/2022"))
        assert.are.equal("-", dates.get_date_separator("31-12-2022"))
        assert.are.equal(".", dates.get_date_separator("31.12.2022"))
        assert.are.equal("-", dates.get_date_separator("2022-12-31"))
        assert.is_nil(dates.get_date_separator("12312022"))
    end)

    it("should infer date format correctly", function()
        assert.are.equal("mdy", dates.infer_date_form("12/31/2022"))
        assert.are.equal("dmy", dates.infer_date_form("31/12/2022"))
        assert.are.equal("iso8601", dates.infer_date_form("2022-12-31"))
        assert.is_nil(dates.infer_date_form("12312022"))
    end)

    it("should convert dates in lines to specified format", function()
        local lines = {
            "This is a date: 12/31/2022 and another 01-01-2023",
            "ISO date format: 2023-07-08",
        }
        local converted_lines = dates.convert_dates(lines, "iso8601")
        assert.same({
            "This is a date: 2022-12-31 and another 2023-01-01",
            "ISO date format: 2023-07-08",
        }, converted_lines)
    end)
end)
