local commands = {}

commands["repeat"] = {
	description = "Repeats a function a number of times",
	permissions = { "control_flow" },
	run = function(context)
		for i = 1, context.args[1] do
			context:run_function(context.args[2])
		end
	end,
	overloads = {
		{
			returns = "nil",
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

commands["while"] = {
	description = "Loops a function while a condition is true",
	permissions = { "control_flow" },
	run = function(context)
		local waits = false
		while context:run_function(context.args[1]) do
			local t = tick()
			context:run_function(context.args[2])
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
			return context:run_function(context.args[2])
		elseif context.args[3] then
			return context:run_function(context.args[3])
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
			context:run_function(context.args[1])
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
