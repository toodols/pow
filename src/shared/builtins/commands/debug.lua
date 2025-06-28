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
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Message",
			type = "any",
			rest = true,
		} } },
	},
}

commands.test_quoted_enum = {
	permissions = { "debug" },
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "...",
					type = "test_quoted_enum",
				},
			},
		},
	},
	run = function() end,
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

-- commands.test_recursive = {
-- 	description = "Returns a recursive value",
-- 	permissions = { "debug" },
-- 	run = function(context)
-- 		local recursive = {}
-- 		recursive.foo = recursive
-- 		return recursive
-- 	end,
-- 	overloads = {
-- 		{
-- 			returns = "any",
-- 			args = {},
-- 		},
-- 	},
-- }

return commands
