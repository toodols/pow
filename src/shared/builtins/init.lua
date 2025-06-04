local parser = require(script.Parent.parser)
local types = require(script.Parent.types)
local builtin_types = require(script.types).builtin_types
local builtin_commands = require(script.commands).builtin_commands

type Context = types.Context
type Type = types.Type
type Expression = parser.Expression

local builtin_permission_types = {
	-- hard-coded role that automatically has all permissions,
	-- present and future, and thus does not need explicit derived roles
	root = {},

	-- standard 5-tier roles found in most admin commands
	owner = { "admin" },
	admin = { "moderator", "control_flow", "automation" },
	moderator = { "vip", "fun", "math", "view_permissions" },
	vip = { "normal" },
	normal = { "debug" },

	-- other partial permission types
	fun = {},
	debug = {},
	math = {},
	automation = {},
	control_flow = {},
	view_permissions = {},
}

return {
	builtin_commands = builtin_commands,
	builtin_permission_types = builtin_permission_types,
	builtin_types = builtin_types,
}
