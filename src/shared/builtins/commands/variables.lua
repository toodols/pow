local commands = {}

commands.out = {
	description = "Returns the value of the nth result",
	permissions = {"variables"},
	run = function(context)
		return context.process.results[context.args[1]]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Index",
					type = "number",
				},
			},
		},
	},
}

commands["set"] = {
	description = "Sets a variable",
	permissions = { "variables" },
	run = function(context)
		context.process.global_scope.variables[context.args[1]] = context.args[2]
		return context.args[2]
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Variable",
					type = "variable_name",
				},
				{
					name = "Value",
					type = "any",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Variable",
					type = "variable_name",
				},
			},
		},
	},
}

commands.increment = {
	description = "Increments a variable",
	permissions = { "variables" },
	run = function(context)
		local variables = context.process.global_scope.variables
		local name = context.args[1]
		if not variables[name] then
			variables[name] = 0
		end
		variables[name] = variables[name] + 1
		return variables[name]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Variable",
					type = "variable_name",
				},
			},
		},
	},
}

commands["get"] = {
	description = "Gets a variable",
	permissions = { "variables" },
	run = function(context)
		return context.process.global_scope.variables[context.args[1]]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Variable",
					type = "variable_name",
				},
			},
		},
	},
}

return commands
