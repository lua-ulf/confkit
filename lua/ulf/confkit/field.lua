---@brief [[
--- `ulf.confkit.field` is responsible for defining and managing configuration fields within the `ulf.confkit` module.
---
--- This module encapsulates individual configuration fields, ensuring each field is associated with its data type, optional
--- default values, descriptions, validation hooks, and fallbacks. By centralizing field responsibilities, this module
--- facilitates managing defaults, field validation, transformations, and access logic, enabling concise control of each
--- field's behavior.
---
---
--- Usage instructions:
---   1. Define each configuration field using `ulf.confkit.field.cfield`.
---   2. Use hooks and fallback configurations to customize field behaviors.
---   3. Access validated and transformed field values through ConfigBlocks that leverage these field definitions.
---
--- Below is an overview of the `ulf.confkit.field` module:
--- <pre>
--- ┌─────────────────────────────────────────────────────────┐
--- │ ┌──────────┐                                            │
--- │ │ Config   │      ┌────────────┐    ┌──────────┐        │
--- │ │ Block    │──▶   │ Field      │───▶│ Schema   │        │
--- │ │          │      │ Definitions│    │ Functions│        │
--- │ └──┬───────┘      └────────────┘    └──────────┘        │
--- │    │ Hooks +      ┌────────────┐     ▲                  │
--- │    │ Fallbacks    │ Validation │     └───────────┐      │
--- │    │ Applied      └──────▲─────┘                 │      │
--- │    ▼                     │                       │      │
--- │ ┌────────────────────┐   │       ┌────────────┐  │      │
--- │ │Default + Custom    │   │       │Field Access│◀─┘      │
--- │ │Fields, Descriptions│           │Utilities   │         │
--- │ └────────────────────┘           └────────────┘         │
--- │              ulf.confkit.field module                  │
--- └─────────────────────────────────────────────────────────┘
---
--- Main components of `ulf.confkit.field`:
---   1 `cfield`: Defines individual fields within configuration tables, specifying types, defaults, descriptions, and hooks.
---   2 `validate`: Ensures each field conforms to the defined data type, hooks, and validation requirements.
---   3 `is_cfield_spec`: Helper function that checks if a table follows the `cfield` specification format.
---   4 `parse_cfield`: Parses and returns a configured `cfield` instance for easy field management.
--- </pre>
---
--- Additional resources for `ulf.confkit.field`:
--- <pre>
--- https://github.com/ulf-project/ulf.lib
---
---   :h ulf.confkit.field
---   :h ulf.confkit.ctable
---   :h ulf.confkit.ConfigBlock
---   :h ulf.confkit.schema
---   :h ulf.confkit.util
--- </pre>
---
--- Example:

--- Examples:
--- These examples start simple and introduce more features progressively.
---
--- Basic Field Definition:
--- <code=lua>
--- local field = require("ulf.confkit.field")
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
---@brief ]]

---@class ulf.confkit.field
local M = {}

local trim = require("ulf.lib.string.trimmer").trim
local gsplit = require("ulf.lib.string.splitter").gsplit
local dedent = require("ulf.lib.string.dedent").dedent

local f = string.format
local Validator = require("ulf.confkit.validator")
local types = require("ulf.confkit.types")
local make_message = require("ulf.lib.error").make_message

---@alias ulf.confkit.cfield_kind_type
---| 1 # Mandatory config field
---| 2 # Optional config field
---| 3 # Fallback config field
---| 10 # Non config field

---@alias ulf.confkit.hook_fn fun(v:any):any

---@class ulf.confkit.cfield_optional
---@field hook? ulf.confkit.hook_fn @A hook function takes the original value and returns a "replacement" value
---@field fallback? string @Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---
---@class ulf.confkit.FieldSpec : ulf.confkit.cfield_optional
---@field [1] string @The first list item is either a value or the description.
---@field [2]? string @The second list item is the description if the first list item has a value.
---@field type? string @Optional. Specifies the Lua data type.

--

---@class ulf.confkit.cfield : ulf.confkit.cfield_optional
---@field name string @The name of the field.
---@field default any @The default value of the field.
---@field value any @The value of the field.
---@field _value any @The real value writen to the table
---@field field_type ulf.confkit.cfield_kind_type @The ID of the configuration field type.
---@field type string @The Lua data type
---@field description string @The description of the field

--- BEHAVIOUR!
---@class ulf.confkit.cfield_kind
M.kinds = {
	MANDATORY_FIELD = 1,
	OPTIONAL_FIELD = 2,
	FALLBACK_FIELD = 3,
	NON_FIELD = 10,
}

--- DATA FORMAT
M.valid_types = {

	["string"] = true,
	["number"] = true,
	["function"] = true,
	["boolean"] = true,
	["table"] = true,
}

