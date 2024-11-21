local M = {}

---@tag ulf.confkit.util
---@config { ["module"] = "ulf.confkit.util" }

---@brief [[
--- Utilities for `ConfKit`
---@brief ]]

---comment
---@param t table
---@param name string
---@return boolean
local function _is_type(t, name)
	local mt = getmetatable(t)
	if mt and mt.__class then
		return mt.__class.name and mt.__class.name == name
	end
	return false
end

---comment
---@param t table
---@return boolean
function M.is_field(t)
	return _is_type(t, "ulf.confkit.Field")
end

---comment
---@param t table
---@return boolean
function M.is_field_type(t)
	return _is_type(t, "ulf.confkit.FieldType")
end

---@param t table
---@return boolean
function M.is_schema(t)
	return _is_type(t, "ulf.confkit.Schema")
end

return M
