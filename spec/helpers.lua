local M = {}

---@class test.ulf.confkit.FieldMock
---@field name? string
---@field description? string
---@field hook? function
---@field type? string
---@field fallback? string
---@field attributes? table<string,any>
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
		attributes = opts.attributes,
		value = opts.value,
	}
end

---comment
---@param severity_name string
M.severity_to_number = function(severity_name)
	local smap = {
		trace = 0,
		debug = 1,
		info = 2,
		warn = 3,
		error = 4,
		off = 5,
	}

	return smap[severity_name]
end

return M
