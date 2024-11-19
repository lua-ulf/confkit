local assert = require("luassert")
local H = require("spec.helpers")

local ulf = {
	lib = require("ulf.lib"),
}
local Util = require("ulf.confkit.util")
local Field = require("ulf.confkit.field")
local f = string.format
local TestCase = {}
TestCase.Schema = {}

local function to_bits(num, bits)
	-- returns a table of bits, most significant first.
	bits = bits or math.max(1, select(2, math.frexp(num)))
	---@type number[]
	local t = {} -- will contain the bits
	for b = bits, 1, -1 do
		t[b] = math.fmod(num, 2)
		num = math.floor((num - t[b]) / 2)
	end
	return t
end

---@class test.test_case.schema.validate.fiel_spec
---@field value any
---@field default? any
---@field name string
---@field description? string
---@field type? string
---@field behaviour? number[]
---@field context? ulf.confkit.field.context: Optional. A context for advanced behaviour
---@field assert? string

---@class test.test_case.schema.validate_expect
---@field fields table<string,test.test_case.schema.validate.fiel_spec>

---comment
---@param got ulf.confkit.schema.Schema
---@param want test.test_case.schema.validate_expect
TestCase.Schema.validate = function(got, want)
	for path, test_spec in pairs(want.fields) do
		local nodes = ulf.lib.string.split(path, ".", { plain = true })
		local field = ulf.lib.table.tbl_get(got, unpack(nodes))
		assert(field)

		if test_spec.value then
			it(f("field '%s' has value '%s'", path, test_spec.value), function()
				local assert_name = test_spec.assert or "equal"
				assert[assert_name](
					test_spec.value,
					field.value,
					f("expect '%s' to have value '%s', got '%s", test_spec.name, test_spec.value, field.value)
				)
			end)
		end

		if test_spec.default then
			it(f("field '%s' has a default value of '%s'", path, test_spec.default), function()
				assert.equal(
					test_spec.default,
					field.default,
					f(
						"expect '%s' to have a default value of '%s', got '%s",
						test_spec.name,
						test_spec.default,
						field.default
					)
				)
			end)
		end
		if test_spec.type then
			it(f("field '%s' is of type '%s'", path, test_spec.type), function()
				assert.equal(
					test_spec.type,
					field.type,
					f("expect '%s' to be of type '%s', got '%s", test_spec.name, test_spec.type, field.type)
				)
			end)
		end

		if test_spec.description then
			it(f("field '%s' has expected description", path), function()
				assert.equal(
					test_spec.description,
					field.description,
					f(
						"expect '%s' to have description '%s', got '%s",
						test_spec.name,
						test_spec.description,
						field.description
					)
				)
			end)
		end

		if type(test_spec.behaviour) == "table" and #test_spec.behaviour > 0 then
			for _, flag in ipairs(test_spec.behaviour) do
				local flag_str = tostring(flag)
				P({
					"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",

					Field.has_flag(field, flag),
				})
				-- local flag_str = table.concat(to_bits(8, flag), "") .. "b"
				it(f("field '%s' has expected behaviour '%s'", path, flag_str), function()
					assert.True(
						Field.has_flag(field, flag),
						f("expect '%s' to have flag '%s' set", test_spec.name, flag_str)
					)
				end)
			end
		end

		if type(test_spec.context) == "table" and type(test_spec.context.target) == "table" then
			it(f("field '%s' has expected context.target", path), function()
				assert.same(
					test_spec.context.target,
					field.context.target,
					f("expect '%s' to have expected context.target", test_spec.name)
				)
			end)
		end
	end
end

