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

local make_message = require("ulf.lib.error").make_message

---@alias ulf.confkit.cfield_kind_type
---| 1 # Mandatory config field
---| 2 # Optional config field
---| 3 # Fallback config field
---| 10 # Non config field

---@class ulf.confkit.cfield_base
---@field name string
---@field value? any
---@field hook? ulf.confkit.hook_spec_fn
---@field fallback? string
---@field kind ulf.confkit.cfield_kind_type
---@field type string
---@field description string

---@class ulf.confkit.cfield : ulf.confkit.cfield_base

---@class ulf.confkit.cfield_kind
M.kinds = {
	MANDATORY_FIELD = 1,
	OPTIONAL_FIELD = 2,
	FALLBACK_FIELD = 3,
	NON_FIELD = 10,
}

M.valid_types = {

	["string"] = true,
	["number"] = true,
	["function"] = true,
	["boolean"] = true,
	["table"] = true,
}
---@param field ulf.confkit.cfield_base
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
	if type(field.kind) ~= "number" then
		error(

			make_message(
				{ "ulf.confkit.field", "validate" },
				"Field '%s': 'kind' must be a field kind ID. got=%s",
				field.name,
				tostring(field.kind)
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

	if field.value == nil and not field.type then
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
---@param opts? ulf.confkit.cfield_base|string
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

	P({
		"cfield.................",
		opts,
	})
	M.validate(opts)

	---@type table<string,fun(t:table,k:string):any>
	local accessors = {

		value = function(t, k)
			if opts.hook then
				return opts.hook(opts.value)
			end

			return opts.value
		end,
	}

	return setmetatable({
		name = opts.name,
		description = opts.description,
		type = opts.type,
		fallback = opts.fallback,
		-- value = opts.value,
		hook = opts.hook,
		kind = opts.kind,
	}, {
		__index = function(t, k)
			local accessor = accessors[k]
			if type(accessor) == "function" then
				return accessor(t, k)
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
---@param t table
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
--- @param v table The value specification
--- @return ulf.confkit.cfield
function M.parse_cfield(k, v)
	---@type ulf.confkit.cfield
	local field_spec = {}
	if not M.is_cfield_spec(v) then
		return { kind = M.kinds.NON_FIELD }
	end
	P("M.parse_cfield")
	-- P({
	-- 	"M.parse_cfield............................",
	-- 	k = k,
	-- 	v = v,
	-- 	len_v = #v,
	-- 	v_1 = v[1],
	-- 	v_2 = v[2],
	-- })
	field_spec.kind = M.kinds.MANDATORY_FIELD
	field_spec.name = k

	-- Extract value
	---@type any
	field_spec.value = v[1]

	P({
		"!!!!!!!!!!!!!",
		v_len = #v,
		v_1 = v[1],
		v_2 = v[2],
	})
	-- FIXME: why #v==2 ?
	-- only a description present so an OPTIONAL_FIELD
	if #v == 1 then
		field_spec.value = nil
		field_spec.kind = M.kinds.OPTIONAL_FIELD
		field_spec.description = v[1]
	elseif #v == 2 then
		if v[1] == nil then
			field_spec.value = nil
			field_spec.kind = M.kinds.OPTIONAL_FIELD
		end
		field_spec.description = v[2]
	end

	if v.fallback then
		field_spec.fallback = v.fallback
		field_spec.kind = M.kinds.FALLBACK_FIELD
	end

	-- extract field type.
	field_spec.type = v.type or (field_spec.value ~= nil and type(field_spec.value)) -- Only determine type from value if it's not nil

	field_spec.description = dedent(normalize(field_spec.description))
	field_spec.hook = v.hook

	P(field_spec)
	return M.cfield(field_spec)
end

return M
