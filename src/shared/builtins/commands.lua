local Players = game:GetService "Players"
local InsertService = game:GetService "InsertService"
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
		local tool = context.args[1]
		tool.Activated:Connect(function()
			context:run_function(context.args[2], {})
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

builtin_commands.index = {
	description = "Returns the value at the index of a table",
	permissions = { "math" },
	run = function(context)
		return context.args[1][context.args[2]]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{ name = "Table", type = "table" },
				{ name = "Index", type = "number" },
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

builtin_commands.unshirt = {
	description = "Removes a player's shirt",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local character = player.Character
			local shirt = character:FindFirstChildOfClass "Shirt"
			if shirt then
				shirt:Destroy()
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.shirt = {
	description = "Sets a player's a shirt",
	permissions = { "moderator" },
	server_run = function(context)
		local players
		local id
		if #context.args == 1 then
			players = { context.executor }
			id = context.args[1]
		else
			players = context.args[1]
			id = context.args[2]
		end

		local template = InsertService:LoadAsset(id):FindFirstChildOfClass "Shirt"

		for _, player in players do
			local character = player.Character
			local shirt = character:FindFirstChildOfClass "Shirt"
			if not shirt then
				shirt = Instance.new "Shirt"
				shirt.Parent = character
			end
			shirt.ShirtTemplate = template.ShirtTemplate
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Shirt Id",
				type = "number",
			} },
		},
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Shirt Id",
					type = "number",
				},
			},
		},
	},
}

builtin_commands.forcefield = {
	alias = { "ff" },
	description = "Gives players a forcefield",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local character = player.Character
			local forcefield = Instance.new "ForceField"
			forcefield.Parent = character
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.unforcefield = {
	alias = { "unff" },
	description = "Removes all forcefields from players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local character = player.Character
			for _, forcefield in character:GetChildren() do
				if forcefield:IsA "ForceField" then
					forcefield:Destroy()
				end
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.unpants = {
	description = "Removes a player's pants",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local character = player.Character
			local pants = character:FindFirstChildOfClass "Pants"
			if pants then
				pants:Destroy()
			end
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Targets",
				type = "players",
			} },
		},
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.pants = {
	description = "Sets a player's pants",
	permissions = { "moderator" },
	server_run = function(context)
		local players
		local id
		if #context.args == 1 then
			players = { context.executor }
			id = context.args[1]
		else
			players = context.args[1]
			id = context.args[2]
		end
		local template = InsertService:LoadAsset(id):FindFirstChildOfClass "Pants"
		for _, player in players do
			local character = player.Character
			local pants = character:FindFirstChildOfClass "Pants"
			if not pants then
				pants = Instance.new "Pants"
				pants.Parent = character
			end
			pants.PantsTemplate = template.PantsTemplate
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Pants Id",
				type = "number",
			} },
		},
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Pants Id",
					type = "number",
				},
			},
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

builtin_commands.hit = {
	description = "Returns the CFrame under the mouse",
	permissions = { "moderator" },
	run = function(context)
		return Players.LocalPlayer:GetMouse().Hit
	end,
	overloads = {
		{
			returns = "cframe",
			args = {},
		},
	},
}

builtin_commands.unlock = {
	description = "Unlocks players",
	permissions = { "moderator" },
	server_run = function(context)
		local player = context.args[1] or { context.executor }
		local character = player.Character
		for _, part in character:GetDescendants() do
			if part:IsA "BasePart" then
				part.Locked = false
			end
		end
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Target",
			type = "players",
		} } },
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.equipped = {
	description = "Returns the equipped tool",
	permissions = { "moderator" },
	run = function(context)
		return context.executor.Backpack:FindFirstChildWhichIsA "Tool"
	end,
	overloads = {
		{
			returns = "instance",
			args = {},
		},
	},
}

builtin_commands.tool = {
	description = "Creates an empty tool",
	permissions = { "moderator" },
	server_run = function(context)
		local name = context.args[1]
		local tool = Instance.new "Tool"
		tool.Name = name or "Tool"
		tool.RequiresHandle = false
		tool.Parent = context.executor.Backpack
		return tool
	end,
	overloads = {
		{ returns = "instance", args = { {
			name = "Name",
			type = "string",
		} } },

		{
			returns = "instance",
			args = {},
		},
	},
}

builtin_commands.time = {
	description = "Sets the time",
	permissions = { "moderator" },
	server_run = function(context)
		local hour = context.args[1] or 12
		local minute = context.args[2] or 0
		local second = context.args[3] or 0
		game:GetService("Lighting").ClockTime = hour + (minute / 60) + (second / 3600)
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Hour",
					type = "number",
				},
				{
					name = "Minute",
					type = "number",
				},
				{
					name = "Second",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Hour",
					type = "number",
				},
				{
					name = "Minute",
					type = "number",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Hour",
					type = "number",
				},
			},
		},
	},
}

