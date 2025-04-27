local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ui = require(script.ui)
local runtime = require(script.runtime)
local types = require(script.types)
local builtins = require(script.builtins)
local util = require(script.util)

type PowClient = types.PowClient
type Type = types.Type
type Config = types.Config
type PartialConfig = types.PartialConfig

function reload_commands(functions_namespace, commands_to_register, user_permissions)
	functions_namespace.functions = {}
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

	return functions_namespace
end

function init_client(config_: PartialConfig?)
	local remote
	if config_ == nil then
		remote = ReplicatedStorage:WaitForChild "Pow"
		if not remote or not remote:IsA "RemoteFunction" then
			error "can't find pow remote"
			return
		end
		config_ = remote:InvokeServer "get_config"
		print("get_config", config_)
	end
	if config_ == nil then
		config_ = {}
	end

	local config = config_ :: Config

	local registered_types = table.clone(builtins.builtin_types)
	local commands_to_register = { builtins.builtin_commands }
	local functions_namespace = { type = "namespace", functions = {} }

	local client_requests: { [string]: (...any) -> any } = {}

	local state = { tabs = {} } :: PowClient

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

	reload_commands(functions_namespace, commands_to_register, config.user_permissions)

	remote.OnClientInvoke = function(type, data)
		if type == "client_request" then
			local func = client_requests[data.type]
			if func then
				return func(unpack(data.args))
			else
				error("no client request " .. data.type)
			end
		elseif type == "run_command" then
			local process = state.tabs[state.current_tab]
			if data["function"] then
				if data["function"].type == "custom_command" then
					process:run_command_ast(data["function"])
				else
					error "cant"
				end
			elseif data.command_text then
				process:run_command(data.command_text)
			end
		elseif type == "config_updated" then
			config.user_permissions = data.user_permissions
			config.permissions = data.permissions

			reload_commands(functions_namespace, commands_to_register, config.user_permissions)
		end
		return
	end

	local function new_process()
		local process = runtime.new_process()
		process.config = config
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
		current_process:run_command(command_text)
		state.ui.update(state)
	end

	local process = new_process()
	process.logs = {
		{
			type = "info",
			value = "<b>Pow - Press ESC to close</b>",
		},
	}
	state.ui = ui.init_ui(state)

	if extras and extras.auto_run then
		for _, command in extras.auto_run do
			state.submit_command(command)
		end
	end

	print "Pow loaded"
end

return {
	init_client = init_client,
}
