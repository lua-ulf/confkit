---@class ulf.confkit.lib
local M = {}

---@tag ulf.confkit.lib
---@config { ["module"] = "ulf.confkit.lib" }

---@brief [[
--- External librarie for `ConfKit`
---
--- Import external libraries only here and require this file. This makes it
--- easier to manage external depenendencies.
---@brief ]]

local ulf = {
	lib = require("ulf.lib"),
}

M.split = ulf.lib.string.split
M.deepcopy = ulf.lib.table.deepcopy
M.tbl_isempty = ulf.lib.table.tbl_isempty
M.tbl_get = ulf.lib.table.tbl_get
M.trim = ulf.lib.string.trim
M.gsplit = ulf.lib.string.gsplit
M.dedent = ulf.lib.string.dedent

return M
