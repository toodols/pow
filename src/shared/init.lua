local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local ui = require(script.ui)
local runtime = require(script.runtime)
local parser = require(script.parser)
local types = require(script.types)
local builtins = require(script.builtins)
local util = require(script.util)

local local_player = Players.LocalPlayer

type PowClient = types.PowClient
type Type = types.Type
type Config = types.Config
type PartialConfig = types.PartialConfig

function init_client(config_: PartialConfig?)
	local remote
	if config_ == nil then
		remote = ReplicatedStorage:FindFirstChild "Pow"
		if not remote or not remote:IsA "RemoteFunction" then
			return
		end
		config_ = remote:InvokeServer "get_config"
		print("get_config", config_)
	end
	if config_ == nil then
		config_ = {}
	end

	local config = config_ :: Config
	local user_permissions = config.user_permissions

	local registered_types = table.clone(builtins.builtin_types)
	local commands_to_register = { builtins.builtin_commands }
	local functions_namespace = { type = "namespace", functions = {} }

	local client_requests: { [string]: (...any) -> any } = {}

	local extras
	if config.extras then
		extras = require(config.extras)()
		if extras.commands then
			table.insert(commands_to_register, extras.commands)
		end
		if extras.types then
			for name, type in extras.types do
				registered_types[name] = type
			end
		end
		if extras.client_requests then
			for name, func in extras.client_requests do
				client_requests[name] = func
			end
		end
	end

	remote.OnClientInvoke = function(type, data)
		if type == "client_request" then
			local func = client_requests[data.type]
			if func then
				return func(unpack(data.args))
			else
				error("no client request " .. data.type)
			end
		end
	end

	for _, commands in commands_to_register do
		for name, command in commands do
			if command.permissions then
				if not util.has_permission(command.permissions, user_permissions) then
					continue
				end
			end
			util.normalize_function(command, name)
			functions_namespace.functions[name] = command

			if command.alias then
				for _, alias in command.alias do
					if functions_namespace.functions[alias] then
						error(`command {alias} already exists`)
					end
					functions_namespace.functions[alias] = command
				end
			end
		end
	end

	local state = { tabs = {} } :: PowClient
	local function new_process()
		local process = runtime.new_process()
		process.global_scope.functions = functions_namespace
		process.types = registered_types

		process.on_log_updated = function()
			state.ui.update(state)
		end
		state.tabs[process.id] = process
		state.current_tab = process.id
		return process
	end

	state.new_tab = function()
		local proc = new_process()
		state.ui.update(state)
	end
	state.remove_tab = function(id)
		state.tabs[id] = nil
		state.current_tab = next(state.tabs)
		if state.current_tab == nil then
			new_process()
		end
		state.ui.update(state)
	end
	state.select_tab = function(id)
		state.current_tab = id
		state.ui.update(state)
	end
	state.submit_command = function(command_text: string)
		local current_process = state.tabs[state.current_tab]
		local parse_success, result, parse_state = parser.parse(command_text)
		table.insert(current_process.history, command_text)
		table.insert(current_process.logs, {
			type = "input",
			value = command_text,
			at = tick(),
		})
		if parse_success then
			runtime.run_root_commands(current_process, result)
		else
			table.insert(current_process.logs, {
				type = "error",
				value = result,
				at = tick(),
			})
		end
		state.ui.update(state)
	end

	local process = new_process()
	process.logs = {
		{
			type = "info",
			value = "<b>Pow - Press ESC to close</b>",
		},
		{
			type = "info",
			value = "Hi leo!!",
		},
	}
	state.ui = ui.init_ui(state)

	if extras and extras.auto_run then
		for _, command in extras.auto_run do
			state.submit_command(command)
		end
	end
end

return {
	init_client = init_client,
}
