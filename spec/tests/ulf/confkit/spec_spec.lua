local assert = require("luassert")
local H = require("spec.helpers")

describe("#ulf.confkit.spec", function()
	local spec = require("ulf.confkit.spec")
	local Constants = require("ulf.confkit.constants")

	describe("field", function()
		describe("is_field_spec", function()
			it("returns true for a valid Field spec with value and description", function()
				assert.True(spec.field.is_field_spec({ "default", "description" }))
			end)

			it("returns true for a Field spec with only a description and type", function()
				assert.True(spec.field.is_field_spec({ "description", type = "string" }))
			end)

			it("returns false for an invalid Field spec without type or value", function()
				assert.False(spec.field.is_field_spec({ "description" }))
			end)

			it("returns false if the table has a metatable", function()
				local t = setmetatable({}, {})
				assert.False(spec.field.is_field_spec(t))
			end)
		end)

		describe("parse_field", function()
			it("parses a field with value and description", function()
				local f = spec.field.parse("test_key", { "default", "A test description" })
				assert.equal("default", f.default)
				assert.equal("A test description", f.description)
				-- assert.equal("string", f.type)
			end)

			it("parses a field with only description and type", function()
				local f = spec.field.parse("test_key", { "A test description", type = "number" })
				assert.equal(nil, f.value)
				assert.equal(Constants.FIELD_BEHAVIOUR.OPTIONAL_FIELD, f.field_type)
				assert.equal("A test description", f.description)
				assert.equal("number", f.type)
			end)

			it("returns field.field_type=NON_FIELD if no type is provided for fields without a value", function()
				local f = spec.field.parse("test_key", { "A description for an optional field" })
				assert.equal(Constants.FIELD_BEHAVIOUR.NON_FIELD, f.field_type)
			end)

			it("returns field.field_type=NON_FIELD if description as the last list element is not a string", function()
				local f = spec.field.parse("severity", { "debug", 1 }) ---@diagnostic disable-line: assign-type-mismatch
				assert.equal(Constants.FIELD_BEHAVIOUR.NON_FIELD, f.field_type)
			end)

			it("parses a field when fallback is set", function()
				local f = spec.field.parse("severity", { "debug", "some desc", fallback = "fallback_key" }) ---@diagnostic disable-line: assign-type-mismatch
				assert.equal("fallback_key", f.fallback)
			end)

			it("parses a field when context is set", function()
				local context = {
					target = { obj = {} },
				}
				local f = spec.field.parse("severity", { "debug", "some desc", context = context }) ---@diagnostic disable-line: assign-type-mismatch
				assert.equal(context, f.context)
			end)

			describe("using hooks", function()
				it("parses a field if hook is set and a function", function()
					local hook = function(v)
						return 1
					end
					local f = spec.field.parse("severity", { "debug", "some desc", hook = hook })
					assert.equal("severity", f.name)
					assert.equal("debug", f.default)
					assert.equal(Constants.FIELD_BEHAVIOUR.MANDATORY_FIELD, f.field_type)
					assert.equal("some desc", f.description)
					assert.equal(hook, f.hook)
				end)
			end)
		end)
	end)
end)
