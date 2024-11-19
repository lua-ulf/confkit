local M = {}

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
function M.is_ctable(t)
	return _is_type(t, "ctable")
end

---comment
---@param t table
---@return boolean
function M.is_config_block(t)
	return _is_type(t, "ConfigBlock")
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

---@param t table
---@return boolean
function M.is_config_class(t)
	return _is_type(t, "config_class")
end

return M
