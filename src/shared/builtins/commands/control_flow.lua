function unwrap(res)
	if res.err ~= nil then
		error(res)
	end
	return res.ok
end
local commands = {}

commands["repeat"] = {
	description = "Repeats a function a number of times. Returns all results as a table",
	permissions = { "control_flow" },
	run = function(context)
		local results = {}
		for i = 1, context.args[1] do
			local res = context.runtime.run_function(context.process, context.args[2])
			table.insert(results, unwrap(res))
		end
		return results
	end,
	overloads = {
		{
			returns = "table",
			args = {
				{
					name = "Times",
					type = "number",
				},
				{
					name = "Body",
					type = "function",
				},
			},
		},
	},
}

commands.run = {
	description = "Runs a function",
	permissions = { "control_flow" },
	run = function(context)
		local res = context.runtime.run_function(context.process, context.args[1])
		return unwrap(res)
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

commands["foreach"] = {
	description = "Iterates over a table with a variable",
	permissions = { "control_flow", "variables" },
	overloads = {
		{
			returns = "table",
			args = {
				{
					name = "Variable",
					type = "variable_name",
				},
				{
					name = "Table",
					type = "table",
				},
				{
					name = "Body",
					type = "function",
				},
			},
		},
	},
	run = function(context)
		local results = {}
		local var_name = context.args[1]
		local tab = context.args[2]
		local fun = context.args[3]
		for _, value in tab do
			context.process.global_scope.variables[var_name] = value
			local res = context.runtime.run_function(context.process, fun)
			table.insert(results, unwrap(res))
		end
		return results
	end,
}

commands["client"] = {
	description = "Forces a function to run in client context",
	permissions = { "control_flow" },
	client_run = function(context)
		return context.runtime.run_function(context.process, context.args[1])
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}
commands["server"] = {
	description = "Forces a function to run in server context",
	permissions = { "control_flow" },
	server_run = function(context)
		unwrap(context.runtime.run_function(context.process, context.args[1]))
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

commands["while"] = {
	description = "Loops a function while a condition is true",
	permissions = { "control_flow" },
	run = function(context)
		local waits = false
		while context.runtime.run_function(context.process, context.args[1]) do
			local t = tick()
			context.runtime.run_function(context.process, context.args[2])
			if tick() - t < 1 then
				if not waits then
					context:log {
						type = "info",
						value = "This loop is too fast. A wait has been added",
					}
				end
				waits = true
				task.wait()
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Condition",
					type = "function",
				},
				{
					name = "Body",
					type = "function",
				},
			},
		},
	},
}

commands["if"] = {
	description = "if statement.",
	permissions = { "control_flow" },
	run = function(context)
		if context.args[1] then
			return context.runtime.run_function(context.process, context.args[2])
		elseif context.args[3] then
			return context.runtime.run_function(context.process, context.args[3])
		end
		return nil
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Condition",
					type = "boolean",
				},
				{
					name = "True",
					type = "function",
				},
				{
					name = "False",
					type = "function",
				},
			},
		},
		{
			returns = "any",
			args = {
				{
					name = "Condition",
					type = "boolean",
				},
				{
					name = "True",
					type = "function",
				},
			},
		},
	},
}

commands.loop = {
	description = "Loops a function indefinitely",
	permissions = { "control_flow" },
	run = function(context)
		local waits = false
		while true do
			local t = tick()
			context.runtime.run_function(context.process, context.args[1])
			if tick() - t < 1 then
				if not waits then
					context:log {
						type = "info",
						value = "This loop is too fast. A wait has been added",
					}
				end
				waits = true
				task.wait()
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Body",
				type = "function",
			} },
		},
	},
}

commands.run_and_wait = {
	description = "Runs a function (server), waits, then returns the result. Used for waiting for a newly created instance on the server to replicate to the client",
	permissions = { "control_flow" },
	server_run = function(context)
		local res = unwrap(context.runtime.run_function(context.process, context.args[2]))
		task.wait(context.args[1])
		return res
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Seconds",
					type = "number",
				},
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

commands.wait = {
	description = "Waits for a number of seconds",
	permissions = { "control_flow" },
	run = function(context)
		task.wait(context.args[1])
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Seconds",
				type = "number",
			} },
		},
	},
}

return commands
