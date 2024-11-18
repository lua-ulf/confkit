---@class b64tm.Logger : ulf.util.minilog.Logger
local log = require("ulf.util.minilog").Logger.create({
	appname = "ulf.confkit",
	severity = "trace",
	multi_line = true,
	targets = {
		terminal = true,
	},
})

return log
