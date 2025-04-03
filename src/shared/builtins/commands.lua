local Players = game:GetService "Players"
local types = require(script.Parent.Parent.types)

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

builtin_commands.print = {
	alias = {},
	description = "prints a message to console.",
	permissions = { "debug" },
	run = function(context)
		context:log {
			type = "info",
			at = tick(),
			value = table.concat(context.args, " "),
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

builtin_commands.clear = {
	description = "clears the console.",
	permissions = { "debug" },
	run = function(context)
		context:clear_logs()
	end,
	overloads = {
		{ returns = "nil", args = {} },
	},
}

builtin_commands.kill = {
	description = "kills players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			if player.Character then
				player.Character.Humanoid.Health = 0
			end
		end
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Targets",
			type = "players",
		} } },
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.bind_tool = {
	description = "Binds a tool to a function",
	permissions = { "moderator" },
	run = function(context)
		local tool = Instance.new "Tool"
		tool.Name = context.args[1]
		tool.RequiresHandle = false
		tool.Activated:Connect(function()
			print(context.args[2])
			context:run_function(context.args[2], {})
		end)
		tool.Parent = Players.LocalPlayer.Backpack
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{ name = "Name", type = "string" },
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

builtin_commands.gear = {
	description = "Gives players gear",
	permissions = { "moderator" },
	server_run = function(context)
		local players
		local gear
		if #context.args == 1 then
			players = { context.executor }
			gear = context.args[1]
		else
			players = context.args[1]
			gear = context.args[2]
		end
		local InsertService = game:GetService "InsertService"
		local model = InsertService:LoadAsset(gear)
		local tool = model:FindFirstChildOfClass "Tool"
		for _, player in players do
			tool:Clone().Parent = player.Backpack
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Gear Id",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = { {
				name = "Gear Id",
				type = "number",
			} },
		},
	},
}

builtin_commands.to = {
	description = "Teleports you to a player",
	permissions = { "moderator" },
	run = function(context)
		local player = context.args[1] or context.executor
		Players.LocalPlayer.Character:PivotTo(player.Character:GetPivot())
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Target",
			type = "player",
		} } },
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.respawn = {
	description = "Respawns players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			player:LoadCharacter()
		end
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Targets",
			type = "players",
		} } },
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.bring = {
	description = "Brings players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1]
		local target = context.executor
		for _, player in players do
			player.Character:PivotTo(target.Character:GetPivot())
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
			},
		},
	},
}

builtin_commands.teleport = {
	description = "Teleports players",
	alias = { "tp" },
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1]
		local pos = context.args[2]
		for _, player in players do
			if player.Character then
				player.Character:PivotTo(pos.Character:GetPivot())
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "To",
					type = "player",
				},
			},
		},
	},
}

builtin_commands.blink = {
	description = "Teleports to position under the mouse",
	permissions = { "moderator" },
	alias = { "b" },
	run = function(context)
		local mouse = Players.LocalPlayer:GetMouse()
		local pos = mouse.Hit.p
		Players.LocalPlayer.Character:PivotTo(CFrame.new(pos))
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.add = {
	description = "Adds numbers",
	permissions = { "math" },
	run = function(context)
		local sum = 0
		for _, arg in context.args do
			sum = sum + arg
		end
		return sum
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Value",
				type = "number",
				rest = true,
			} },
		},
	},
}

builtin_commands.as = {
	description = "Casts a string to a type",
	permissions = { "math" },
	run = function(context)
		error "this doesnt work yet"
	end,
	overloads = {
		{
			returns = "any",
			args = { {
				name = "Value",
				type = "any",
			}, {
				name = "Type",
				type = "type",
			} },
		},
	},
}

builtin_commands.equal = {
	description = "Checks if two values are equal",
	permissions = { "math" },
	alias = { "eq" },
	run = function(context)
		return context.args[1] == context.args[2]
	end,
	overloads = {
		-- this is funny gadget to test type inference but it's better to handle this at runtime
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "number",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "number",
		-- 		},
		-- 	},
		-- },
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "boolean",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "boolean",
		-- 		},
		-- 	},
		-- },
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "string",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "string",
		-- 		},
		-- 	},
		-- },
		{
			returns = "boolean",
			args = {
				{
					name = "LHS",
					type = "any",
				},
				{
					name = "RHS",
					type = "any",
				},
			},
		},
	},
}

