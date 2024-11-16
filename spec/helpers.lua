local M = {}

---@class test.ulf.confkit.FieldMock
---@field name? string
---@field description? string
---@field hook? function
---@field type? string
---@field fallback? string
---@field value? any
---@field default? any

---@param opts test.ulf.confkit.FieldMock
M.field_mock = function(opts)
	return {
		name = opts.name,
		description = opts.description,
		default = opts.default,
		hook = opts.hook,
		fallback = opts.fallback,
		type = opts.type,
		value = opts.value,
	}
end

return M
