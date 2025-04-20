local commands = {}

commands.print = {
	alias = {},
	description = "prints a message to console.",
	permissions = { "debug" },
	run = function(context)
		local msg = context.args[1]
		for i = 2, #context.args do
			if context.args[i] then
				msg = tostring(msg) .. " " .. tostring(context.args[i])
			end
		end
		context:log {
			type = "info",
			at = tick(),
			value = msg,
		}
		print(unpack(context.args))
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Message",
			type = "any",
			rest = true,
		} } },
	},
}

commands.echo = {
	alias = { "identity" },
	description = "Returns a value.",
	permissions = { "debug" },
	run = function(context)
		return context.args[1]
	end,
	overloads = {
		{ returns = "any", args = { {
			name = "Value",
			type = "any",
		} } },
	},
}

return commands
