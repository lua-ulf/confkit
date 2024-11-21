local M = {}

---@class test.ulf.confkit.FieldMock
---@field name? string
---@field description? string
---@field hook? function
---@field type? string
---@field fallback? string
---@field attributes? table<string,any>
---@field value? any
---@field default? any

---@param opts test.ulf.confkit.FieldMock
M.field_mock = function(opts)
	return {
		name = opts.name,
		description = opts.description,
		default = opts.default,
		hook = opts.hook,
		fallback = opts.fallback,
		type = opts.type,
		attributes = opts.attributes,
		value = opts.value,
	}
end

---comment
---@param severity_name string
M.severity_to_number = function(severity_name)
	local smap = {
		trace = 0,
		debug = 1,
		info = 2,
		warn = 3,
		error = 4,
		off = 5,
	}

	return smap[severity_name]
end

---@return test.TestSchema
M.create_test_schema = function()
	local Schema = require("ulf.confkit.schema")
  ---@class test.TestSchema.global : ulf.confkit.schema.Schema,ulf.confkit.SchemaClass
  ---@field severity ulf.confkit.field.Field

  ---@class test.TestSchema.logger.default : ulf.confkit.schema.Schema,ulf.confkit.SchemaClass
  ---@field filename ulf.confkit.field.Field
  ---@field severity ulf.confkit.field.Field

  ---@class test.TestSchema.logger : ulf.confkit.schema.Schema,ulf.confkit.SchemaClass
  ---@field default test.TestSchema.logger.default

  -- stylua: ignore
  ---@class test.TestSchema : ulf.confkit.schema.Schema,ulf.confkit.SchemaClass
  ---@field fallback ulf.confkit.field.Field
  ---@field description ulf.confkit.field.Field
  ---@field version ulf.confkit.field.Field
  ---@field enabled ulf.confkit.field.Field
  ---@field opts ulf.confkit.field.Field
  ---@field priority ulf.confkit.field.Field
  ---@field tag ulf.confkit.field.Field
  ---@field logger test.TestSchema.logger
  ---@field global test.TestSchema.global
  return Schema({
    version = {[[This is the schema version]], value = "1.1.0",},
    enabled = {true, [[This is an boolean tag]],},
    priority = {10, [[This is the priority field]], type = "number",},
    opts = {[[This is the opts field]], type = "table",},
    tag = {[[This is an optional tag]], type = "string",},
    global = Schema({
      severity = {"info", "Global severity level", hook = M.severity_to_number, type = "number",},
    }, "Global settings"),
    logger = Schema({
      default = Schema({
        filename = {"Logger filename", type = "string",},
        severity = {"Logger severity level", hook = M.severity_to_number, type = "number",},
      }, "Default logger settings"),
    }, "Logger settings"),
  }, {
    description = "Schema root",
    fallback = { ["logger.default.severity"] = "global.severity" }
  })
end

return M
