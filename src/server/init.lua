local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"
local DataStoreService = game:GetService "DataStoreService"
local Players = game:GetService "Players"

local shared = script.shared
local util = require(script.shared.util)
local runtime = require(script.shared.runtime)
local types = require(script.shared.types)

type PartialConfig = types.PartialConfig
type Config = types.Config
type Process = types.Process
type Log = types.Log

function load_permissions(config: Config, done: () -> nil)
	if config.disable_data_store then
		return
	end
	task.defer(function()
		local success, data_store = pcall(function()
			return DataStoreService:GetDataStore(config.data_store_key or "pow_default_data_store_key", "v0")
		end)
		if not success then
			return
		end
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

		done()
	end)
end

function init(config_: PartialConfig)
	local pow_client = script.pow_client
	pow_client.Parent = StarterPlayer.StarterPlayerScripts

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

	if config.extras_shared then
		local list = {}
		for _, extra in config.extras_shared do
			local cloned = extra:Clone()
			cloned.Parent = shared_root
			cloned.Name = "replicated_extras"
			table.insert(list, cloned)
		end
		config.replicated_extras_shared = list
	end

	if config.extras_client then
		for _, extra in config.extras_client do
			extra.Parent = shared_root
		end
	end

	load_permissions(config, function()
		for _, player in Players:GetPlayers() do
			local player_permission = util.get_user_permission_and_rank(config.permissions, player.UserId)
			remote:InvokeClient(player, "get_config", util.serialize_config(config, player_permission))
		end
	end)

	local functions_to_register = { builtins.builtin_commands }
	local functions_by_id: { [string]: any } = {}
	local functions_namespace = { type = "namespace", functions = {} }

	local extras: { commands: { [string]: any }, types: { [string]: any }, permission_types: { [string]: any } } =
		{ commands = {}, types = {}, permission_types = {}, client_requests = {} }

	if config.extras_shared then
		for _, extra in config.extras_shared do
			require(extra)(extras)
		end
	end

	local server_extras = { commands = {}, types = {}, permission_types = {} }
	if config.extras_server then
		for _, extra in config.extras_server do
			require(extra)(server_extras)
		end
	end
	table.insert(functions_to_register, extras.commands)
	table.insert(functions_to_register, server_extras.commands)

	util.reload_commands(functions_by_id, functions_namespace, functions_to_register)

	local server_functions_namespace = { type = "namespace", functions = {} }
	util.reload_commands({}, server_functions_namespace, { server_extras.commands })
	config.function_prototypes = server_functions_namespace

	local registered_types = table.clone(builtins.builtin_types)
	for name, type in extras.types do
		if registered_types[name] then
			error(`type {name} already exists`)
		end
		registered_types[name] = type
	end
	for name, type in server_extras.types do
		error "Do not add types in server extras"
	end

	config.permission_types = {}
	for name, type in extras.permission_types do
		if config.permission_types[name] == nil then
			config.permission_types[name] = {}
		end
		for _, inherited in type do
			table.insert(config.permission_types[name], inherited)
		end
	end
	for name, type in builtins.builtin_permission_types do
		if config.permission_types[name] == nil then
			config.permission_types[name] = {}
		end
		for _, inherited in type do
			table.insert(config.permission_types[name], inherited)
		end
	end
	for name, type in server_extras.permission_types do
		error "Do not add permission types in server extras"
	end

	config.expanded_permission_types = util.expand_permissions(config.permission_types)

	local server_process = runtime.new_process()
	server_process.config = config
	server_process.global_scope.functions = functions_namespace
	server_process.types = registered_types

	local user_processes: { [Player]: { [string]: Process } } = {}

	remote.OnServerInvoke = function(player, type, data)
		local user_permission = util.get_user_permission_and_rank(config.permissions, player.UserId)
		local user_expanded_permission = config.expanded_permission_types[user_permission]
		if type == "get_config" then
			return util.serialize_config(config, user_permission)
		elseif type == "telemetry" then
			user_processes[player] = data
		elseif type == "server_run" then
			local fun = functions_by_id[data.function_id]
			if not fun then
				return { err = `server: command {data.function_id} not found` }
			end
			if not util.has_permission(fun.permissions, user_expanded_permission) then
				return { err = `server: insufficient permission` }
			end

			local coerced_res = runtime.coerce_args(data.args, fun.overloads, { types = registered_types } :: Process)

			if coerced_res.err then
				return { err = "server: " .. coerced_res.err }
			end
			if coerced_res.ok == nil then
				return { err = "server: no overload found" }
			end

			local result = runtime.run_function(
				{
					id = data.process_id,
					config = server_process.config,
					global_scope = server_process.global_scope,
					owner = player,
					types = server_process.types,
					server = {
						user_processes = user_processes,
					},
				} :: Process,
				fun,
				coerced_res.ok,
				data.data
			)
			return result
		end
		return nil
	end
end

return { init = init }
