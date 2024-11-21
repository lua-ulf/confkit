# ULF ConfKit

`ulf.confkit` is a configuration manager module for ulf.

## Usage

### Fields

Use a simple table to define your fields in a `Schema`. First item can be
the default value or the description of a field. The type is auto detected or can
be set using the `type` keyword. Hooks can be used to transform a value before
it is written and are set using the `hook` keyword.

```Lua
local f = { [[This is the schema version]], value = "1.1.0" }
```

### Schema

A `Schema` takes a key-value pair of `Field` objects and `SchemaOptions`. Use
`SchemaOptions.description` to set a description for the schema and
`SchemaOptions.fallback` to configure a field's default value to return the value
of another `Field`. When you set a value of a field which has a fallback then the
actual value is returned.

Define your configuration schema:

```Lua

---@param severity_name string
local severity_hook = function(severity_name)
 local smap = {trace = 0, debug = 1, info = 2, warn = 3, error = 4, off = 5,}
 return smap[severity_name]
end

local ConfigSchema = Schema({
 version = { [[This is the schema version]], value = "1.1.0" },
 enabled = { true, [[This is an boolean tag]] },
 priority = { 10, [[This is the priority field]], type = "number" },
 opts = { [[This is the opts field]], type = "table" },
 tag = { [[This is an optional tag]], type = "string" },
 global = Schema({
  severity = { "info", "Global severity level", hook = severity_hook, type = "number" },
 }, "Global settings"),
 logger = Schema({
  default = Schema({
   filename = { "Logger filename", type = "string" },
   severity = { "Logger severity level", hook = severity_hook, type = "number" },
  }, "Default logger settings"),
 }, "Logger settings"),
}, {
 description = "Schema root",
 fallback = { ["logger.default.severity"] = "global.severity" },
})
```

### Schema Class

Create a `class` from a `Schema` and use it like an Object:

```Lua
local Config = ConfigSchema:create_class()
local cfg = Config.new()

local another_cfg = Config.new()
```

### Field API

#### Get Values

```Lua
local version = cfg.version.value
```

#### Set Values

You can set a value by assignment

```Lua
cfg.version.value = "2.1.0"
```

You can set multiple values by calling a schema block:

```Lua

cfg{
  enabled = true,
  priority = 100,
  version = "2.1.0",
}
```

## Dependencies

* ulf.lib

## Testing

Executing a single test file

```shell
make test-lua BUSTED_ARGS=spec/tests/ulf/confkit/schema_spec.lua
```

Using a busted tag

```shell
make test-lua BUSTED_TAG=ulf.confkit.schema
```

* Documentation
