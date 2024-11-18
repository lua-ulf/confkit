---@class ulf.confkit.validator
local M = {}

---@tag ulf.confkit.validator
---@config { ["name"] = "Validator" }

---@brief [[
--- Validator functions
---@brief ]]

local f = string.format

--- A validator function validates a value
---@alias ulf.confkit.validator_fn fun(field:ulf.confkit.field.Field|ulf.confkit.field.FieldOptions,context:table<string,any>?):boolean,string?:boolean,string?

--- A validator function chain is a list of validators
---@alias ulf.confkit.validator_chain ulf.confkit.validator_fn[]

---@alias ulf.confkit.validator.validator_set table<string,ulf.confkit.validator_fn>

---@class ulf.confkit.validator.Rule
---@field name string
---@field valid boolean|ulf.confkit.validator_fn
---@field index? number

M.validation_error = function(name, value, message)
	return f("Field '%s' %s [value=%s]", name, message, value)
end

local got_want = function(got, want)
	return f("want '%s' but got '%s'", want, got)
end

M.Util = {}

---@param rules ulf.confkit.validator.Rule[]
---@return ulf.confkit.validator_fn
M.Util.create_validator = function(rules)
	return function(field, context)
		local valid = true
		---@type string[]
		local errors = {}

		for _, rule in ipairs(rules) do
			local is_valid = rule.valid
			if type(is_valid) == "function" then
				local ok, err = is_valid(field, context)
				valid = ok and valid
				if not ok then
					errors[#errors + 1] = err
				end
				P("M.Util.create_validator: function(...) validator result", rule.name, ok, err)
			else
				P("M.Util.create_validator: MISSING VALIDATOR")
			end
		end

		return valid,
			not valid and M.validation_error(field.name, field.value, "errors: " .. table.concat(errors, "\n")) or nil
	end
end

---comment
---@param wanted_type any
---@return ulf.confkit.validator_fn
M.Util.type_validator = function(wanted_type)
	return function(field)
		if field.value == nil then
			return true
		end
		local got_type = type(field.value)
		local match_type = got_type == wanted_type
		return match_type, not match_type and "type error, " .. got_want(got_type, wanted_type) or nil
	end
end

M.CheckFuncs = {}
---@type ulf.confkit.validator.validator_set
M.CheckFuncs.base = {}

---@type ulf.confkit.validator.validator_set
M.CheckFuncs.boolean = {}
M.CheckFuncs.boolean.is_boolean = M.Util.type_validator("boolean")

---@type ulf.confkit.validator.validator_set
M.CheckFuncs.table = {}
M.CheckFuncs.table.is_table = M.Util.type_validator("table")

---@type ulf.confkit.validator.validator_set
M.CheckFuncs.number = {}
M.CheckFuncs.number.is_number = M.Util.type_validator("number")

---@type ulf.confkit.validator.validator_set
M.CheckFuncs.string = {}
M.CheckFuncs.string.is_string = M.Util.type_validator("string")

---comment
---@param field ulf.confkit.field.Field
---@param context table<string,any>
M.CheckFuncs.string.matches = function(field, context)
	context = context or {}
	local attributes = field.attributes or {}

	local valid = true

	if type(attributes.pattern) == "string" and field.value ~= nil then
		local result = string.match(field.value, attributes.pattern)
		valid = result and true or false
	end

	return valid, not valid and f("string must match pattern '%s'", attributes.pattern) or nil
end

---comment
---@param field ulf.confkit.field.Field
---@param context table<string,any>
M.CheckFuncs.string.lt = function(field, context)
	context = context or {}
	local attributes = field.attributes or {}

	local valid = true

	if attributes.maxlen and field.value ~= nil then
		valid = #field.value <= attributes.maxlen
	end

	return valid, not valid and f("string length must be lower than %s", attributes.maxlen) or nil
end

M.ValidatorSet = {
	boolean = M.Util.create_validator({
		{ name = "is_boolean", valid = M.CheckFuncs.boolean.is_boolean },
	}),
	number = M.Util.create_validator({
		{ name = "is_number", valid = M.CheckFuncs.number.is_number },
	}),
	table = M.Util.create_validator({
		{ name = "is_table", valid = M.CheckFuncs.table.is_table },
	}),
	string = M.Util.create_validator({
		{ name = "is_string", valid = M.CheckFuncs.string.is_string },
		{ name = "maxlen", valid = M.CheckFuncs.string.lt },
		{ name = "pattern", valid = M.CheckFuncs.string.matches },
	}),
}

return M
