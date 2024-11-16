local M = {}

local it
local assert = require("luassert")
local H = require("spec.helpers")
local f = string.format

local TestCase = {}

M.TestCase = TestCase

TestCase.types = {}
TestCase.validator = {}

---@class test.test_case.validators.type_validator
---@field valid { field:test.ulf.confkit.FieldMock }
---@field invalid { field:test.ulf.confkit.FieldMock }

---@param config test.test_case.validators.type_validator
TestCase.validator.type_validator = function(config)
	local type_validator = require("ulf.confkit.validator").type_validator

	it("returns true when field.value is a " .. config.valid.field.type, function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.valid.field.value,
			type = config.valid.field.type,
		})
		local ok, err = type_validator(config.valid.field.type)(field)
		assert(ok)
		assert.Nil(err)
	end)

	it("returns false and an error when field.value is not a " .. config.valid.field.type, function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.invalid.field.value,
			type = config.valid.field.type,
		})
		local ok, err = type_validator(config.valid.field.type)(field)

		assert.False(ok)
		assert.equal(
			f(
				"Field '%s' type error, want '%s' but got '%s' [value=%s]",
				config.valid.field.name,
				config.valid.field.type,
				config.invalid.field.type,
				config.invalid.field.value
			),
			err
		)
	end)
end

---@param type_name string
TestCase.types.default_type = function(type_name)
	local types = require("ulf.confkit.types")

	it("field type " .. type_name .. " has the correct defaults", function()
		local field_type = types.get(type_name)

		assert.equal("basic " .. type_name .. " type", field_type.description)
		assert.equal(type_name, field_type.id)
		assert.Table(field_type.validators)
		assert.Function(field_type.validators[1])
	end)
end

return function(context)
	it = context.it ---@diagnostic disable-line: no-unknown
	return M
end
