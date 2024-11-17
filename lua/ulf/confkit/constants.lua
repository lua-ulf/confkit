---@class ulf.confkit.constants
local M = {}

---@brief [[
--- `ulf.confkit.constants` contains global constants for `ConfKit`
---
---@brief ]]

---@alias ulf.confkit.field_behaviour_type
---| 1 # Mandatory config field
---| 2 # Optional config field
---| 3 # Fallback config field
---| 10 # Non config field

--- BEHAVIOUR!
---@class ulf.confkit.FieldBehaviour
M.FIELD_BEHAVIOUR = {
	MANDATORY_FIELD = 1,
	OPTIONAL_FIELD = 2,
	FALLBACK_FIELD = 3,
	NON_FIELD = 10,
}
M.NIL = string.char(0)

return M
