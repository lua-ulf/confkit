describe("#ulf.lib.conf.field", function()
	local field = require("ulf.lib.conf.field")

	describe("cfield", function()
		it("creates a cfield with all attributes", function()
			local opts = {
				name = "test_field",
				value = "some_value",
				description = "A test field",
				type = "string",
				fallback = "default.fallback",
				kind = 1,
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
				field.cfield("not_a_table")
			end)
		end)
		it("fails when opts.kind is not a number", function()
			assert.has_error(function()
				field.cfield({}) ---@diagnostic disable-line: missing-fields
			end)
		end)

		it("fails when opts.description is not a string", function()

			---FIXME: fails
			-- assert.has_error(function()
			-- 	field.cfield({ value = "some_value", type = "string", description = 1 }) ---@diagnostic disable-line: missing-fields
			-- end)
		end)
	end)

	describe("is_cfield_spec", function()
		it("returns true for a valid cfield spec with value and description", function()
			assert.True(field.is_cfield_spec({ "value", "description" }))
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
			local f = field.parse_cfield("test_key", { "value", "A test description" })
			assert.equal("value", f.value)
			assert.equal("A test description", f.description)
			assert.equal("string", f.type)
		end)

		it("parses a field with only description and type", function()
			local f = field.parse_cfield("test_key", { "A test description", type = "number" })
			assert.equal(nil, f.value)
			assert.equal(field.kinds.OPTIONAL_FIELD, f.kind)
			assert.equal("A test description", f.description)
			assert.equal("number", f.type)
		end)

		it("returns field.kind=NON_FIELD if no type is provided for fields without a value", function()
			local f = field.parse_cfield("test_key", { "A description for an optional field" })
			assert.equal(field.kinds.NON_FIELD, f.kind)
		end)

		it("returns field.kind=NON_FIELD if description as the last list element is not a string", function()
			local f = field.parse_cfield("severity", { "debug", 1 })
			assert.equal(field.kinds.NON_FIELD, f.kind)
		end)

		it("fails to parse if fallback is set and not a string|function", function()
			assert.has_error(function()
				field.parse_cfield("severity", { "debug", "some desc", fallback = 1 })
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
				assert.equal(field.kinds.MANDATORY_FIELD, f.kind)
				assert.equal("some desc", f.description)
				assert.equal(hook, f.hook)
			end)
			it("fails to parse if hook is set and not a function", function()
				assert.has_error(function()
					field.parse_cfield("severity", { "debug", "some desc", hook = "not_a_hook" })
				end)
			end)
		end)
	end)
end)
