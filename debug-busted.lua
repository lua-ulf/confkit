local BUSTED_VERSION = "2.2.0-1"

local LUA_INTERPRETER_VERSION = "5.1"
local TARGET_DIR = "build/2.1.0-beta3"
local LUA_PACKAGE_PATH = TARGET_DIR
	.. "/share/lua/"
	.. LUA_INTERPRETER_VERSION
	.. "/?.lua;"
	.. TARGET_DIR
	.. "/share/lua/"
	.. LUA_INTERPRETER_VERSION
	.. "/?/init.lua;"
LUA_PACKAGE_CPATH = TARGET_DIR .. "/lib/lua/" .. LUA_INTERPRETER_VERSION .. "/?.so;"
package.path = LUA_PACKAGE_PATH .. package.path .. ";"
package.cpath = LUA_PACKAGE_CPATH .. package.cpath .. ";"
local k, l, _ = pcall(require, "luarocks.loader")
_ = k and l.add_context("busted", BUSTED_VERSION)
-- NVIM_BUSTED_EXEC ?= "$(TARGET_DIR)/lib/luarocks/rocks-$(LUA_INTERPRETER_VERSION)/busted/$(BUSTED_VERSION)/bin/busted"

require("busted.runner")({ standalone = false })
