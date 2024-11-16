---@class ulf.confkit.validator
local M = {}

---@tag ulf.confkit.validator
---@config { ["name"] = "Validator" }

---@brief [[
--- Validator functions
---@brief ]]

local make_message = require("ulf.lib.error").make_message

---@type boolean
local init_done

local f = string.format

--- A validator function validates a value
---@alias ulf.confkit.validator_fn fun(field:ulf.confkit.cfield,context:table<string,any>?):boolean,string?:boolean,string?

--- A validator function chain is a list of validators
---@alias ulf.confkit.validator_chain ulf.confkit.validator_fn[]

M.validation_error = function(name, value, message)
	return f("Field '%s' %s [value=%s]", name, message, value)
end

local got_want = function(got, want)
	return f("want '%s' but got '%s'", want, got)
end

---comment
---@param wanted_type any
---@return ulf.confkit.validator_fn
M.type_validator = function(wanted_type)
	return function(field)
		local got_type = type(field.value)
		local match_type = got_type == wanted_type
		return match_type,
			not match_type and M.validation_error(
				field.name,
				field.value,
				"type error, " .. got_want(got_type, wanted_type)
			) or nil
	end
end

M.string_validator = function(name, value, context) end

return M
