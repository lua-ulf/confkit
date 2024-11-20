---@class ulf.confkit.constants
local M = {}

---@tag ulf.confkit.constants

---@config { ['field_heading'] = "Options", ["module"] = "ulf.confkit.constants" }

---@brief [[
---
--- `ulf.confkit.constants` contains global constants for `ConfKit`
---
---@brief ]]

---@alias ulf.confkit.field_behaviour_type
---| 0b0000 # Default config field
---| 0b0001 # Mandatory config field
---| 0b0010 # Optional config field
---| 0b0100 # Readonly config field

M.NIL = string.char(0)

-- stylua: ignore
---
---@class ulf.confkit.FieldBehaviour @Valid flags for configuring the behaviour of a field.
---@field DEFAULT number: default field behaviour is a field with a default value
---@field FALLBACK number: enables fallback value lookup of foreign fields
---@field OPTIONAL number: when optional is set default and value can be nil
---@field READONLY number: readonly cannot be written to
M.FIELD_BEHAVIOUR = {
	DEFAULT  = 0b0000, 
	FALLBACK = 0b0001, -- 1 in binary
	OPTIONAL = 0b0010, -- 2 in binary
	READONLY = 0b0100, -- 4 in binary (example of adding another flag)
}
return M
