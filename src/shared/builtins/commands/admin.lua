local Players = game:GetService "Players"
local InsertService = game:GetService "InsertService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local DataStoreService = game:GetService "DataStoreService"

local util = require(script.Parent.Parent.Parent.util)
local types = require(script.Parent.Parent.Parent.types)
type Config = types.Config

local pow_remote = ReplicatedStorage:FindFirstChild "Pow"

local commands = {}
commands.view_permissions = {
	description = "Display all permissions.",
	permissions = { "view_permissions" },
	server_run = function(context)
		return context.process.config.permissions
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

local function save_user_permission(config: Config, userid: number)
	if config.disable_data_store then
		return
	end
	local permission, rank = util.get_user_permission_and_rank(config.permissions, userid)
	if permission == "root" or permission == "normal" then
		return
	end

	local data_store = DataStoreService:GetDataStore(config.data_store_key or "pow_default_data_store_key", "v0")
	local succ, err = pcall(function()
		data_store:UpdateAsync("permissions", function(value)
			value = value or config.permissions
			util.set_permission(value, userid, permission, rank)
			return value
		end)
	end)
	if not succ then
		print("updating permissions failed with error", err)
	end
end

commands.set_permission = {
	description = "Sets a player's permission.\n<b>Setting your own permission will permanently change it unless it is hard coded</b>",
	permissions = { "admin" },
	server_run = function(context)
		local executor = context.executor
		local target: Player = context.args[1]
		if not util.compare_ranks(context.process.config.permissions, executor, target) then
			error "You can't set this player's permission"
		end

		local target_permission = context.args[2]
		local executor_permission =
			util.get_user_permission_and_rank(context.process.config.permissions, executor.UserId)

		if
			not util.has_permission(
				{ target_permission },
				context.process.config.expanded_permission_types[executor_permission]
			)
		then
			error "You can't set this permission"
		end

		local rank = context.args[3]
		if not util.compare_ranks(context.process.config.permissions, executor, rank) then
			error "You can't set this rank"
		end
		util.set_permission(context.process.config.permissions, target.UserId, target_permission, rank)
		save_user_permission(context.process.config, target.UserId)

		local player_permission = util.get_user_permission_and_rank(context.process.config.permissions, target.UserId)
		-- print("context.process.config", context.process.config)
		-- print("player_permission", player_permission)
		pow_remote:InvokeClient(
			target,
			"config_updated",
			util.serialize_config(context.process.config, player_permission)
		)
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Target",
					type = "player",
				},
				{
					name = "Permission",
					type = "permission",
				},
				{
					name = "Rank",
					type = "number",
				},
			},
		},
	},
}

commands.ban = {
	description = "Ban players",
	permissions = { "admin" },
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Players",
					type = "players",
				},
				{
					name = "Duration",
					type = "number",
					description = "Duration of the ban, in seconds. Permanent bans should have a value of <b>-1</b>. <b>0</b> and all other negative values are invalid",
				},
				{
					name = "Display Reason",
					description = "The message that will be displayed to users when they attempt to and fail to join an experience. Maximum string length is <b>400</b>",
					type = "string",
				},
				{
					name = "Private Reason",
					description = "Internal messaging that will be returned when querying the user's ban history. Maximum string length is <b>1000</b>.",
					type = "string",
				},
				{
					name = "Exclude Alt Accounts",
					description = "When <b>true</b>, Roblox does not attempt to ban alt accounts.",
					type = "boolean",
				},
			},
		},
	},
	server_run = function(context)
		local user_ids = {}
		for _, player in context.args[1] do
			table.insert(user_ids, player.UserId)
		end
		Players:BanAsync {
			UserIds = user_ids,
			Duration = context.args[2],
			DisplayReason = context.args[3],
			PrivateReason = context.args[4],
			ExcludeAltAccounts = context.args[5],
		}
	end,
}

commands.unban = {
	description = "Unban players",
	permissions = { "admin" },
	overloads = {
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
	server_run = function(context)
		local user_ids = {}
		for _, player in context.args[1] do
			table.insert(user_ids, player.UserId)
		end
		Players:UnbanAsync {
			UserIds = user_ids,
		}
	end,
}

commands.morph_user = {
	description = "Morph as a user",
	permissions = { "moderator" },
	overloads = {
		{
			returns = "morph",
			args = {
				{
					name = "Players",
					type = "players",
				},
				{
					name = "User Id",
					type = "number",
				},
			},
		},
	},
	server_run = function(context)
		local description = Players:GetHumanoidDescriptionFromUserId(context.args[2])
		for _, player in context.args[1] do
			player.Character:FindFirstChildOfClass("Humanoid"):ApplyDescription(description)
		end
	end,
}

commands.fly = {
	description = "Fly",
	permissions = { "moderator" },
	overloads = {
		{
			returns = "nil",
			args = {},
		},
		{
			returns = "nil",
			args = {
				{ name = "Players", type = "players" },
			},
		},
	},
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			pow_remote:InvokeClient(player, "client_request", {
				type = "set_flying",
				args = { true },
			})
		end
	end,
}

commands.unfly = {
	description = "Unfly",
	permissions = { "moderator" },
	overloads = {
		{
			returns = "nil",
			args = {},
		},
		{
			returns = "nil",
			args = {
				{ name = "Players", type = "players" },
			},
		},
	},
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			pow_remote:InvokeClient(player, "client_request", {
				type = "set_flying",
				args = { false },
			})
		end
	end,
}

commands.scale = {
	description = "Scales up a player",
	permissions = { "moderator" },
	server_run = function(context)
		for _, plr in context.args[1] do
			local humanoid: Humanoid = plr.Character:FindFirstChildOfClass "Humanoid"
			local description = humanoid:GetAppliedDescription()
			description.HeadScale = context.args[2]
			description.HeightScale = context.args[3]
			description.DepthScale = context.args[4]
			description.WidthScale = context.args[5]
			humanoid:ApplyDescription(description)
		end
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Targets",
					type = "players",
				},
				{
					name = "Head Scale",
					type = "number",
				},
				{
					name = "Height Scale",
					type = "number",
				},
				{
					name = "Depth Scale",
					type = "number",
				},
				{
					name = "Width Scale",
					type = "number",
				},
			},
		},
	},
}

