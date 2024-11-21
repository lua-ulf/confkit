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
local Lib = require("ulf.confkit.lib")
local dedent = Lib.dedent
local trim = Lib.trim
local gsplit = Lib.gsplit

local f = string.format
local log = require("ulf.confkit.logger")

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
---@class ulf.confkit.FieldSpec @FieldSpec is a table for defining fields in a declarative manner
---@field [1] string: The first list item is either a value or the description.
---@field [2]? string: The second list item is the description if the first list item has a value.
---@field type? string: Optional. Specifies the Lua data type.
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---@field context? {target:any}: Optional. A context for advanced behaviour
---@field value? any: The value of the field.

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
		if t.type == nil and t.value == nil then
			return false
		end
	end

	return true
end

--- The function is run before validation and ensures that sane defaults
--- are set.
---@param options ulf.confkit.field.FieldOptions
---@return ulf.confkit.field.FieldOptions
M.field.apply_defaults = function(options)
	local type_from = options.value ~= nil and options.value or options.default ~= nil and options.default
	if options.type == nil and type_from ~= nil then
		options.type = type(type_from)
	end
	return options
end

--- The function is run before validation and ensures that sane defaults
--- are set.
---@param options ulf.confkit.field.FieldOptions
---@param spec ulf.confkit.FieldSpec
---@return ulf.confkit.field.FieldOptions
M.field.parse_attributes = function(options, spec)
	assert(options.type)

	options.attributes = {}
	local field_type = require("ulf.confkit.types").get(options.type)
	if field_type then
		for key, value in
			pairs(spec --[[@as table<string,any>]])
		do
			if field_type.attributes[key] then
				options.attributes[key] = value
			end
		end
	end

	return options
end

--- Parses a cfield table spec and returns an instance of cfield.
---
--- Value is always the first list item. If the key 'value' is
--- present then value is the value of this kv paire. If len is 1 then
--- it is assumed that only a description is given and value can
--- be optional set.
---
--- @param name string The key of the field
--- @param spec ulf.confkit.FieldSpec: The value specification
--- @return ulf.confkit.field.FieldOptions?
M.field.parse = function(name, spec)
	---@type ulf.confkit.field.FieldOptions
	local options = {} ---@diagnostic disable-line: missing-fields
	if not M.field.is_field_spec(spec) then
		log.debug(f("spec.field.parse: key='%s' is not a key spec, spec=", name), spec)
		return
	end

	-- log.debug(f( "spec.field.parse: called, name=%s #spec=%s, spec[1]=%s ", name, #spec, (type(spec) == "table" and #spec > 0 and spec[1]) or "" ))

	options.behaviour = Constants.FIELD_BEHAVIOUR.DEFAULT
	options.name = name
	options.context = spec.context
	options.value = spec.value
	options.hook = spec.hook
	options.type = spec.type

	-- Extract value
	---@type any
	options.default = spec[1]

	local msg = ""
	if #spec == 1 then
		msg = "#spec==1"
		options.default = nil
		options.behaviour = Constants.FIELD_BEHAVIOUR.OPTIONAL
		options.description = spec[1]
	elseif #spec == 2 then
		msg = "#spec==2"
		if spec[1] == nil then
			msg = "#spec==2 spec[1]==nil"
			options.default = nil
			options.behaviour = Constants.FIELD_BEHAVIOUR.OPTIONAL
		end
		options.description = spec[2]
	end
	options = M.field.apply_defaults(options)
	options = M.field.parse_attributes(options, spec)

	log.debug(
		f(
			"spec.field.parse: name='%s' result> %s description='%s' behaviour=%s default=%s value=%s type='%s' hook=%s",
			options.name,
			msg,
			options.description,
			options.behaviour,
			options.default,
			options.value,
			options.type,
			options.hook
		)
	)
	-- if spec.fallback then
	-- 	options.fallback = spec.fallback
	-- 	options.behaviour = Constants.FIELD_BEHAVIOUR.FALLBACK
	-- end

	options.description = dedent(M.field.normalize(options.description))

	return options
end

return M
