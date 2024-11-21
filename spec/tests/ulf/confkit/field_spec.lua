local assert = require("luassert")
local H = require("spec.helpers")

describe("#ulf.confkit.field", function()
	local Field = require("ulf.confkit.field")

	describe("Field", function()
		describe("Field.new", function()
			describe("with required attributes", function()
				describe("and a default value it creates a field", function()
					local f = Field({
						name = "test_field",
						default = "default_value",
						description = "A test field",
						type = "string",
					})

					it("with a default value", function()
						assert.equal("default_value", f.value)
					end)

					it("with _value set to NIL", function()
						assert.equal(Field.NIL, f._value)
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
					local f = Field({
						name = "test_field",
						value = "some_value",
						description = "A test field",
						type = "string",
					})

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
					local f = Field({
						name = "test_field",
						default = "default_value",
						value = "some_value",
						description = "A test field",
						type = "string",
					})

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
				describe("and no value and no default it creates an optional field", function()
					local f = Field({
						name = "test_field_optional",
						description = "A test field",
						type = "string",
						behaviour = 0,
					})
					it("with the correct type", function()
						assert.equal("string", f.type)
					end)

					it("returns nil as value", function()
						assert.Nil(f.value)
					end)

					it("has  nil as value", function()
						P("field", f)
						assert(Field.has_flag(f, Field.FIELD_BEHAVIOUR.OPTIONAL))
					end)
				end)
				--- FIXME: does not work
				---
				describe("and a value and a default which have different types", function()
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
				end)
			end)
			describe("error conditions", function()
				describe("when opts is not a table", function()
					it("fails with an error", function()
						assert.has_error(function()
							Field("not_a_table") ---@diagnostic disable-line: param-type-mismatch
						end)
					end)
				end)
				describe("when opts.behaviour is not a number", function()
					it("fails with an error", function()
						assert.has_error(function()
							Field({}) ---@diagnostic disable-line: missing-fields
						end)
					end)
				end)
				describe("when opts.description is not a string", function()
					it("fails with an error", function()

						---FIXME: fails
						-- assert.has_error(function()
						-- 	field.Field({ default = "some_value", type = "string", description = 1 }) ---@diagnostic disable-line: missing-fields
						-- end)
					end)
				end)
			end)
		end)
		describe("types", function()
			describe("boolean", function()
				it("writes a value when boolean field is optional", function()
					local f = Field({
						name = "boolean_field_optional",
						description = "description boolean_field_optional",
						type = "boolean",
					})
					assert.equal(nil, f.value)
					f.value = true
					assert.equal(true, f.value)

					f.value = false
					assert.equal(false, f.value)
				end)
			end)
			describe("string", function()
				it("writes a value when string field is optional", function()
					local f = Field({
						name = "string_field_optional",
						description = "description string_field_optional",
						type = "string",
					})
					assert.equal(nil, f.value)
					f.value = "test"
					assert.equal("test", f.value)
				end)

				it("fails when string length exceeds maxlen", function()
					assert.has_error(function()
						Field({
							name = "test_field",
							default = "default_value",
							description = "A test field",
							type = "string",
							attributes = {
								maxlen = 10,
							},
						})
					end, "Field 'test_field' errors: string length must be lower than 10 [value=default_value]")
				end)
				it("fails when string does not match pattern", function()
					assert.has_error(function()
						Field({
							name = "test_field",
							default = "default_value",
							description = "A test field",
							type = "string",
							attributes = {
								pattern = "^some_value",
							},
						})
					end, "Field 'test_field' errors: string must match pattern '^some_value' [value=default_value]")
				end)
			end)
		end)
	end)
	describe("__newindex", function()
		it("sets a value", function()
			assert.has_no_error(function()
				local f = Field({
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
			local f = Field({
				name = "severity",
				default = "debug",
				description = "severity level",
			})
			f.value = "info"
			assert.equal("debug", f.default)
			assert.equal("info", f.value)
			f.value = nil
			assert.equal(Field.NIL, f._value)
			assert.equal("debug", f.value)
		end)

		it("fails when validates raises an error", function()
			assert.has_error(function()
				local f = Field({
					name = "severity",
					default = "debug",
					description = "severity level",
				})
				f.value = false
			end)
		end)
		describe("default value", function()
			it("changing a default value returns it when value is not set", function()
				local f = Field({
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
		describe("fallback value", function()
			it("returns a value from fallback if fallback is set and no value is set", function()
				local obj = {

					severity = Field({
						name = "severity",
						value = "info",
						description = "fallback severity level",
					}),
				}

				assert.equal("info", obj.severity.value)
				local f = Field({
					name = "severity",
					description = "severity level",
					type = "string",
					fallback = "obj.severity",
					behaviour = Field.FIELD_BEHAVIOUR.FALLBACK,

					context = {
						target = obj.severity,
					},
				})

				assert.equal("info", f.value)
				f.value = "error"
				assert.equal("error", f.value)
				f.value = nil
				assert.equal("info", f.value)
			end)
		end)
		describe("fallback value with hooks", function()
			it("returns a value from fallback if fallback is set and no value is set", function()
				local obj = {

					severity = Field({
						name = "severity",
						value = "info",
						hook = H.severity_to_number,
						type = "number",
						description = "fallback severity level",
					}),
				}

				assert.equal(2, obj.severity.value)
				local f = Field({
					name = "severity",
					description = "severity level",
					fallback = "obj.severity",
					behaviour = Field.FIELD_BEHAVIOUR.FALLBACK,
					hook = H.severity_to_number,
					type = "number",
					context = {
						target = obj.severity,
					},
				})

				assert.equal(2, f.value)
				f.value = "error"
				assert.equal(4, f.value)
				f.value = nil
				assert.equal(2, f.value)
			end)
		end)
	end)
	describe("parse", function()
		it("returns a field when basic conditions are met", function()
			local f = Field.parse("severity", {
				"debug",
				"severity level",
			})
			assert(f)
		end)
	end)
	describe("validate_base", function()
		it("returns true when basic conditions are met", function()
			local ok, err = Field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "string",
			}))
			assert(ok)
			assert.Nil(err)
		end)

		it("returns false, err when description and name is missing", function()
			local ok, err = Field.validate_base(H.field_mock({
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
			local ok, err = Field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "no_type",
			}))
			assert.False(ok)
			assert.equal("Field 'severity' errors: field type 'no_type' is invalid [value=nil]", err)
		end)
		it("returns false, err when hook is not a function", function()
			local ok, err = Field.validate_base(H.field_mock({
				name = "severity",
				description = "severity level",
				default = "debug",
				type = "string",
				hook = 1, ---@diagnostic disable-line: assign-type-mismatch
			}))
			assert.False(ok)
			assert.equal("Field 'severity' errors: field hook must be a function [value=nil]", err)
		end)
		-- it("returns false, err when fallback is not a string", function()
		-- 	local ok, err = field.validate_base(H.field_mock({
		-- 		name = "severity",
		-- 		description = "severity level",
		-- 		default = "debug",
		-- 		type = "string",
		-- 		fallback = 1, ---@diagnostic disable-line: assign-type-mismatch
		-- 	}))
		-- 	assert.False(ok)
		-- 	assert.equal("Field 'severity' errors: field fallback must be a string [value=nil]", err)
		-- end)
	end)
end)
