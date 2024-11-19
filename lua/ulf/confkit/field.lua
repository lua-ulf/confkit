local f = string.format
local Validator = require("ulf.confkit.validator")
local types = require("ulf.confkit.types")
local make_message = require("ulf.lib.error").make_message

local log = require("ulf.confkit.logger")
local Constants = require("ulf.confkit.constants")

---@class ulf.confkit.field.context
---@field target table: The target table for fetching a fallback value

---@alias ulf.confkit.field.attributes table<string,any>
---@alias ulf.confkit.hook_fn fun(v:any):any

---@class ulf.confkit.field.FieldBase @FieldBase are basic attributes for options and an instance
---@field name string: The name of the field.
---@field default? any: The default value of the field.
---@field value? any: The value of the field.
---@field behaviour? number: The ID of the configuration field type.
---@field type? string: The Lua data type
---@field description string: The description of the field
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field attributes? ulf.confkit.field.attributes: Optional. Options for validater functions
---@field context? ulf.confkit.field.context: Optional. A context for advanced behaviour
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.

---@class ulf.confkit.field.FieldOptions : ulf.confkit.field.FieldBase @FieldOptions are options which are passed to the constructor to set initial values

---@class ulf.confkit.field.Field : ulf.confkit.field.FieldBase
---@field name string: The name of the field.
---@field default any: The default value of the field.
---@field fallback? string: Optional. Specifies a fallback path as a string, pointing to a node in the fallback context table. The fallback node’s value is used if the current field has no explicitly set value.
---@field value any: The value of the field.
---@field _default any: The real default value
---@field _value any: The real value writen to the table
---@field behaviour number: The ID of the configuration field type.
---@field type string: The Lua data type
---@field description string: The description of the field
---@field hook? ulf.confkit.hook_fn: A hook function takes the original value and returns a "replacement" value
---@field context? ulf.confkit.field.context: Optional. A context for advanced behaviour
---@field attributes? ulf.confkit.field.attributes: Optional. Options for validater functions
---@overload fun(self:ulf.confkit.field.FieldOptions):ulf.confkit.field.Field
local Field = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
Field.__index = Field

Field.FIELD_BEHAVIOUR = Constants.FIELD_BEHAVIOUR

Field.NIL = Constants.NIL

--- Instance method to check if a specific flag is set in the instance's behaviour
---@param field ulf.confkit.field.FieldBase
---@param flag number
---@return boolean True if the flag is set, false otherwise
Field.has_flag = function(field, flag)
	return field.behaviour % (flag + flag) >= flag
end

---@param field ulf.confkit.field.FieldBase
---@param flag number
Field.set_flag = function(field, flag)
	return Field.has_flag(field, flag) and field.behaviour or field.behaviour + flag
end

---@type ulf.confkit.validator_fn
Field.validate_base = function(field)
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
		context = {
			valid = field.context == nil or (type(field.context) == "table" and type(field.context.target) == "table"),
			message = "field context.target must be a table",
		},
	}

	local valid = true

	---@type string[]
	local errors = {}

	for _, check_spec in pairs(checks) do
		valid = check_spec.valid and valid
		if not check_spec.valid then
			errors[#errors + 1] = check_spec.message
		end
	end

	return valid,
		not valid and Validator.validation_error(field.name, field.value, "errors: " .. table.concat(errors, "\n"))
			or nil
end

---comment
---@param field ulf.confkit.field.FieldOptions
---@param opts? {base:boolean?,value:boolean?}
function Field.validate(field, opts)
	log.debug(f("field.validate: name=%s", field.name), opts)
	opts = opts or {}

	local want_base_validation = type(opts.base) == "boolean" and opts.base or false
	local want_value_validation = type(opts.value) == "boolean" and opts.value or false

	---@type boolean
	local ok
	---@type string[]
	local errors = {}
	---@type string
	local err
	local valid = true

	local _base_validation = function()
		ok, err = Field.validate_base(field)
		if not ok then
			error(err)
		end
	end

	local _value_validation = function()
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

	if want_base_validation then
		_base_validation()
	end
	if want_value_validation then
		_value_validation()
	end
end

---@type table<string,fun(t:ulf.confkit.field.Field):any>
Field.accessors = {

	default = function(t)
		log.debug(
			f("Field.accessors.default: name=%s _default=%s behaviour=%s", t.name, t._default, t.behaviour),
			t.context
		)
		if Field.has_flag(t, Field.FIELD_BEHAVIOUR.FALLBACK) then
			log.debug(f("Field.accessors.default: FALLBACK flag set context.target.value=%s", t.context.target.value))
			return t.context.target.value
		end
		return t._default
	end,

	value = function(t)
		log.debug(
			f(
				"Field.accessors.value: name=%s _default=%s default=%s _value=%s",
				t.name,
				t._default,
				t.default,
				t._value
			)
		)

		---@type any
		local v

		local msg = ""

		if t._value == Field.NIL then
			v = t.default
			msg = "t._value is NIL, using t.default as return value"
		else
			v = t._value
			msg = "using t._value as return value"
		end

		if t.hook then
			-- if a fallback is configured and _value is NIL then do bit apply
			-- the hook again!
			if not (Field.has_flag(t, Field.FIELD_BEHAVIOUR.FALLBACK) and t._value == Field.NIL) then
				msg = msg .. " applying HOOK"
				v = t.hook(v)
			end
		end

		log.debug(f("Field.accessors.value: %s> FINAL value=%s", msg, v))
		return v
	end,
}
--- The function is run before validation and ensures that sane defaults
--- are set.
---@param spec ulf.confkit.field.FieldOptions
---@return ulf.confkit.field.FieldOptions
Field.apply_defaults = function(spec)
	if type(spec.behaviour) ~= "number" then
		spec.behaviour = 0
	end

	local type_from = spec.value ~= Field.NIL and spec.value or spec.default
	if spec.type == nil and type_from ~= nil then
		spec.type = type(type_from)
	end
	if spec.value == nil and spec.default == nil then
		spec.behaviour = Field.set_flag(spec, Field.FIELD_BEHAVIOUR.OPTIONAL)
	end
	-- if spec.value == nil then
	-- 	spec._value = Field.NIL
	-- end
	return spec
end

---@param opts? ulf.confkit.field.FieldOptions
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
	Field.validate(opts, { base = true })

	---@type table<string,fun(t:ulf.confkit.field.Field,v:any):any>
	local writers = {

		value = function(t, v)
			v = v == nil and Field.NIL or v
			log.debug(f("Field.writer: name=%s> value=%s", t.name, v))
			t._value = v
		end,
	}

	local obj = {
		name = opts.name,
		description = opts.description,
		type = opts.type,
		fallback = opts.fallback,
		hook = opts.hook,
		attributes = opts.attributes,
		context = opts.context,
		behaviour = type(opts.behaviour) == "number" and opts.behaviour or 0,
		_default = opts.default,
		_value = opts.value ~= nil and opts.value or Field.NIL,
	}

	local self = setmetatable(obj, {
		---comment
		---@param t ulf.confkit.field.Field
		---@param k string
		---@return any
		__index = function(t, k)
			log.debug(f("Field.__index: k=%s", k))
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

	Field.validate(self, { value = true })
	return self
end

---@param name string
---@param spec ulf.confkit.FieldSpec
---@return ulf.confkit.field.Field
function Field.parse(name, spec)
	return Field(require("ulf.confkit.spec").field.parse(name, spec))
end

return Field
