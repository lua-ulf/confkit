local assert = require("luassert")
local H = require("spec.helpers")

describe("#ulf.confkit.util", function()
	local Field = require("ulf.confkit.field")
	local util = require("ulf.confkit.util")

	describe("is_field", function()
		it("returns true when object is a Field", function()
			local f = Field({
				name = "test_field",
				default = "default_value",
				description = "A test field",
				type = "string",
			})
			assert(util.is_field(f))
		end)
		it("returns false when object is not a Field", function()
			local f = 161
			assert.False(util.is_field(f)) ---@diagnostic disable-line: param-type-mismatch
			local v = setmetatable({ a = 1 }, { __class = { name = "not_a_field" } })
			assert.False(util.is_field(v))
			v = setmetatable({ a = 1 }, { __index = function(t, k) end })
			assert.False(util.is_field(v))
		end)
	end)
	describe("is_field_type", function()
		it("returns true when object is a Field", function()
			local field_type = require("ulf.confkit.types").get("string")
			assert(util.is_field_type(field_type))
		end)
		it("returns false when object is not a Field", function()
			local f = 161
			assert.False(util.is_field_type(f)) ---@diagnostic disable-line: param-type-mismatch
			local v = setmetatable({ a = 1 }, { __class = { name = "not_a_field" } })
			assert.False(util.is_field_type(v))
			v = setmetatable({ a = 1 }, { __index = function(t, k) end })
			assert.False(util.is_field_type(v))
		end)
	end)
end)
