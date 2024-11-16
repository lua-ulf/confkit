local assert = require("luassert")

local types = require("ulf.confkit.types")
local TC = require("spec.test_cases")({ it = it })
local H = require("spec.helpers")

local f = string.format

describe("#ulf.confkit.types", function()
	describe("types", function()
		TC.TestCase.types.default_type("string")
		TC.TestCase.types.default_type("number")
		TC.TestCase.types.default_type("boolean")
		TC.TestCase.types.default_type("table")
	end)

	describe("register", function()
		it("registers a type", function()
			local validator = function(field, context) end

			types.register(
				"confkit:choice",
				"provides a field which allows choices between: a and b",
				{ validator },
				{}
			)

			local field_type = types.get("confkit:choice")

			assert.equal("confkit:choice", field_type.id)
			assert.equal("provides a field which allows choices between: a and b", field_type.description)
			assert.Table(field_type.validators)
			assert.equal(validator, field_type.validators[1])
		end)
	end)
end)
