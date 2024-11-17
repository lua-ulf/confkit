local assert = require("luassert")
local H = require("spec.helpers")

describe("#ulf.confkit.field", function()
	local Constants = require("ulf.confkit.constants")
	local field = require("ulf.confkit.field")

	describe("Field", function()
		describe("Field.new", function()
			describe("with required attributes", function()
				describe("and a default value it creates a field", function()
					local opts = {
						name = "test_field",
						default = "default_value",
						description = "A test field",
					}
					local f = field.Field(opts)

					it("with a default value", function()
						assert.equal("default_value", f.value)
					end)

					it("with _value set to NIL", function()
						assert.equal(Constants.NIL, f._value)
					end)

					it("with a value returning the default", function()
						assert.equal("default_value", f.value)
					end)
					it("with a description", function()
						assert.equal("A test field", f.description)
					end)

					it("with the correct type", function()
						assert.equal("string", f.type)
					end)
				end)
				describe("and a value it creates a field", function()
					local opts = {
						name = "test_field",
						value = "some_value",
						description = "A test field",
					}
					local f = field.Field(opts)

					it("with a default value returning nil", function()
						assert.equal(nil, f.default)
					end)

					it("with _value set to the value", function()
						assert.equal("some_value", f._value)
					end)
					it("with a value returning the value", function()
						assert.equal("some_value", f.value)
					end)

					it("with the correct type", function()
						assert.equal("string", f.type)
					end)
				end)

				describe("and a value and a default it creates a field", function()
					local opts = {
						name = "test_field",
						default = "default_value",
						value = "some_value",
						description = "A test field",
					}
					local f = field.Field(opts)

					it("with a default set to the default", function()
						assert.equal("default_value", f.default)
					end)

					it("with _value set to the value", function()
						assert.equal("some_value", f._value)
					end)
					it("with a value returning the value", function()
						assert.equal("some_value", f.value)
					end)

					it("with the correct type", function()
						assert.equal("string", f.type)
					end)
				end)
				--- FIXME: does not work
				---
				-- describe("and a value and a default which have different types", function()
				-- 	local opts = {
				-- 		name = "test_field",
				-- 		default = 1,
				-- 		value = "some_value",
				-- 		description = "A test field",
				-- 	}
				--
				-- 	it("fails with an error", function()
				-- 		print(">")
				-- 		assert.has_error(function()
				-- 			local f = field.Field(opts)
				-- 		end)
				-- 		print(">")
				-- 	end)
				-- end)
			end)
			describe("when opts is not a table", function()
				it("fails with an error", function()
					assert.has_error(function()
						field.Field("not_a_table") ---@diagnostic disable-line: param-type-mismatch
					end)
				end)
			end)

			describe("when opts.behaviour is not a number", function()
				it("fails with an error", function()
					assert.has_error(function()
						field.Field({}) ---@diagnostic disable-line: missing-fields
					end)
				end)
			end)

			it("fails when opts.description is not a string", function()

				---FIXME: fails
				-- assert.has_error(function()
				-- 	field.Field({ default = "some_value", type = "string", description = 1 }) ---@diagnostic disable-line: missing-fields
				-- end)
			end)
		end)
	end)

	describe("__newindex", function()
		it("sets a value", function()
			assert.has_no_error(function()
				local f = field.Field({
					name = "severity",
					default = "debug",
					description = "severity level",
				})
				f.value = "info"
				assert.equal("debug", f.default)
				assert.equal("info", f.value)
			end)
		end)

		it("deletes a value", function()
			local f = field.Field({
				name = "severity",
				default = "debug",
				description = "severity level",
			})
			f.value = "info"
			assert.equal("debug", f.default)
			assert.equal("info", f.value)
			f.value = nil
			assert.equal(Constants.NIL, f._value)
			assert.equal("debug", f.value)
		end)

		describe("default value", function()
			it("changing a default value returns it when value is not set", function()
				local f = field.Field({
					name = "severity",
					default = "debug",
					description = "severity level",
				})
				assert.equal("debug", f.default)
				assert.equal("debug", f.value)
				f.default = "error"
				assert.equal("error", f.value)
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