builtin_commands["explode"] = {
	description = "Explodes players",
	permissions = { "moderator", "fun" },
	server_run = function(context)
		local players
		local blast_radius = 10
		if #context.args == 2 then
			players = context.args[1]
			blast_radius = context.args[2]
		elseif #context.args == 1 then
			if typeof(context.args[1]) == "table" then
				players = context.args[1]
			else
				players = { context.executor }
				blast_radius = context.args[1]
			end
		else
			players = { context.executor }
		end

		for _, player in players do
			local explosion = Instance.new "Explosion"
			explosion.Position = player.Character:GetPivot().Position
			explosion.Parent = workspace
			explosion.BlastRadius = blast_radius
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Players",
					type = "players",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Blast Radius",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Players",
					type = "players",
				},
				{
					name = "Blast Radius",
					type = "number",
				},
			},
		},
	},
}

builtin_commands["kick"] = {
	description = "Kicks players",
	permissions = { "admin" },
	server_run = function(context)
		local players = context.args[1]
		for _, player in players do
			player:Kick(context.args[2])
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Players",
					type = "players",
				},
				{
					name = "Reason",
					type = "string",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Players",
					type = "players",
				},
			},
		},
	},
}

builtin_commands["true"] = {
	description = "Returns true",
	permissions = { "math" },
	run = function(context)
		return true
	end,
	overloads = {
		{
			returns = "boolean",
			args = {},
		},
	},
}

builtin_commands["false"] = {
	description = "Returns false",
	permissions = { "math" },
	run = function(context)
		return false
	end,
	overloads = {
		{
			returns = "boolean",
			args = {},
		},
	},
}

builtin_commands.walkspeed = {
	description = "Sets the speed of the player",
	permissions = { "moderator" },
	alias = { "speed", "ws" },
	server_run = function(context)
		local players
		local speed
		if #context.args == 2 then
			players = context.args[1]
			speed = context.args[2]
		elseif #context.args == 1 then
			if typeof(context.args[1]) == "table" then
				players = context.args[1]
				speed = 16
			else
				players = { context.executor }
				speed = context.args[1]
			end
		end
		for _, player in players do
			if player.Character then
				player.Character.Humanoid.WalkSpeed = speed
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "speed",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = { {
				name = "Speed",
				type = "number",
			} },
		},
	},
}

builtin_commands.wait = {
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

builtin_commands.loop = {
	description = "Loops a function",
	permissions = { "control_flow" },
	run = function(context)
		while true do
			context:run_function(context.args[1])
			task.wait()
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

builtin_commands["while"] = {
	description = "Loops a function while a condition is true",
	permissions = { "control_flow" },
	run = function(context)
		while context:run_function(context.args[1]) do
			context:run_function(context.args[2])
			task.wait()
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

builtin_commands.jumppower = {
	description = "Sets the jump power of the player",
	permissions = { "moderator" },
	alias = { "jp" },
	server_run = function(context)
		local players
		local jumppower
		if #context.args == 2 then
			players = context.args[1]
			jumppower = context.args[2]
		elseif #context.args == 1 then
			if typeof(context.args[1]) == "table" then
				players = context.args[1]
				jumppower = 50
			else
				players = { context.executor }
				jumppower = context.args[1]
			end
		end
		for _, player in players do
			if player.Character then
				player.Character.Humanoid.JumpPower = jumppower
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Jump Power",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = { {
				name = "Jump Power",
				type = "number",
			} },
		},
	},
}

builtin_commands.concat = {
	description = "Concatenates strings",
	permissions = { "math" },
	run = function(context)
		return table.concat(context.args, "")
	end,
	overloads = {
		{
			returns = "string",
			args = { {
				name = "Strings",
				type = "string",
				rest = true,
			} },
		},
	},
}

builtin_commands.mul = {
	description = "Multiplies two numbers",
	permissions = { "math" },
	run = function(context)
		local product = 1
		for _, arg in context.args do
			product = product * arg
		end
		return product
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Value",
				type = "number",
				rest = true,
			} },
		},
	},
}

builtin_commands.position = {
	description = "Prints the position of the player",
	permissions = { "debug", "moderator" },
	run = function(context)
		local plr = context.args[1] or game.Players.LocalPlayer
		local pos = plr.Character:GetPivot().Position
		context:log {
			type = "info",
			at = tick(),
			value = Vector3.new(pos.X, pos.Y, pos.Z),
		}
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Target",
			type = "player",
		} } },
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.echo = {
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

builtin_commands["if"] = {
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

return {
	builtin_commands = builtin_commands,
}
