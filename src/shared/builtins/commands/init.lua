local RunService = game:GetService "RunService"

local types = require(script.Parent.Parent.types)
local admin_commands = require(script.admin)
local control_flow_commands = require(script.control_flow)
local debug_commands = require(script.debug)
local variable_commands = require(script.variables)
local math_commands = require(script.math)
local instances_commands = require(script.instances)

type Context = types.Context

local builtin_commands: {
	[string]: {
		run: ((Context) -> any)?,
		server_run: ((Context) -> any)?,
		description: string?,
		alias: { string }?,
		permissions: { string }?,
		overloads: { { returns: string, args: { { name: string, type: string } } } }?,
	},
} =
	{}

builtin_commands.clear = {
	description = "clears the console.",
	permissions = { "debug" },
	client_run = function(context: Context)
		context.process.logs = {}
	end,
	overloads = {
		{ returns = "nil", args = {} },
	},
}

builtin_commands.bind_tool = {
	description = "Binds a tool to a function",
	permissions = { "moderator" },
	server_run = function(context)
		local tool = context.args[1]
		tool.Activated:Connect(function()
			context.runtime.run_function(context.process, context.args[2])
		end)
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{ name = "Tool", type = "instance" },
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

builtin_commands.bind = {
	description = "Binds a function to a key",
	permissions = { "moderator" },
	client_run = function(context)
		context.process.bindings[context.args[1]] = context.args[2]
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Key",
					type = "keycode",
				},
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

builtin_commands.unbind = {
	description = "Unbinds a function from a key",
	permissions = { "moderator" },
	client_run = function(context)
		context.process.bindings[context.args[1]] = nil
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Key",
					type = "keycode",
				},
			},
		},
	},
}
builtin_commands.get_run_context = {
	description = "Returns whether this command is being ran on the server or the client",
	permissions = { "moderator" },
	run = function(context)
		if RunService:IsClient() then
			return "client"
		else
			return "server"
		end
	end,
	overloads = {
		{
			returns = "string",
			args = {},
		},
	},
}

for _, commands in
	{ admin_commands, control_flow_commands, debug_commands, variable_commands, math_commands, instances_commands }
do
	for name, command in commands do
		builtin_commands[name] = command
	end
end

return {
	builtin_commands = builtin_commands,
}