describe("#ulf.confkit.schema", function()
	local Schema = require("ulf.confkit.schema")
	local util = require("ulf.confkit.util")

	describe("Schema.new", function()
		describe("Schema root node and global node", function()
			TestCase.Schema.validate(
				Schema({
					version = {
						[[This is the schema version]],
						value = "1.1.0",
					},

					tag = {
						[[This is an optional tag]],
						type = "string",
					},
					global = Schema({
						severity = {
							"info",
							"Global severity level",
							hook = H.severity_to_number,
							type = "number",
						},
					}, "Global settings"),
				}),
				{
					fields = {

						["version"] = {
							name = "version",
							value = "1.1.0",
							type = "string",
							description = [[This is the schema version]],
						},

						["tag"] = {
							name = "tag",
							value = nil,
							type = "string",
							description = [[This is an optional tag]],
							behaviour = {
								Field.FIELD_BEHAVIOUR.OPTIONAL,
							},
						},
						["global.severity"] = {
							name = "severity",
							value = 2,
							type = "number",
							description = "Global severity level",
						},
					},
				}
			)
		end)

		describe("Schema with internal fallback value", function()
			local schema = Schema({
				version = {
					[[This is the schema version]],
					value = "1.1.0",
				},

				global = Schema({
					severity_global = {
						"info",
						"Global severity level",
						hook = H.severity_to_number,
						type = "number",
					},
				}, "Global settings"),

				logger = Schema({

					default = Schema({
						severity_logger = {
							"Logger severity level",
							hook = H.severity_to_number,
							type = "number",
						},
					}, "Default logger settings"),
				}, "Logger settings"),
			}, {
				description = "Schema root",
				fallback = {
					["logger.default.severity_logger"] = "global.severity_global",
				},
			})

			-- assert.equal(1, schema.logger.default.severity_logger.value)
			if false then
				TestCase.Schema.validate(schema, {
					fields = {

						["version"] = {
							name = "version",
							value = "1.1.0",
							type = "string",
							description = [[This is the schema version]],
						},

						["global.severity_global"] = {
							name = "severity",
							value = 2,
							type = "number",
							description = "Global severity level",
						},

						["logger.default.severity_logger"] = {
							name = "severity",
							-- value = 1,
							type = "number",
							description = "Logger severity level",
							behaviour = {
								Field.FIELD_BEHAVIOUR.FALLBACK,
							},
							-- context = {
							-- 	target = schema.global.severity,
							-- },
						},
					},
				})
			end
			print("<<<<<<<")
		end)
	end)

	describe("Schema.field", function()
		---@class test.TestSchema.global : ulf.confkit.schema.Schema
		---@field severity ulf.confkit.field.Field

		---@class test.TestSchema.logger.default : ulf.confkit.schema.Schema
		---@field severity ulf.confkit.field.Field

		---@class test.TestSchema.logger : ulf.confkit.schema.Schema
		---@field default test.TestSchema.logger.default

		---@class test.TestSchema : ulf.confkit.schema.Schema
		---@field version ulf.confkit.field.Field
		---@field tag ulf.confkit.field.Field
		---@field logger test.TestSchema.logger
		---@field global test.TestSchema.global
		local TestSchema = Schema({
			version = {
				[[This is the schema version]],
				value = "1.1.0",
			},
			enabled = {
				true,
				[[This is an boolean tag]],
			},

			tag = {
				[[This is an optional tag]],
				type = "string",
			},
			global = Schema({
				severity = {
					"info",
					"Global severity level",
					hook = H.severity_to_number,
					type = "number",
				},
			}, "Global settings"),
			logger = Schema({

				default = Schema({
					severity = {
						"Logger severity level",
						hook = H.severity_to_number,
						type = "number",
					},
				}, "Default logger settings"),
			}, "Logger settings"),
		})

		describe("get", function()
			it("returns a field by its path when dotted path has no children", function()
				local field = TestSchema.field.get("version")
				assert(field)
				assert(Util.is_field(field))
				assert.equal("version", field.name)
				--
			end)

			it("returns a field by its path when dotted path has children", function()
				local field = TestSchema.field.get("logger.default.severity")
				assert(field)
				assert(Util.is_field(field))
				assert.equal("severity", field.name)
				--
			end)
		end)

		describe("__call", function()
			it("when called it updates multiple fields", function()
				TestSchema({
					tag = "t1",
					enabled = true,
					version = "2",
				})
				assert.equal("t1", TestSchema.tag.value)
				assert.equal("2", TestSchema.version.value)
			end)
		end)
	end)
end)