commands.spy = {
	description = "Spys on a player's processes",
	permissions = { "admin" },
	server_run = function(context)
		if not util.compare_ranks(context.process.config.permissions, context.executor, context.args[1]) then
			error "You can't spy on this player"
		end
		return context.process.server.user_processes[context.args[1]]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Target",
					type = "player",
				},
			},
		},
	},
}

commands.sudo = {
	description = "Runs a command as another player",
	permissions = { "admin" },
	server_run = function(context)
		if not util.compare_ranks(context.process.config.permissions, context.executor, context.args[1]) then
			error "You can't use sudo on this player"
		end
		local result = pow_remote:InvokeClient(context.args[1], "run_command", {
			["function"] = context.args[2],
		})
		if result.ok then
			return result.ok
		else
			return "Error: " .. result.err
		end
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{
					name = "Target",
					type = "player",
				},
				{
					name = "Command",
					type = "function",
				},
			},
		},
	},
}

commands.kill = {
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

-- commands.leaderstat = {
-- 	description = ""
-- }

commands.gear = {
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

commands.to = {
	description = "Teleports you to a player",
	permissions = { "moderator" },
	run = function(context)
		local player = context.args[1]
		context.executor.Character:PivotTo(player.Character:GetPivot())
	end,
	overloads = {
		{ returns = "nil", args = { {
			name = "Target",
			type = "player",
		} } },
	},
}

commands.unlock = {
	description = "Unlocks players",
	permissions = { "moderator" },
	server_run = function(context)
		local players = context.args[1] or { context.executor }
		for _, player in players do
			local character = player.Character
			for _, part in character:GetDescendants() do
				if part:IsA "BasePart" then
					part.Locked = false
				end
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

commands.respawn = {
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

commands.bring = {
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

commands.tool = {
	description = "Creates an empty tool",
	permissions = { "moderator" },
	server_run = function(context)
		local name = context.args[1]
		local tool = Instance.new "Tool"
		tool.Name = name or "Tool"
		tool.RequiresHandle = false
		tool.Parent = context.executor.Backpack
		if context.args[2] then
			local handle = Instance.new "Part"
			handle.Name = "Handle"
			handle.Parent = tool
			tool.CanBeDropped = true
		end
		return tool
	end,
	overloads = {
		{
			returns = "instance",
			args = {
				{
					name = "Name",
					type = "string",
				},
				{
					name = "Droppable",
					type = "boolean",
					optional = true,
				},
			},
		},

		{
			returns = "instance",
			args = {},
		},
	},
}

commands.time = {
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

commands.explosion = {
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

commands.clear_inventory = {
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
		{ returns = "nil", args = {} },
		{ returns = "nil", args = { {
			name = "Target",
			type = "players",
		} } },
	},
}

commands.clone = {
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

commands.teleport = {
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

commands.view = {
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

commands.kick = {
	description = "Kicks players",
	permissions = { "admin" },
	server_run = function(context)
		local players = context.args[1]
		for _, player in players do
			if util.compare_ranks(context.process.config.permissions, context.executor, player) then
				player:Kick(context.args[2])
			else
				error(`Cannot kick {player.Name}`)
			end
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

commands.walkspeed = {
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

commands.explode = {
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

commands.blink = {
	description = "Teleports to position under the mouse",
	permissions = { "moderator" },
	alias = { "b" },
	client_run = function(context)
		local mouse = Players.LocalPlayer:GetMouse()
		local pos = mouse.Hit.Position
		Players.LocalPlayer.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 2, 0)))
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

commands.through = {
	description = "Teleports to position after the mouse ",
	permissions = { "moderator" },
	alias = { "t" },
	client_run = function(context)
		local mouse = Players.LocalPlayer:GetMouse()
		local pos = mouse.Hit * CFrame.new(0, 0, -4)
		Players.LocalPlayer.Character:PivotTo(CFrame.new(pos.Position))
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

commands.jumppower = {
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

commands.unshirt = {
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

commands.shirt = {
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
		{
			returns = "nil",
			args = { {
				name = "Shirt Id",
				type = "number",
			} },
		},
	},
}

commands.forcefield = {
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

commands.unforcefield = {
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

commands.unpants = {
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

commands.backpack = {
	description = "Gets all items in a player's backpack",
	permissions = { "moderator" },
	overloads = {
		{
			returns = "table",
			args = {
				{
					name = "Player",
					type = "player",
				},
			},
		},
	},
	run = function(context)
		local backpack = context.args[1].Backpack
		return backpack:GetChildren()
	end,
}

commands.steal = {
	description = "Moves an item to your backpack",
	permissions = { "admin" },
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Tool",
				type = "instance",
			} },
		},
	},
	server_run = function(context)
		if not context.args[1]:IsA "Tool" then
			error "That's not a tool"
		end
		context.args[1].Parent = context.executor.Backpack
	end,
}

commands.pants = {
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
		{
			returns = "nil",
			args = { {
				name = "Pants Id",
				type = "number",
			} },
		},
	},
}

return commands
