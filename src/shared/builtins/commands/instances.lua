-- Instance manipulation commands
local Players = game:GetService "Players"

local commands = {}
commands.class_name = {
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

commands.player = {
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

commands.character = {
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

commands.parent = {
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

commands.humanoid = {
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

commands.move_to = {
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
					type = "model",
				},
				{
					name = "Position",
					type = "vector3",
				},
			},
		},
	},
}

commands.equipped = {
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

commands.target = {
	description = "Returns the target of the mouse",
	permissions = { "moderator" },
	client_run = function(context)
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
commands.destroy = {
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

commands.player_cframe = {
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

commands.player_position = {
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

commands.userid = {
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

commands.hit = {
	description = "Returns the CFrame under the mouse",
	permissions = { "moderator" },
	client_run = function(context)
		return context.executor:GetMouse().Hit
	end,
	overloads = {
		{
			returns = "cframe",
			args = {},
		},
	},
}

return commands
