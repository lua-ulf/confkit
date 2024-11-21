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
local TestSchema = H.create_test_schema()

---@class test.test_case.schema.validate.fiel_spec
---@field value any
---@field default? any
---@field name string
---@field description? string
---@field type? string
---@field behaviour? number[]
---@field context? ulf.confkit.field.context: Optional. A context for advanced behaviour
---@field assert? string
---@field is_fallback_routed? boolean

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
				-- P({
				-- 	"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
				-- 	Field.has_flag(field, flag),
				-- })
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

		if type(test_spec.is_fallback_routed) == "boolean" and test_spec.is_fallback_routed == true then
			it(f("field '%s' has expected is_fallback_routed", path), function()
				assert.equal(
					test_spec.is_fallback_routed,
					field:is_fallback_routed(),
					f(
						"expect '%s' to have is_fallback_routed '%s', got '%s",
						test_spec.name,
						test_spec.is_fallback_routed,
						field:is_fallback_routed()
					)
				)
			end)
		end
	end
end

describe("#ulf.confkit.schema", function()
	local Schema = require("ulf.confkit.schema")
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
			local schema = TestSchema:create_class().new()
			---@cast schema test.TestSchema
			TestCase.Schema.validate(schema, {
				fields = {

					["version"] = {
						name = "version",
						value = "1.1.0",
						type = "string",
						description = [[This is the schema version]],
					},

					["global.severity"] = {
						name = "severity",
						value = 2,
						type = "number",
						description = "Global severity level",
					},

					["logger.default.severity"] = {
						name = "severity",
						value = 2,
						type = "number",
						description = "Logger severity level",
						context = {
							target = schema.global.severity,
						},
						is_fallback_routed = true,
					},
				},
			})
		end)

		describe("Schema with internal fallback default", function()
			local schema = TestSchema:create_class().new()
			---@cast schema test.TestSchema
			it("has the expected values from the TestSchema", function()
				assert.equal(2, schema.logger.default.severity.value)
				assert.equal(2, schema.logger.default.severity.context.target.value)
			end)
			it("when setting a value fallback is disabled and the value is returned", function()
				schema.logger.default.severity.value = "error"
				assert.equal(4, schema.logger.default.severity.value)
				assert.equal("error", schema.logger.default.severity._value)
			end)

			it("clear deletes all values and field.value returns nil", function()
				schema.logger.default.severity:clear()
				assert.equal(nil, schema.logger.default.severity.value)
			end)
		end)
	end)

	describe("Schema.field", function()
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
					priority = 100,
					version = "2",
					opts = {
						timeout = 1000,
					},
				})
				TestSchema.logger.default({
					filename = "log",
				})
				assert.equal(100, TestSchema.priority.value)
				assert.equal("t1", TestSchema.tag.value)
				assert.equal("2", TestSchema.version.value)
				assert.equal(true, TestSchema.enabled.value)
				assert.same({ timeout = 1000 }, TestSchema.opts.value)

				assert.equal("log", TestSchema.logger.default.filename.value)
			end)
		end)
	end)

	---@diagnostic disable:undefined-field
	describe("Schema.create_class", function()
		it("returns a new SchemaClass", function()
			local schema1 = Schema({
				version = {
					[[This is the schema version]],
					value = "1.1.0",
				},
			})

			local schema2 = Schema({
				version = {
					[[This is the schema version]],
					value = "2.1.0",
				},
			})

			assert.equal("1.1.0", schema1.version.value)
			assert.equal("2.1.0", schema2.version.value)
			local class1 = schema1:create_class().new()
			local class2 = schema2:create_class().new()
			assert(class1)
			assert(class2)
			assert.equal("1.1.0", class1.version.value)
			assert.equal("2.1.0", class2.version.value)

			class1.version.value = "1.2.0"
			assert.equal("1.2.0", class1.version.value)
			assert.equal("2.1.0", class2.version.value)

			class2.version.value = "2.2.0"
			assert.equal("1.2.0", class1.version.value)
			assert.equal("2.2.0", class2.version.value)
		end)
	end)

	describe("traversal", function()
		describe("fields function", function()
			it("iterates over schema in defined order with only fields that have values", function()
				local expected = {
					{ "enabled", true },
					{ "opts", {
						timeout = 1000,
					} },
					{ "priority", 100 },
					{ "tag", "t1" },
					{ "version", "2" },
				}

				-- Collect results from pairs iterator
				---@type string[]
				local results = {}
				for _, node in ---@diagnostic disable-line: no-unknown
					TestSchema:fields() --[[@as table<string,ulf.confkit.schema.Schema> ]]
				do
					table.insert(results, { tostring(node.name), node.value })
				end
				assert.same(expected, results)
			end)
		end)
		describe("walk_post_order", function()
			it("traverses a schema in post order", function()
				local traversal_result = {}

				local expected = {
					{ "version", "2" },
					{ "global.severity", 2 },
					{ "tag", "t1" },
					{ "priority", 100 },
					{ "enabled", true },
					{ "logger.default.filename", "log" },
					{ "logger.default.severity" },
					{ "opts", { timeout = 1000 } },
				}

				TestSchema:walk(function(node_path, _field)
					table.insert(traversal_result, { tostring(node_path), _field.value })
				end)

				assert.same(expected, traversal_result)
			end)
		end)
	end)
end)
