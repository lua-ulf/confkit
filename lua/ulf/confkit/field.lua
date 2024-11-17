---@class ulf.confkit.field
local M = {}

local f = string.format
local Validator = require("ulf.confkit.validator")
local types = require("ulf.confkit.types")
local make_message = require("ulf.lib.error").make_message

local Constants = require("ulf.confkit.constants")
local NIL = Constants.NIL

---@alias ulf.confkit.hook_fn fun(v:any):any

---@class ulf.confkit.field.FieldOptions @FieldOptions are options which are passed to the constructor to set initial values
---@field name string: The name of the field.
---@field default any: The default value of the field.
---@field value any: The value of the field.
---@field field_type ulf.confkit.field_behaviour_type: The ID of the configuration field type.
---@field type string: The Lua data type
---@field description string: The description of the field
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---@field context? {target:any}: Optional. A context for advanced behaviour

---@class ulf.confkit.cfield_optional
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.

---@class ulf.confkit.field.Field : ulf.confkit.cfield_optional
---@field name string: The name of the field.
---@field default any: The default value of the field.
---@field value any: The value of the field.
---@field _value any: The real value writen to the table
---@field field_type ulf.confkit.field_behaviour_type: The ID of the configuration field type.
---@field type string: The Lua data type
---@field description string: The description of the field
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---@field context? {target:any}: Optional. A context for advanced behaviour
---@field validate fun(self:ulf.confkit.field.Field):boolean,string?: Validates a field, returns true for success or false,errors in case of error
---@overload fun(self:ulf.confkit.field.Field):ulf.confkit.field.Field
local Field = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.Field = Field

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

		--- TODO: validate context
		-- context = {
		-- }

		--- FIXME: rule does not work
		-- value = {
		-- 	valid = (field.value ~= nil and field.default ~= nil and type(field.value) == type(field.default)) or true,
		-- 	message = "field default and field value must have the same type",
		-- },
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

	-- P({
	-- 	"validate_base",
	-- 	errors = errors,
	-- })
	return valid,
		not valid and Validator.validation_error(field.name, field.value, "errors: " .. table.concat(errors, "\n"))
			or nil
end

---comment
---@param field ulf.confkit.field.Field
function M.validate(field)
	P("incoming FIED?????????????", field)
	---@type boolean
	local ok
	---@type string[]
	local errors = {}
	---@type string
	local err

	ok, err = M.validate_base(field)
	if not ok then
		error(err)
	end

	local valid = true

	local field_type = types.get(field.type)

	for _, field_validator in pairs(field_type.validators) do
		ok, err = field_validator(field)
		valid = ok and valid
		if not ok then
			errors[#errors + 1] = err
		end
	end

	if not valid then
		error(table.concat(errors, "\n"))
	end
end

---@type table<string,fun(t:ulf.confkit.field.Field):any>
Field.accessors = {

	value = function(t)
		---@type any
		local v
		if t._value == NIL then
			v = t.default
		else
			v = t._value
		end

		if t.hook then
			return t.hook(v)
		end

		return v
	end,
}
--- The function is run before validation and ensures that sane defaults
--- are set.
---@param spec ulf.confkit.field.Field
---@return ulf.confkit.field.Field
Field.apply_defaults = function(spec)
	local type_from = spec.value ~= NIL and spec.value or spec.default
	if spec.type == nil and type_from ~= nil then
		spec.type = type(type_from)
	end
	-- if spec.value == nil then
	-- 	spec._value = NIL
	-- end
	return spec
end

---@param opts? ulf.confkit.field.Field
---@return ulf.confkit.field.Field
function Field.new(opts)
	assert(
		type(opts) == "table",
		make_message(
			{ "ulf.confkit.field", "Field" },
			"opts must be a table with {optional,value,type,description}. got=%s",
			tostring(opts)
		)
	)

	opts = Field.apply_defaults(opts)
	M.validate(opts)

	---@type table<string,fun(t:ulf.confkit.field.Field,v:any):any>
	local writers = {

		value = function(t, v)
			v = v or NIL
			t._value = v
		end,
	}

	local obj = {
		name = opts.name,
		description = opts.description,
		type = opts.type,
		fallback = opts.fallback,
		default = opts.default,
		_value = opts.value or NIL,
		hook = opts.hook,
		field_type = opts.field_type,
		context = opts.context,
	}

	local self = setmetatable(obj, {
		---comment
		---@param t ulf.confkit.field.Field
		---@param k string
		---@return any
		__index = function(t, k)
			print(f(">>>>>>>>>>> __index: k=%s", k))
			local accessor = Field.accessors[k]
			if type(accessor) == "function" then
				return accessor(t)
			end
		end,

		---@param t ulf.confkit.field.Field
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
		__class = { name = "ulf.confkit.Field" },
	})

	return self
end

return M