builtin_commands.explosion = {
	description = "Creates an explosion at the position",
	permissions = { "moderator" },
	server_run = function(context)
		local pos = context.args[1]
		local explosion = Instance.new "Explosion"
		explosion.Position = pos
		explosion.Parent = workspace
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Position",
					type = "vector3",
				},
			},
		},
	},
}

builtin_commands.clear_inventory = {
	description = "Clears the inventory of players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local inventory = player.Backpack

			for _, item in inventory:GetChildren() do
				if item:IsA "Tool" then
					item:Destroy()
				end
			end
			local character = player.Character
			for _, item in character:GetChildren() do
				if item:IsA "Tool" then
					item:Destroy()
				end
			end
		end
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Target",
			type = "players",
		} } },
	},
}

builtin_commands.target = {
	description = "Returns the target of the mouse",
	permissions = { "moderator" },
	run = function(context)
		local mouse = Players.LocalPlayer:GetMouse()
		return mouse.Target
	end,
	overloads = {
		{
			returns = "instance",
			args = {},
		},
	},
}

builtin_commands.out = {
	description = "Returns the value of the nth result",
	permissions = {},
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

builtin_commands.view = {
	description = "Sets camera to view target",
	permissions = { "moderator" },
	run = function(context)
		local target = context.args[1]
		local camera = workspace.CurrentCamera
		camera.CameraSubject = target.Character.Humanoid
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Target",
					type = "player",
				},
			},
		},
	},
}

builtin_commands.destroy = {
	description = "Destroys an instance",
	permissions = { "admin" },
	server_run = function(context)
		local instance = context.args[1]
		if instance then
			instance:Destroy()
		end
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Instance",
					type = "instance",
				},
			},
		},
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.clone = {
	description = "Clones players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		local c
		for _, player in players do
			player.Character.Archivable = true
			c = player.Character:Clone()
			c.Parent = player.Character.Parent
		end
		return c
	end,
	overloads = {
		{
			returns = "model",
			args = {
				{
					name = "Targets",
					type = "players",
				},
			},
		},
		{
			returns = "model",
			args = {},
		},
	},
}

builtin_commands.teleport = {
	description = "Teleports players",
	alias = { "tp" },
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1]
		local pos
		if typeof(context.args[2]) == "Instance" then
			pos = context.args[2].Character:GetPivot()
		else
			pos = CFrame.new(context.args[2])
		end

		for _, player in players do
			if player.Character then
				player.Character:PivotTo(pos)
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
		{
			returns = "nil",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Position",
					type = "vector3",
				},
			},
		},
	},
}

builtin_commands.userid = {
	description = "Returns the userid of the player",
	permissions = { "moderator" },
	run = function(context)
		local player = context.args[1] or context.executor
		return player.UserId
	end,
	overloads = {
		{
			returns = "number",
			args = {
				{
					name = "Target",
					type = "player",
				},
			},
		},
		{
			returns = "number",
			args = {},
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
		Players.LocalPlayer.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 2, 0)))
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.vector3 = {
	description = "Creates a vector3 from components",
	permissions = { "moderator" },
	run = function(context)
		local x = context.args[1]
		local y = context.args[2]
		local z = context.args[3]
		return Vector3.new(x, y, z)
	end,
	overloads = {
		{
			returns = "vector3",
			args = {
				{
					name = "X",
					type = "number",
				},
				{
					name = "Y",
					type = "number",
				},
				{
					name = "Z",
					type = "number",
				},
			},
		},
	},
}

