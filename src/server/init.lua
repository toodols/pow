local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"
local shared = script.shared
local builtins = require(script.shared.builtins)
local util = require(script.shared.util)
local runtime = require(script.shared.runtime)
local types = require(script.shared.types)

type PartialConfig = types.PartialConfig
type Config = types.Config
type Process = types.Process

function init(config_: PartialConfig)
	local remote = Instance.new "RemoteFunction"
	remote.Parent = ReplicatedStorage
	remote.Name = "Pow"

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

	local extras_script
	if config.extras then
		extras_script = config.extras:Clone()
		extras_script.Parent = ReplicatedStorage
	end

	local registered_types = table.clone(builtins.builtin_types)

	local expanded_permission_types = util.expand_permissions(builtins.builtin_permission_types)

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

	if extras.types then
		for name, type in extras.types do
			registered_types[name] = type
		end
	end

	remote.OnServerInvoke = function(player, type, data)
		local user_permission = util.get_user_permission_and_rank(config.permissions, player.UserId)
		local user_expanded_permission = expanded_permission_types[user_permission]
		if type == "get_config" then
			return {
				user_permissions = user_expanded_permission,
				extras = extras_script,
			}
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
