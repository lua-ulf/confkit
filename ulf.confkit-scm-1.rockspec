---@diagnostic disable:lowercase-global

rockspec_format = "3.0"
package = "ulf.confkit"
version = "scm-1"
source = {
	url = "https://github.com/lua-ulf/ulf.confkit/archive/refs/tags/scm-1.zip",
}

description = {
	summary = "ulf.confkit is the core library for the ULF framework.",
	labels = { "lua", "neovim", "ulf" },
	homepage = "http://github.com/lua-ulf/ulf.confkit",
	license = "MIT",
}

dependencies = {
	"lua >= 5.1",
	"inspect",
	"lpeg",
}
build = {
	type = "builtin",
	modules = {},
	copy_directories = {},
	platforms = {},
}
test_dependencies = {
	"busted",
	"busted-htest",
	"luacov",
	"luacov-html",
	"luacov-multiple",
	"luacov-console",
	"luafilesystem",
}
test = {
	type = "busted",
}
