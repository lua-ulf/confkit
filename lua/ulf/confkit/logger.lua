---@class ulf.confkit.Logger : ulf.util.minilog.Logger
---@field debug fun(...:any)
---@field info fun(...:any)
---@field warn fun(...:any)
---@field error fun(...:any)
local log = require("ulf.util.minilog").Logger.create({
	appname = "ulf.confkit",
	severity = "trace",
	multi_line = true,
	targets = {
		terminal = false,
	},
})

return log
