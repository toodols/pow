local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"
local DataStoreService = game:GetService "DataStoreService"

local shared = script.shared
local util = require(script.shared.util)
local runtime = require(script.shared.runtime)
local types = require(script.shared.types)

type PartialConfig = types.PartialConfig
type Config = types.Config
type Process = types.Process

function load_permissions(config: Config)
	if config.disable_data_store then
		return
	end
	local data_store = DataStoreService:GetDataStore(config.data_store_key or "pow_default_data_store_key", "v0")

	local permissions = data_store:GetAsync "permissions"
	if permissions then
		for permission, ranks in permissions do
			if permission == "root" or permission == "normal" then
				continue
			end
			for userid, rank in ranks do
				local cur_permission, cur_rank = util.get_user_permission_and_rank(config.permissions, userid)
				if cur_permission == "normal" or cur_permission == permission and cur_rank < rank then
					config.permissions[permission] = config.permissions[permission] or {}
					config.permissions[permission][userid] = rank
				end
			end
		end
	end
end

function init(config_: PartialConfig)
	local remote = Instance.new "RemoteFunction"
	remote.Parent = ReplicatedStorage
	remote.Name = "Pow"

	-- have the remote ready before requiring builtins
	local builtins = require(script.shared.builtins)

	local config = config_ :: Config
	if config == nil then
		config = {}
	end
	if config.permissions == nil then
		config.permissions = {}
	end

	local shared_root = ReplicatedStorage:FindFirstChild "pow"
	if shared_root == nil then
		shared_root = shared:Clone()
		shared_root.Parent = ReplicatedStorage
		shared_root.Name = "pow"
	end

	if config.extras then
		config.replicated_extras = config.extras:Clone()
		config.replicated_extras.Parent = shared_root
		config.replicated_extras.Name = "replicated_extras"
	end

	load_permissions(config)

	local commands = {}
	for name, command in builtins.builtin_commands do
		local id = name
		util.normalize_function(command, id)
		command.id = id
		commands[name] = command
	end

	local extras = require(config.extras)()
	if extras.commands then
		for name, command in extras.commands do
			local id = name
			util.normalize_function(command, id)
			command.id = id
			commands[name] = command
		end
	end

	local registered_types = table.clone(builtins.builtin_types)
	if extras.types then
		for name, type in extras.types do
			registered_types[name] = type
		end
	end

	config.permission_types = {}
	if extras.permission_types then
		for name, type in extras.permission_types do
			config.permission_types[name] = type
		end
	end
	for name, type in builtins.builtin_permission_types do
		config.permission_types[name] = type
	end

	config.expanded_permission_types = util.expand_permissions(config.permission_types)

	remote.OnServerInvoke = function(player, type, data)
		local user_permission = util.get_user_permission_and_rank(config.permissions, player.UserId)
		local user_expanded_permission = config.expanded_permission_types[user_permission]
		if type == "get_config" then
			return util.serialize_config(config, user_permission)
		elseif type == "telemetry" then
			print "got telemetry"
		elseif type == "server_run" then
			local command = commands[data.function_id]
			if not command then
				return { err = `server: command {data.function_id} not found` }
			end
			if command.permissions and not util.has_permission(command.permissions, user_expanded_permission) then
				return { err = `server: insufficient permission` }
			end

			local coerced_res =
				runtime.coerce_args(data.args, command.overloads, { types = registered_types } :: Process)

			if coerced_res.err then
				return { err = "server: " .. coerced_res.err }
			end
			if coerced_res.ok == nil then
				return { err = "server: no overload found" }
			end
			if command.server_run == nil then
				return { err = "server: no server_run" }
			end

			local success, result = pcall(function()
				return command.server_run {
					remote = remote,
					executor = player,
					args = coerced_res.ok,
					client_data = data.client_data,
					config = config,
				}
			end)
			if success then
				return { ok = result }
			else
				return { err = "server: " .. result }
			end
		end
		return nil
	end

	local pow_client = script.pow_client
	pow_client.Parent = StarterPlayer.StarterPlayerScripts
end

return { init = init }
