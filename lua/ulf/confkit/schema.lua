local Field = require("ulf.confkit.field")
local log = require("ulf.confkit.logger")
local Traversal = require("ulf.confkit.traversal")
local Spec = require("ulf.confkit.spec")
local Util = require("ulf.confkit.util")

local Lib = require("ulf.confkit.lib")
local split = Lib.split
local deepcopy = Lib.deepcopy
local tbl_isempty = Lib.tbl_isempty
local tbl_get = Lib.tbl_get

local is_field = Util.is_field

local f = string.format
local unpack = table.unpack or unpack

---@alias ulf.confkit.schema.key_type
---| 1 # Field
---| 10 # Non Field

---@class ulf.confkit.SchemaClassOptions @Options for the generated SchemaClass constructor
---@field base table: Base class

---@class ulf.confkit.SchemaClass : ulf.confkit.schema.Schema @SchemaClass is a generated class from a schema so that you can create separate instances
---@field new fun(options:ulf.confkit.SchemaClassOptions?): ulf.confkit.SchemaClass
---@overload fun(options:ulf.confkit.SchemaClassOptions?): ulf.confkit.SchemaClass

---@class ulf.confkit.schema.SchemaBase @SchemaBase are basic attributes for options and an instance

---@class ulf.confkit.schema.SchemaOptions : ulf.confkit.schema.SchemaBase @SchemaOptions are options which are passed to the constructor to set initial values
---@field order? string[]: the order of config keys when iterating over the table
---@field description? string: description for this table
---@field fallback? table<string,string>: Internal fallback map

---@class ulf.confkit.schema.SchemaField
---@field get fun(path:string):ulf.confkit.field.Field?

---@class ulf.confkit.schema.Schema : ulf.confkit.schema.SchemaBase
---@field field ulf.confkit.schema.SchemaField
---@field _values table<string,any>
---@field _keys table<string,ulf.confkit.schema.key_type>
---@field _order string[] @maintains a sorted list of all keys if no order is given when iterating
---@field _parent? string
---@field description? string: description for this table
---@overload fun(tbl:table,self:ulf.confkit.schema.SchemaOptions|string?):ulf.confkit.schema.Schema
local Schema = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
Schema.__index = Schema

---@class ulf.confkit.schema.KeyType
Schema.KEY_TYPE = {
	FIELD = 1,
	NON_FIELD = 10,
}

Schema.Field = {}

--- Returns a field by its full path (dotted)
---@param self ulf.confkit.schema.Schema
---@param path string
---@return ulf.confkit.field.Field?
Schema.Field.get = function(self, path)
	if not path:match("%.") then
		return self[path]
	end
	local nodes = split(path, ".", { plain = true })
	if type(nodes) ~= "table" or #nodes == 0 then
		return
	end
	local field = tbl_get(self, unpack(nodes))
	return field
end

---@param self ulf.confkit.schema.Schema
---@param data table<string,any>
Schema.update = function(self, data)
	log.debug("Schema.update: called data=", data)

	if type(data) == "table" then
		if tbl_isempty(data) then
			return
		end

		for key, value in pairs(data) do
			-- if value == Field.NIL then
			-- 	value = nil
			-- end
			if is_field(self[key]) then
				log.debug(f("Schema.update: setting value '%s' for field '%s'", value, key))
				---@type any
				self[key].value = value
			else
				log.warn(f("Schema.update: WARNING: no such field '%s' to update", key))
			end
		end
	end
end

