local parser = require(script.Parent.parser)
local types = require(script.Parent.types)
local builtin_types = require(script.types).builtin_types
local builtin_commands = require(script.commands).builtin_commands

type Context = types.Context
type Type = types.Type
type Expression = parser.Expression

local builtin_permission_types = {
	owner = { "admin" },
	admin = { "moderator", "control_flow", "automation"},
	moderator = { "vip", "fun", "math", "debug" },
	vip = { "normal" },
	normal = {},

	fun = {},
	debug = {},
	math = {},
	automation = {},
	control_flow = {},
}

return {
	builtin_commands = builtin_commands,
	builtin_permission_types = builtin_permission_types,
	builtin_types = builtin_types,
}
