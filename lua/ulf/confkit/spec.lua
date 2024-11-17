---@class ulf.confkit.spec
local M = {}

---@brief [[
--- `ulf.confkit.spec` is responsible for parsing and using specification tables
---
--- `ulf.confkit.spec.field`
--- functions for field specifications
---
--- `ulf.confkit.spec.ctable`
--- functions for ctable specifications
---
---
--- General sequence processing for a field:
---   1. user needs to parse a spec
---   2. `ulf.confkit.spec.field.parse` is called
---   3. if the parser detects errors it raises an error
---   4. the output of the parse function is a set of options,
---      for fields: ulf.confkit.field.FieldOptions
---   5. the constructor `ulf.confkit.field.Field` takes an option set
---   6. the pre validation hook is run which sets some reasonable defaults or
---      tries to guess missing values
---   7. validation is called, if errors are detected an error is raised
---   8. the constructor returns the field
---
---
---@brief ]]

local Constants = require("ulf.confkit.constants")

local trim = require("ulf.lib.string.trimmer").trim
local gsplit = require("ulf.lib.string.splitter").gsplit
local dedent = require("ulf.lib.string.dedent").dedent

local f = string.format
local Validator = require("ulf.confkit.validator")
local types = require("ulf.confkit.types")
local make_message = require("ulf.lib.error").make_message

---@class ulf.confkit.spec.field
M.field = {}

--- FieldSpec
---
--- Examples:
--- These examples start simple and introduce more features progressively.
---
--- Basic Field Definition:
--- <code=lua>
--- local field = require("ulf.lib.conf.field")
---
--- -- Define a field with a name and description:
--- local name_field = field.parse_cfield(
---   "name",
---   { "John Doe", "Name field" }
--- )
--- assert.equal("John Doe", name_field.value)
--- assert.equal("Name field", name_field.description)
--- </code>
---
--- Adding Data Type:
--- <code=lua>
--- local age_field = field.parse_cfield(
---   "age",
---   { 42, "Age field", type = "number" }
--- )
--- assert.equal(42, age_field.value)
--- assert.equal("number", age_field.type)
--- </code>
---
--- Using Hooks to Transform Values:
--- <code=lua>
--- local severity_to_number = function(severity_name)
---   local smap = {
---     trace = 0, debug = 1, info = 2, warn = 3, error = 4, off = 5
---   }
---   return smap[severity_name]
--- end
---
--- local severity_field = field.parse_cfield(
---   "severity",
---   { "debug", "Severity level", hook = severity_to_number }
--- )
--- assert.equal(1, severity_field.value)
--- </code>---
---
---
---@class ulf.confkit.FieldSpec : ulf.confkit.cfield_optional @FieldSpec is a table for defining fields in a declarative manner
---@field [1] string: The first list item is either a value or the description.
---@field [2]? string: The second list item is the description if the first list item has a value.
---@field type? string: Optional. Specifies the Lua data type.
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---@field context? {target:any}: Optional. A context for advanced behaviour

---@param s string
---@return string
M.field.normalize = function(s)
	local lines = {}
	for line in gsplit(s, "\n", { plain = true }) do
		table.insert(lines, trim(line))
	end
	return table.concat(lines, "\n")
end

---comment
---@param t ulf.confkit.FieldSpec
---@return boolean
M.field.is_field_spec = function(t)
	if type(t) ~= "table" or getmetatable(t) then
		return false
	end

	local has_description = type(t[#t]) == "string"

	if not has_description then
		return false
	end

	if #t == 1 then
		if t.type == nil then
			return false
		end
	end

	return true
end

--- Parses a cfield table spec and returns an instance of cfield.
---
--- Value is always the first list item. If the key 'value' is
--- present then value is the value of this kv paire. If len is 1 then
--- it is assumed that only a description is given and value can
--- be optional set.
---
--- @param k string The key of the field
--- @param v ulf.confkit.FieldSpec: The value specification
--- @return ulf.confkit.field.FieldOptions
M.field.parse = function(k, v)
	---@type ulf.confkit.field.FieldOptions
	local options = {} ---@diagnostic disable-line: missing-fields
	if not M.field.is_field_spec(v) then
		return { field_type = Constants.FIELD_BEHAVIOUR.NON_FIELD }
	end
	options.field_type = Constants.FIELD_BEHAVIOUR.MANDATORY_FIELD
	options.name = k
	options.context = v.context

	-- Extract value
	---@type any
	options.default = v[1]

	-- P({"!!!!!!!!!!!!!", v_len = #v, v_1 = v[1], v_2 = v[2],})
	if #v == 1 then
		options.default = nil
		options.field_type = Constants.FIELD_BEHAVIOUR.OPTIONAL_FIELD
		options.description = v[1]
	elseif #v == 2 then
		if v[1] == nil then
			options.default = nil
			options.field_type = Constants.FIELD_BEHAVIOUR.OPTIONAL_FIELD
		end
		options.description = v[2]
	end

	if v.fallback then
		options.fallback = v.fallback
		options.field_type = Constants.FIELD_BEHAVIOUR.FALLBACK_FIELD
	end

	-- extract field type.
	options.type = v.type or (options.default ~= nil and type(options.default)) -- Only determine type from default if it's not nil

	options.description = dedent(M.field.normalize(options.description))
	options.hook = v.hook

	return options
end

return M
