---@class ulf.confkit.traversal
local M = {}

local split = require("ulf.lib.string.splitter").split
local deepcopy = require("ulf.lib.table").deepcopy
local tbl_isempty = require("ulf.lib.table").tbl_isempty
local tbl_get = require("ulf.lib.table").tbl_get
local Field = require("ulf.confkit.field")
local log = require("ulf.confkit.logger")

local Spec = require("ulf.confkit.spec")
local Util = require("ulf.confkit.util")
local is_schema = Util.is_schema
local is_field = Util.is_field

local f = string.format
local unpack = table.unpack or unpack
-- local make_message = require("ulf.lib.error").make_message

---@alias ulf.confkit.traversal.visitor fun(node_path:ulf.confkit.traversal.node_path,field:ulf.confkit.field.Field)

---comment
---@param parent string[]
---@param key string
---@return string[]
local new_childs = function(parent, key)
	local child_nodes = { unpack(parent) }
	table.insert(child_nodes, key)
	return child_nodes
end

---comment
---@param parent string
---@param node_name string
M.node_path = function(parent, node_name)
	---@type ulf.confkit.traversal.node_path
	return setmetatable({
		parent = parent,
		node_name = node_name,
	}, {
		__tostring = function(t)
			return t.parent == "" and t.node_name or t.parent .. "." .. t.node_name
		end,
	})
end

M.walk = {}
---@param node ulf.confkit.schema.Schema
---@param parent string[]
---@param fn ulf.confkit.traversal.visitor
M.walk.post_order = function(node, parent, fn)
	local parent_path = table.concat(parent, ".")
	-- Traverse child nodes first
	-- for _, node_path, child in node:fields(nil, parent_path) do
	for node_name, child in pairs(node._values) do
		if is_schema(child) then
			---@cast child ulf.confkit.schema.Schema
			-- Create a new path for the child node and recursively traverse it
			local child_path = new_childs(parent, node_name)

			-- Perform post-order traversal on the child node
			M.walk.post_order(child, child_path, fn)
		end

		if is_field(child) then
			fn(M.node_path(parent_path, node_name), child)
		end
	end
end

---@class ulf.confkit.traversal.node_path
---@field parent string
---@field node_name string

--- Iterates over all defined config fields.
---@param obj ulf.confkit.schema.Schema
---@param keys string[]
---@param path?  string
---@return function
---@return string[]
---@return integer
M.fields = function(obj, keys, path)
	-- Create a list to store ordered nodes
	local temp_list = {}
	path = path or ""

	-- Use the correct ordering
	for _, k in ipairs(keys) do
		local _field = obj[k]
		table.insert(temp_list, _field)
	end

	-- Custom iterator over the ordered list
	---comment
	---@param a table
	---@param i number
	local function iter(a, i)
		i = i + 1
		if i <= #a then
			---@type ulf.confkit.traversal.node_path
			local node_path = M.node_path(path, a[i].name)
			return i, node_path, a[i]
		end
	end

	return iter, temp_list, 0
end

return M
