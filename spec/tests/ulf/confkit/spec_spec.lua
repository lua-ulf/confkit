local assert = require("luassert")
-- local H = require("spec.helpers")

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

		describe("parse", function()
			describe("string", function()
				it("parses a string field with attributes", function()
					local f = spec.field.parse(
						"test_key",
						{ "default", "A test description", maxlen = 10, pattern = "some_pat" }
					)
					assert(f)
					assert.equal("default", f.default)
					assert.equal("A test description", f.description)
					assert.equal(10, f.attributes.maxlen)
					assert.equal("some_pat", f.attributes.pattern)
				end)
			end)
			it("parses a field with value and description", function()
				local f = spec.field.parse("test_key", { "default", "A test description" })
				assert(f)
				assert.equal("default", f.default)
				assert.equal("A test description", f.description)
				-- assert.equal("string", f.type)
			end)

			it("parses a field with only description and type", function()
				local f = spec.field.parse("test_key", { "A test description", type = "number" })
				assert(f)
				assert.equal(nil, f.value)
				assert.equal(Constants.FIELD_BEHAVIOUR.OPTIONAL, f.behaviour)
				assert.equal("A test description", f.description)
				assert.equal("number", f.type)
			end)

			it("returns nil if no type is provided for fields without a value", function()
				local f = spec.field.parse("test_key", { "A description for an optional field without a type" })
				assert.Nil(f)
			end)

			it("returns nil if description as the last list element is not a string", function()
				local f = spec.field.parse("severity", { "debug", 1 }) ---@diagnostic disable-line: assign-type-mismatch
				assert.Nil(f)
			end)

			-- it("parses a field when fallback is set", function()
			-- 	local f = spec.field.parse("severity", { "debug", "some desc", fallback = "fallback_key" }) ---@diagnostic disable-line: assign-type-mismatch
			-- 	assert.equal("fallback_key", f.fallback)
			-- end)

			it("parses a field when context is set", function()
				local context = {
					target = { obj = {} },
				}
				local f = spec.field.parse("severity", { "debug", "some desc", context = context }) ---@diagnostic disable-line: assign-type-mismatch
				assert(f)
				assert.equal(context, f.context)
			end)

			describe("using hooks", function()
				it("parses a field if hook is set and a function", function()
					local hook = function(v)
						return 1
					end
					local f = spec.field.parse("severity", { "debug", "some desc", hook = hook })
					assert(f)
					assert.equal("severity", f.name)
					assert.equal("debug", f.default)
					assert.equal(Constants.FIELD_BEHAVIOUR.DEFAULT, f.behaviour)
					assert.equal("some desc", f.description)
					assert.equal(hook, f.hook)
				end)
			end)
		end)
	end)
end)
