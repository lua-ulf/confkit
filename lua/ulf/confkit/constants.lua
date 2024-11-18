---@class ulf.confkit.constants
local M = {}

---@brief [[
--- `ulf.confkit.constants` contains global constants for `ConfKit`
---
---@brief ]]

---@alias ulf.confkit.field_behaviour_type
---| 0b0000 # Default config field
---| 0b0001 # Mandatory config field
---| 0b0010 # Optional config field
---| 0b0100 # Readonly config field
---| 0b1000 # Fallback config field

M.NIL = string.char(0)

-- stylua: ignore
---@class ulf.confkit.FieldBehaviour
M.FIELD_BEHAVIOUR = {
	DEFAULT  = 0b0000,
	FALLBACK = 0b0001, -- 1 in binary
	OPTIONAL = 0b0010, -- 2 in binary
	READONLY = 0b0100, -- 4 in binary (example of adding another flag)
	VALIDATE = 0b1000, -- 8 in binary (another example)
}
return M
