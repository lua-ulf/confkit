local assert = require("luassert")

local TC = require("spec.test_cases")({ it = it })
-- local H = require("spec.helpers")

describe("#ulf.confkit.validator", function()
	-- local Validator = require("ulf.confkit.validator")

	describe("type_validator", function()
		describe("number", function()
			TC.TestCase.validator.type_validator({
				valid = {
					field = { name = "length", type = "number", value = 1 },
				},
				invalid = {
					field = { value = "invalid", type = "string" },
				},
			})
		end)

		describe("number", function()
			TC.TestCase.validator.type_validator({
				valid = {
					field = { name = "name", type = "string", value = "test" },
				},
				invalid = {
					field = { value = 161, type = "number" },
				},
			})
		end)

		describe("boolean", function()
			TC.TestCase.validator.type_validator({
				valid = {
					field = { name = "enabled", type = "boolean", value = false },
				},
				invalid = {
					field = { value = 161, type = "number" },
				},
			})
		end)

		describe("table", function()
			TC.TestCase.validator.type_validator({
				valid = {
					field = { name = "opts", type = "table", value = { a = 1 } },
				},
				invalid = {
					field = { value = 161, type = "number" },
				},
			})
		end)
	end)
end)
