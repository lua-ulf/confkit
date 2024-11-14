SHELL := /bin/bash
DEPS ?= build

TEST_CONTEXT_ROOT := $(shell pwd)
LUA_INTERPRETER_VERSION := 5.1
LUA_VERSION ?= luajit 2.1.0-beta3
NVIM_BIN ?= nvim
NVIM_LUA_VERSION := $(shell $(NVIM_BIN) -v 2>/dev/null | grep -E '^Lua(JIT)?' | tr A-Z a-z)
ifdef NVIM_LUA_VERSION
LUA_VERSION ?= $(NVIM_LUA_VERSION)
endif
LUA_NUMBER := $(word 2,$(LUA_VERSION))

TARGET_DIR := $(DEPS)/$(LUA_NUMBER)

ROCKS_PACKAGE_VERSION := $(shell ./.rocks-version ver)
ROCKS_PACKAGE_REVISION := $(shell ./.rocks-version rev)
APPNAME := ulf.confkit
TMP_DIR := .tmp

LUAROCKS_INIT ?= $(TMP_DIR)/luarocks-init
LUAROCKS_DEPS ?= $(TMP_DIR)/luarocks-deps
LUAROCKS_TEST_PREPARE ?= $(TMP_DIR)/luarocks-test-prepare
LUAROCKS_MAKE_LOCAL ?= $(TMP_DIR)/luarocks-make-local

HEREROCKS ?= $(DEPS)/hererocks.py
HEREROCKS_URL ?= https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py
HEREROCKS_ACTIVE := source $(TARGET_DIR)/bin/activate

LUAROCKS ?= $(TARGET_DIR)/bin/luarocks

BUSTED ?= $(TARGET_DIR)/bin/busted
BUSTED_HELPER ?= $(PWD)/spec/busted_helper.lua
BUSTED_FILTER := .*
BUSTED_TAG := ulf.confkit
BUSTED_ARGS := spec/tests
BUSTED_VERSION := 2.2.0-1

LUA_PACKAGE_PATH ?= $(TARGET_DIR)/share/lua/$(LUA_INTERPRETER_VERSION)/?.lua;$(TARGET_DIR)/share/lua/$(LUA_INTERPRETER_VERSION)/?/init.lua
LUA_PACKAGE_CPATH ?= $(TARGET_DIR)/lib/lua/$(LUA_INTERPRETER_VERSION)/?.so
NVIM_PACKAGE_PATH ?= "lua package.path='$(LUA_PACKAGE_PATH)'..package.path;package.cpath='$(LUA_PACKAGE_CPATH)'..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('busted','$(BUSTED_VERSION)')"
NVIM_BUSTED_EXEC ?= "$(TARGET_DIR)/lib/luarocks/rocks-$(LUA_INTERPRETER_VERSION)/busted/$(BUSTED_VERSION)/bin/busted"
NVIM_BUSTED_ARGS ?= spec/tests

LUV ?= $(TARGET_DIR)/lib/lua/$(LUA_NUMBER)/luv.so

LUA_LS ?= $(DEPS)/lua-language-server
LINT_LEVEL ?= Information
LUAROCKS_CONFIG := build/2.1.0-beta3/etc/luarocks/config-5.1.lua
NVIM_DOC := doc
NVIM_DOC_FILE := $(NVIM_DOC)/ulf.confkit.txt

.EXPORT_ALL_VARIABLES:

all: deps

deps: | $(HEREROCKS) $(BUSTED)

doc: 
	@rm -f $(NVIM_DOC_FILE)
	ulf-gendocs tree_sitter_lua --config .ulf-gendocs.json
	head $(NVIM_DOC_FILE)


test: test_lua test_nvim

test-lua: $(BUSTED) $(LUV)
	@echo Test with $(LUA_VERSION) ......
	@$(HEREROCKS_ACTIVE) && eval $$($(LUAROCKS) path) && \
		$(BUSTED) --helper=$(BUSTED_HELPER) --tags=$(BUSTED_TAG) --filter=$(BUSTED_FILTER) $(BUSTED_ARGS)

test-nvim:
	@echo Test with $(NVIM_LUA_VERSION) ......
	@$(NVIM_BIN) -u NONE --headless -c $(NVIM_PACKAGE_PATH) \
		-l $(NVIM_BUSTED_EXEC) --helper=$(BUSTED_HELPER) --tags=$(BUSTED_TAG) $(BUSTED_ARGS)

$(TMP_DIR):
	@mkdir -p $(TMP_DIR)

$(HEREROCKS): $(TMP_DIR)
	mkdir -p $(DEPS)
	curl $(HEREROCKS_URL) -o $@

$(LUAROCKS): $(HEREROCKS)
	$(HEREROCKS_ENV) python3 $< $(TARGET_DIR) --$(LUA_VERSION) -r latest

$(BUSTED): $(LUAROCKS) | $(LUAROCKS_TEST_PREPARE)
	$(HEREROCKS_ACTIVE) && $(LUAROCKS) install busted

# Ensure luarocks-test-prepare is only run once
$(LUAROCKS_TEST_PREPARE): $(LUAROCKS) ## Installs all dependencies for testing (runs once)
	luarocks test --prepare $(APPNAME)-$(ROCKS_PACKAGE_VERSION)-$(ROCKS_PACKAGE_REVISION).rockspec && \
	touch $(TMP_DIR)/luarocks-test-prepare

$(LUV): $(LUAROCKS)
	@$(HEREROCKS_ACTIVE) && [[ ! $$($(LUAROCKS) which luv) ]] && \
		$(LUAROCKS) install luv || true

lint:
	@rm -rf $(LUA_LS)
	@mkdir -p $(LUA_LS)
	@lua-language-server --check $(PWD) --checklevel=$(LINT_LEVEL) --logpath=$(LUA_LS)
	@grep -q '^\[\]\s*$$' $(LUA_LS)/check.json || (cat $(LUA_LS)/check.json && exit 1)

clean:
	rm -rf $(DEPS)

.PHONY: all deps doc clean lint test test_nvim test_lua
