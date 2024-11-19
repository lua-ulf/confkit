---@class ulf.confkit.types
local M = {}

---@tag ulf.confkit.types
---@config { ["name"] = "Types" }

--- config { ['field_heading'] = "Options", ['module'] = "ulf.confkit.types" }

---@brief [[
--- Types Module
---
--- Example:
--- <code=lua>
--- </code>
---
---@brief ]]

local make_message = require("ulf.lib.error").make_message
local Validator = require("ulf.confkit.validator")

---@alias ulf.confkit.types.field_attributes table<string,boolean|{[1]:string}> @map of possible field attributes

---@class ulf.confkit.types.FieldTypeOptions @Options for a field registration
---@field attributes? ulf.confkit.types.field_attributes @map of possible field attributes
local FieldTypeOptions = {}

-- Represents a configurable field type in the Confkit library.
--
-- A `FieldType` defines the characteristics, validation rules, and options for a configuration field.
-- It ensures that fields adhere to predefined rules and provides metadata for documentation and processing.
--
-- Creates a new `FieldType` instance.
--
-- Example:
-- <code=lua>
-- local Types = require("ulf.confkit.types")
-- Types.register({
--   "confkit:string",
--   [[This is a simple string field]],
--   {
--     function(name, value, context)
--       local maxlen = context.maxlen
--       local valid = #value <= maxlen
--       return valid, valid or "Error: value must not be longer than " .. tostring(maxlen)
--     end,
--
--     function(name, value)
--       local match = value:match("^CONFKIT:")
--       local valid = match ~= nil
--       return valid, valid or "Error: value must start with 'CONFKIT:'"
--     end,
--   },
-- })
-- </code>
--

---@class ulf.confkit.types.FieldType @Represents a configurable field type in the Confkit library.
---@field id string: A unique identifier for the field type.
---@field description string: A human-readable description of the field type, used for documentation and context.
---@field validators ulf.confkit.validator_fn[]: A list of validator functions that validate values assigned to fields of this type.
---@field attributes? ulf.confkit.types.field_attributes: Optional. Options for validater functions
---@overload fun(id:string, description:string, validators:ulf.confkit.validator_fn[], opts:ulf.confkit.types.FieldTypeOptions?):ulf.confkit.types.FieldType
M.FieldType = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})

---comment
---@param id string: The ID of the field which has the form 'confkit:field_name'
---@param description string: The description of the field
---@param validators ulf.confkit.validator_chain: Chain of validator functions to validate the field value before it is written
---@param opts? ulf.confkit.types.FieldTypeOptions: Options for the field
function M.FieldType.new(id, description, validators, opts)
	opts = opts or {}
	opts.attributes = opts.attributes or {}
	return setmetatable({
		id = id,
		description = description,
		validators = validators,
		attributes = opts.attributes,
	}, {
		__index = M.FieldType,
		__class = { name = "ulf.confkit.FieldType" },
	})
end

---@alias ulf.confkit.types.field_map table<string,ulf.confkit.types.FieldType>

---@class ulf.confkit.types.Registry @Maintains the registered fields
---@field private _fields ulf.confkit.types.field_map: map of field IDs to fields
M.Registry = {
	_fields = {
		["string"] = M.FieldType("string", "basic string type", {
			Validator.ValidatorSet.string,
		}, {
			attributes = {
				maxlen = { "Number" },
				pattern = { "String" },
			},
		}),
		["number"] = M.FieldType("number", "basic number type", {
			Validator.ValidatorSet.number,
		}),
		["boolean"] = M.FieldType("boolean", "basic boolean type", {
			Validator.ValidatorSet.boolean,
		}),
		["table"] = M.FieldType("table", "basic table type", {
			Validator.ValidatorSet.table,
		}),
	},
}

---comment
---@param id string: The ID of the field
---@param description string: The description for the field
---@param validators ulf.confkit.validator_chain: Chain of validator functions to validate the field value before it is written
---@param opts? ulf.confkit.types.FieldTypeOptions: Options for the field
M.register = function(id, description, validators, opts)
	if M.Registry._fields[id] then
		error(
			make_message(
				{ "ulf.confkit.types", "register" },
				"Field type '%s': already registered. got=%s",
				tostring(id)
			)
		)
	end

	M.Registry._fields[id] = M.FieldType(id, description, validators, opts)
end

---comment
---@param id string
---@return boolean
M.is_valid_type = function(id)
	return M.Registry._fields[id] ~= nil
end

---comment
---@param id string
---@return ulf.confkit.types.FieldType
M.get = function(id)
	if M.Registry._fields[id] == nil then
		error(make_message({ "ulf.confkit.types", "validate" }, "Field type '%s': invalid field id", tostring(id)))
	end
	return M.Registry._fields[id]
end

return M