---@type ulf.confkit.validator_fn
M.validate_base = function(field)
	local checks = {
		name = {
			valid = type(field.name) == "string",
			message = "field name must be a string",
		},
		description = {
			valid = type(field.description) == "string",
			message = "field description must be a string",
		},
		type = {
			valid = types.is_valid_type(field.type),
			message = "field type '" .. tostring(field.type) .. "' is invalid",
		},

		hook = {
			valid = field.hook == nil or (type(field.hook) == "function"),
			message = "field hook must be a function",
		},

		fallback = {
			valid = field.fallback == nil or (type(field.fallback) == "string"),
			message = "field fallback must be a string",
		},
	}
	local valid = true
	---@type string[]
	local errors = {}

	for check_name, check_spec in pairs(checks) do
		valid = check_spec.valid and valid
		if not check_spec.valid then
			errors[#errors + 1] = check_spec.message
		end
	end

	return valid,
		not valid and Validator.validation_error(field.name, field.value, "errors: " .. table.concat(errors, "\n"))
			or nil
end

---@param field ulf.confkit.cfield
M.validate = function(field)
	if type(field.name) ~= "string" then
		error(make_message({ "ulf.confkit.field", "validate" }, "Field must have a name. got=%s", tostring(field.name)))
	end

	if type(field.description) ~= "string" then
		error(

			make_message(
				{ "ulf.confkit.field", "validate" },
				"Field '%s': 'description' must be a string. got=%s",
				field.name,
				tostring(field.description)
			)
		)
	end
	if type(field.field_type) ~= "number" then
		error(

			make_message(
				{ "ulf.confkit.field", "validate" },
				"Field '%s': 'field_type' must be a field field_type ID. got=%s",
				field.name,
				tostring(field.field_type)
			)
		)
	end

	if not M.valid_types[field.type] then
		error(
			make_message(
				{ "ulf.confkit.field", "validate" },
				"Field '%s': 'type' can have the value: boolean, string, number, function or table. got=%s",
				field.name,
				field.type
			)
		)
	end

	if field.default == nil and not field.type then
		error(
			make_message(
				{ "ulf.confkit.field", "validate" },
				"Field '%s': type of field must be set if field has no value",
				field.name
			)
		)
	end

	if field.hook and type(field.hook) ~= "function" then
		error(
			make_message(
				{ "ulf.confkit.field", "parse_cfield" },
				"Field '%s': 'hook' must be a function. got=%s",
				field.name,
				type(field.hook)
			)
		)
	end

	if field.fallback then
		if type(field.fallback) ~= "function" and type(field.fallback) ~= "string" then
			error(
				make_message(
					{ "ulf.confkit.field", "parse_cfield" },
					"Field '%s': 'fallback' must be a string or function. got=%s",
					field.name,
					type(field.fallback)
				)
			)
		end
	end
end

--- Returns a config field
---@param opts? ulf.confkit.cfield
---@return ulf.confkit.cfield
M.cfield = function(opts)
	assert(
		type(opts) == "table",
		make_message(
			{ "ulf.confkit.field", "cfield" },
			"opts must be a table with {optional,value,type,description}. got=%s",
			tostring(opts)
		)
	)

	local ok, err = M.validate_base(opts)
	if not ok then
		error(err)
	end

	---@type table<string,fun(t:table):any>
	local accessors = {

		value = function(t)
			P(t)
			---@type any
			local source = t._value or t.default
			if t.hook then
				return t.hook(source)
			end

			return source
		end,
	}

	---@type table<string,fun(t:table,v:any):any>
	local writers = {

		value = function(t, v)
			t._value = v
		end,
	}

	return setmetatable({
		name = opts.name,
		description = opts.description,
		type = opts.type,
		fallback = opts.fallback,
		default = opts.default,
		_value = opts.value,
		hook = opts.hook,
		field_type = opts.field_type,
	}, {
		---comment
		---@param t ulf.confkit.field
		---@param k string
		---@return any
		__index = function(t, k)
			local accessor = accessors[k]
			if type(accessor) == "function" then
				return accessor(t, k)
			end
		end,
		---@param t ulf.confkit.field
		---@param k string
		---@param v any
		__newindex = function(t, k, v)
			-- P("__newindex", k, v)
			local writer = writers[k]
			if writer then
				writer(t, v)
			else
				rawset(t, k, v)
			end
		end,
		__class = { name = "cfield" },
	})
end

---@param s string
---@return string
local normalize = function(s)
	local lines = {}
	for line in gsplit(s, "\n", { plain = true }) do
		table.insert(lines, trim(line))
	end
	return table.concat(lines, "\n")
end

---comment
---@param t ulf.confkit.FieldSpec
---@return boolean
function M.is_cfield_spec(t)
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
--- @param v ulf.confkit.FieldSpec The value specification
--- @return ulf.confkit.cfield
function M.parse_cfield(k, v)
	---@type ulf.confkit.cfield
	local field_spec = {} ---@diagnostic disable-line: missing-fields
	if not M.is_cfield_spec(v) then
		return { field_type = M.kinds.NON_FIELD }
	end
	field_spec.field_type = M.kinds.MANDATORY_FIELD
	field_spec.name = k

	-- Extract value
	---@type any
	field_spec.default = v[1]

	-- P({"!!!!!!!!!!!!!", v_len = #v, v_1 = v[1], v_2 = v[2],})
	if #v == 1 then
		field_spec.default = nil
		field_spec.field_type = M.kinds.OPTIONAL_FIELD
		field_spec.description = v[1]
	elseif #v == 2 then
		if v[1] == nil then
			field_spec.default = nil
			field_spec.field_type = M.kinds.OPTIONAL_FIELD
		end
		field_spec.description = v[2]
	end

	if v.fallback then
		field_spec.fallback = v.fallback
		field_spec.field_type = M.kinds.FALLBACK_FIELD
	end

	-- extract field type.
	field_spec.type = v.type or (field_spec.default ~= nil and type(field_spec.default)) -- Only determine type from default if it's not nil

	field_spec.description = dedent(normalize(field_spec.description))
	field_spec.hook = v.hook

	return M.cfield(field_spec)
end

return M
