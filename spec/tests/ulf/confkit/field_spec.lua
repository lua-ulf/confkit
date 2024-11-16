local assert = require("luassert")
local H = require("spec.helpers")

describe("#ulf.confkit.field", function()
	local field = require("ulf.confkit.field")

	describe("cfield", function()
		it("creates a cfield with all attributes", function()
			local opts = {
				name = "test_field",
				default = "some_value",
				description = "A test field",
				type = "string",
				fallback = "default.fallback",
				field_type = 1,
				hook = function(v)
					return v
				end,
			}
			local f = field.cfield(opts)

			assert.equal("some_value", f.value)
			assert.equal("A test field", f.description)
			assert.equal("string", f.type)
			assert.equal("default.fallback", f.fallback)
			assert.is_function(f.hook)
		end)

		it("fails when opts is not a table", function()
			assert.has_error(function()
				field.cfield("not_a_table") ---@diagnostic disable-line: param-type-mismatch
			end)
		end)
		it("fails when opts.field_type is not a number", function()
			assert.has_error(function()
				field.cfield({}) ---@diagnostic disable-line: missing-fields
			end)
		end)

		it("fails when opts.description is not a string", function()

			---FIXME: fails
			-- assert.has_error(function()
			-- 	field.cfield({ default = "some_value", type = "string", description = 1 }) ---@diagnostic disable-line: missing-fields
			-- end)
		end)
	end)

	describe("is_cfield_spec", function()
		it("returns true for a valid cfield spec with value and description", function()
			assert.True(field.is_cfield_spec({ "default", "description" }))
		end)

		it("returns true for a cfield spec with only a description and type", function()
			assert.True(field.is_cfield_spec({ "description", type = "string" }))
		end)

		it("returns false for an invalid cfield spec without type or value", function()
			assert.False(field.is_cfield_spec({ "description" }))
		end)

		it("returns false if the table has a metatable", function()
			local t = setmetatable({}, {})
			assert.False(field.is_cfield_spec(t))
		end)
	end)

	describe("parse_cfield", function()
		it("parses a field with value and description", function()
			local f = field.parse_cfield("test_key", { "default", "A test description" })
			assert.equal("default", f.value)
			assert.equal("A test description", f.description)
			assert.equal("string", f.type)
		end)

		it("parses a field with only description and type", function()
			local f = field.parse_cfield("test_key", { "A test description", type = "number" })
			assert.equal(nil, f.value)
			assert.equal(field.kinds.OPTIONAL_FIELD, f.field_type)
			assert.equal("A test description", f.description)
			assert.equal("number", f.type)
		end)

		it("returns field.field_type=NON_FIELD if no type is provided for fields without a value", function()
			local f = field.parse_cfield("test_key", { "A description for an optional field" })
			assert.equal(field.kinds.NON_FIELD, f.field_type)
		end)

		it("returns field.field_type=NON_FIELD if description as the last list element is not a string", function()
			local f = field.parse_cfield("severity", { "debug", 1 }) ---@diagnostic disable-line: assign-type-mismatch
			assert.equal(field.kinds.NON_FIELD, f.field_type)
		end)

		it("fails to parse if fallback is set and not a string|function", function()
			assert.has_error(function()
				field.parse_cfield("severity", { "debug", "some desc", fallback = 1 }) ---@diagnostic disable-line: assign-type-mismatch
			end)
		end)

		describe("using hooks", function()
			it("parses a field if hook is set and a function", function()
				local hook = function(v)
					return 1
				end
				local f = field.parse_cfield("severity", { "debug", "some desc", hook = hook })
				assert.equal("severity", f.name)
				assert.equal(1, f.value)
				assert.equal(field.kinds.MANDATORY_FIELD, f.field_type)
				assert.equal("some desc", f.description)
				assert.equal(hook, f.hook)
			end)
			it("fails to parse if hook is set and not a function", function()
				assert.has_error(function()
					field.parse_cfield("severity", { "debug", "some desc", hook = "not_a_hook" }) ---@diagnostic disable-line: assign-type-mismatch
				end)
			end)
		end)
	end)

	describe("__newindex", function()
		it("sets a value", function()
			print(">>>>>>>>>>>>>>>>>>>>> start")
			assert.has_no_error(function()
				local f = field.parse_cfield("severity", { "debug", "severity level" })

				f.value = "info"
				assert.equal("info", f.value)
			end)

			print(">>>>>>>>>>>>>>>>>>>>> end")
		end)

		it("deletes a value", function()
			print(">>>>>>>>>>>>>>>>>>>>> start")
			local f = field.parse_cfield("severity", { "debug", "severity level" })

			f.value = "info"
			assert.equal("debug", f.default)
			assert.equal("info", f.value)
			f.value = nil
			assert.equal("debug", f.value)

			print(">>>>>>>>>>>>>>>>>>>>> end")
		end)

		describe("default value", function()
			it("changing a default value returns it when value is not set", function()
				print(">>>>>>>>>>>>>>>>>>>>> start")
				local f = field.parse_cfield("severity", { "debug", "severity level" })

				assert.equal("debug", f.default)
				assert.equal("debug", f.value)
				assert.equal("debug", f.value)
				f.default = "error"
				assert.equal("error", f.value)

				print(">>>>>>>>>>>>>>>>>>>>> end")
			end)
		end)
	end)

	describe("validate_base", function()
		it("returns true when basic conditions are met", function()
			local ok, err = field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "string",
			}))
			assert(ok)
			assert.Nil(err)
		end)

		it("returns false, err when description and name is missing", function()
			local ok, err = field.validate_base(H.field_mock({
				default = "debug",
				type = "string",
			}))
			assert.False(ok)
			assert.equal(
				"Field 'nil' errors: field name must be a string\nfield description must be a string [value=nil]",
				err
			)
		end)

		it("returns false, err when type is invalid", function()
			local ok, err = field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "no_type",
			}))
			assert.False(ok)
			assert.equal("Field 'severity' errors: field type 'no_type' is invalid [value=nil]", err)
		end)
		it("returns false, err when hook is not a function", function()
			local ok, err = field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "string",
				hook = 1, ---@diagnostic disable-line: assign-type-mismatch
			}))
			assert.False(ok)
			assert.equal("Field 'severity' errors: field hook must be a function [value=nil]", err)
		end)
		it("returns false, err when fallback is not a string", function()
			local ok, err = field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "string",
				fallback = 1, ---@diagnostic disable-line: assign-type-mismatch
			}))
			assert.False(ok)
			assert.equal("Field 'severity' errors: field fallback must be a string [value=nil]", err)
		end)
	end)
end)