---@param self ulf.confkit.schema.Schema
---@param key string
---@param value any
Schema.key_setter = function(self, key, value)
	log.debug(
		f("Schema.key_setter: key='%s' value='%s'", key, Spec.field.is_field_spec(value) and "Field SPEC" or value)
	)

	---@type ulf.confkit.field.Field
	local new_field

	if Spec.field.is_field_spec(value) then
		new_field = Field.parse(key, value)
		if new_field ~= nil then
			log.debug(f("Schema.key_setter: Field.parse result new_field=%s", new_field))
			self._keys[key] = Schema.KEY_TYPE.FIELD
			self._values[key] = new_field
			self._order[#self._order + 1] = key
			table.sort(self._order)
		else
		end
	else
		self._keys[key] = Schema.KEY_TYPE.NON_FIELD
		self._values[key] = value
	end
end

---@param self ulf.confkit.schema.Schema
---@param key string
Schema.key_getter = function(self, key)
	log.debug(f("Schema.key_handler: key=%s", key))
	local v

	if key == "field" then
		return {
			---comment
			---@param path string
			get = function(path)
				return Schema.Field.get(self, path)
			end,
		}
	end

	v = rawget(self, key) or rawget(Schema, key)
	if v ~= nil then
		return v
	end

	---@type table<string,ulf.confkit.field.Field>
	local values = rawget(self, "_values")
	v = values[key]

	return v
end

Schema.meta = {
	__newindex = Schema.key_setter,
	__index = Schema.key_getter,
	__call = Schema.update,
	__class = {
		name = "ulf.confkit.Schema",
	},
}

---@param tbl? table
---@param opts? ulf.confkit.schema.SchemaOptions|string: options for this schema or just a string as a description
function Schema.new(tbl, opts)
	opts = opts or {}

	---@type string
	local description
	if type(opts) == "string" then
		description = opts
	elseif type(opts) == "table" then
		description = opts.description
	end

	local obj = {
		_keys = {},
		_values = {},
		_order = type(opts) == "table" and opts.order or {},
		description = description,
	}

	local self = setmetatable(obj, Schema.meta)

	if tbl then
		for key, value in
			pairs(tbl --[[@as ulf.lib.conf.ctable_spec ]])
		do
			self[key] = value
		end
	end

	if opts.fallback then
		Schema.route_fallback_values(self, opts.fallback)
	end

	return self
end

---
---@param self ulf.confkit.schema.Schema
---@param fallback_map table<string,string>
function Schema.route_fallback_values(self, fallback_map)
	---@param source ulf.confkit.field.Field
	---@param target ulf.confkit.field.Field
	local route_field = function(source, target)
		if type(source) ~= "table" or type(target) ~= "table" then
			return
		end

		source:set_fallback(target)
		log.debug(
			f(
				"Schema.route_fallback_values: routing field '%s' to target '%s'|source.behaviour=%s, source.context.target=%s",
				source.name,
				target.name,
				source.behaviour,
				type(source.context) == "table" and source.context.target or "INVALID"
			)
		)
	end

	for source_node, target_node in pairs(fallback_map) do
		route_field(Schema.Field.get(self, source_node), Schema.Field.get(self, target_node))
	end
end

---@param self ulf.confkit.schema.Schema
---@param options? ulf.confkit.SchemaClassOptions
function Schema.create_class(self, options)
	---@type ulf.confkit.SchemaClass
	local Class = setmetatable({}, {
		__call = function(t, ...)
			return t.new(...)
		end,
	})

	function Class.new(opts)
		opts = opts or {}
		return setmetatable({
			_schema = deepcopy(self),
		}, {
			__index = function(t, k)
				local v = rawget(t, k) or rawget(Class, k)
				if v ~= nil then
					return v
				end
				-- local _schema = rawget(t, "_schema")

				return self[k]
			end,
		})
	end
	return Class
end

---@param self ulf.confkit.schema.Schema
---@param order? string[]
Schema.fields = function(self, order)
	order = order or self._order
	return Traversal.fields(self, order)
end

---@param self ulf.confkit.schema.Schema
---@param fn ulf.confkit.traversal.visitor
---@param order? "post_order"|"level_order"
Schema.walk = function(self, fn, order)
	order = order or "post_order"
	return Traversal.walk[order](self, {}, fn)
end
return Schema