builtin_commands.add = {
	description = "Adds numbers ",
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

builtin_commands.add_vec3 = {
	description = "Adds vector3",
	permissions = { "math" },
	run = function(context)
		local sum = Vector3.zero
		for _, arg in context.args do
			sum = sum + arg
		end
		return sum
	end,
	overloads = {
		{
			returns = "vector3",
			args = { {
				name = "Value",
				type = "vector3",
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

builtin_commands["table"] = {
	description = "Constructs a table from arguments",
	permissions = { "math" },
	run = function(context)
		local t = {}
		for _, arg in context.args do
			table.insert(t, arg)
		end
		return t
	end,
	overloads = {
		{
			returns = "table",
			args = {},
		},
		{
			returns = "table",
			args = {
				{
					name = "Arguments",
					type = "any",
				},
			},
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

builtin_commands["nil"] = {
	description = "Returns nil",
	permissions = { "math" },
	run = function(context)
		return nil
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.length = {
	description = "Returns the length of a table",
	permissions = { "math" },
	run = function(context)
		return #context.args[1]
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Table",
				type = "table",
			} },
		},
	},
}

builtin_commands["set"] = {
	description = "Sets a variable",
	permissions = { "moderator" },
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

builtin_commands.increment = {
	description = "Increments a variable",
	permissions = { "moderator" },
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

builtin_commands["get"] = {
	description = "Gets a variable",
	permissions = { "moderator" },
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

builtin_commands["repeat"] = {
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

builtin_commands["while"] = {
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

builtin_commands.class_name = {
	description = "Gives the class name of an instance",
	permissions = { "admin" },
	run = function(context)
		return context.args[1].ClassName
	end,
	overloads = {
		{
			returns = "string",
			args = { {
				name = "Instance",
				type = "instance",
			} },
		},
	},
}

builtin_commands.number = {
	description = "Creates a number",
	permissions = { "math" },
	run = function(context)
		return context.args[1]
	end,
	overloads = {
		{
			returns = "number",
			args = {
				{
					name = "Number",
					type = "number",
				},
			},
		},
	},
}

builtin_commands.to_string = {
	description = "Converts number to string",
	permissions = { "math" },
	run = function(context)
		return tostring(context.args[1])
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "Number",
					type = "number",
				},
			},
		},
	},
}

builtin_commands.string = {
	description = "Creates a string",
	permissions = { "math" },
	run = function(context)
		return context.args[1]
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
			},
		},
	},
}

builtin_commands.player = {
	description = "Interprets value as a player",
	permissions = { "moderator" },
	run = function(context)
		return context.args[1] or context.executor
	end,
	overloads = {
		{
			returns = "player",
			args = {
				{
					name = "Player",
					type = "player",
				},
			},
		},
		{
			returns = "player",
			args = {},
		},
	},
}

builtin_commands.character = {
	description = "Returns a player's character",
	permissions = { "moderator" },
	run = function(context)
		return context.args[1] or context.executor.Character
	end,
	overloads = {
		{
			returns = "character",
			args = {
				{
					name = "Player",
					type = "player",
				},
			},
		},
		{
			returns = "character",
			args = {},
		},
	},
}

builtin_commands.parent = {
	description = "Returns the parent of an instance",
	permissions = { "admin" },
	run = function(context)
		return context.args[1].Parent
	end,
	overloads = {
		{
			returns = "instance",
			args = {
				{
					name = "Instance",
					type = "instance",
				},
			},
		},
	},
}

builtin_commands.humanoid = {
	description = "Returns a character's humanoid",
	permissions = { "moderator" },
	run = function(context)
		return context.args[1]:FindFirstChildOfClass "Humanoid"
	end,
	overloads = {
		{
			returns = "humanoid",
			args = {
				{
					name = "Character",
					type = "model",
				},
			},
		},
	},
}

builtin_commands.move_to = {
	description = "Makes a character move to a position",
	permissions = { "moderator" },
	server_run = function(context)
		local humanoid
		if context.args[1] then
			if context.args[1]:IsA "Player" then
				humanoid = context.args[1].Character:FindFirstChildOfClass "Humanoid"
			elseif context.args[1]:IsA "Model" then
				humanoid = context.args[1]:FindFirstChildOfClass "Humanoid"
			end
		else
			humanoid = context.executor.Character:FindFirstChildOfClass "Humanoid"
		end
		local position = context.args[2]
		humanoid:MoveTo(position)
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Player",
					type = "player",
				},
				{
					name = "Position",
					type = "vector3",
				},
			},
		},
		{
			returns = "nil",
			args = {
				{
					name = "Character",
					type = "Model",
				},
				{
					name = "Position",
					type = "vector3",
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

builtin_commands.substring = {
	description = "Returns a substring",
	permissions = { "math" },
	run = function(context)
		return string.sub(context.args[1], context.args[2], context.args[3])
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
				{
					name = "Start",
					type = "number",
				},
				{
					name = "End",
					type = "number",
				},
			},
		},
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
				{
					name = "Start",
					type = "number",
				},
			},
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

builtin_commands.bind = {
	description = "Binds a function to a key",
	permissions = { "moderator" },
	run = function(context)
		table.insert(context.process.bindings, {
			key = context.args[1],
			func = context.args[2],
		})
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

builtin_commands.player_cframe = {
	alias = { "plrcf" },
	description = "Returns the cframe of the player",
	permissions = { "debug", "moderator" },
	run = function(context)
		local plr = context.args[1] or game.Players.LocalPlayer
		local cframe = plr.Character:GetPivot()
		return cframe
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

builtin_commands.player_position = {
	alias = { "plrpos" },
	description = "Returns the position of the player",
	permissions = { "debug", "moderator" },
	run = function(context)
		local plr = context.args[1] or game.Players.LocalPlayer
		local pos = plr.Character:GetPivot().Position
		return pos
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
