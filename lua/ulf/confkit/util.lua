local M = {}

---@tag ulf.confkit.util
---@config { ["module"] = "ulf.confkit.util" }

---@brief [[
--- Utilities for `ConfKit`
---@brief ]]

local ulf = {
	lib = require("ulf.lib"),
}

local split = ulf.lib.string.split
local deepcopy = ulf.lib.table.deepcopy
local tbl_isempty = ulf.lib.table.tbl_isempty
local tbl_get = ulf.lib.table.tbl_get

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

---Returns true of `obj` is a `Field`.
---@param obj table
---@return boolean
function M.is_field(obj)
	return _is_type(obj, "ulf.confkit.Field")
end

---Returns true of `obj` is a `FieldType`.
---@param obj table
---@return boolean
function M.is_field_type(obj)
	return _is_type(obj, "ulf.confkit.FieldType")
end

---Returns true of `obj` is a `Schema`.
---@param obj table
---@return boolean
function M.is_schema(obj)
	return _is_type(obj, "ulf.confkit.Schema")
end

return M
