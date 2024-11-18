local M = {}

---@type function
local it

local assert = require("luassert")
local H = require("spec.helpers")
local f = string.format

local TestCase = {}
local Validator = require("ulf.confkit.validator")

M.TestCase = TestCase

TestCase.types = {}
TestCase.validator = {}
TestCase.validator.CheckFuncs = {}
TestCase.validator.ValidatorSet = {}

---@class test.test_case.validators.type_validator
---@field valid { field:test.ulf.confkit.FieldMock }
---@field invalid { field:test.ulf.confkit.FieldMock }

---@param config test.test_case.validators.type_validator
TestCase.validator.ValidatorSet.string = function(config)
	it("returns true when field.value is a string", function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.valid.field.value,
			type = config.valid.field.type,
		})
		local ok, err = Validator.ValidatorSet.string(field)
		assert(ok)
		assert.Nil(err)
	end)
	it("returns false and an error when field.value is not a string", function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.invalid.field.value,
			type = config.valid.field.type,
		})
		local ok, err = Validator.ValidatorSet.string(field)

		assert.False(ok)
		assert.equal(
			f(
				"Field '%s' errors: type error, want '%s' but got '%s' [value=%s]",
				config.valid.field.name,
				config.valid.field.type,
				config.invalid.field.type,
				config.invalid.field.value
			),
			err
		)
	end)
	it("returns false and an error when length of field.value exceeds maxlen", function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.valid.field.value,
			type = config.valid.field.type,
			attributes = { maxlen = config.invalid.field.attributes.maxlen },
		})
		local ok, err = Validator.ValidatorSet.string(field)

		assert.False(ok)
		assert.equal(
			f(
				"Field '%s' errors: string length must be lower than %s [value=%s]",
				config.valid.field.name,
				config.invalid.field.attributes.maxlen,
				config.valid.field.value
			),
			err
		)
	end)
	it("returns false and an error when field.value does not match pattern", function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.valid.field.value,
			type = config.valid.field.type,
			attributes = { pattern = config.invalid.field.attributes.pattern },
		})
		local ok, err = Validator.ValidatorSet.string(field)

		assert.False(ok, "Expect validation result to be false")
		assert.equal(
			f(
				"Field '%s' errors: string must match pattern '%s' [value=%s]",
				config.valid.field.name,
				config.invalid.field.attributes.pattern,
				config.valid.field.value
			),
			err
		)
	end)
	it("returns true when all conditions are met", function()
		local field = H.field_mock({ ---@diagnostic disable-line: missing-fields
			name = config.valid.field.name,
			value = config.valid.field.value,
			type = config.valid.field.type,
			attributes = {
				maxlen = config.valid.field.attributes.maxlen,
				pattern = config.valid.field.attributes.pattern,
			},
		})
		local ok, _ = Validator.ValidatorSet.string(field)

		assert.True(ok, "Expect validation result to be true")
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
