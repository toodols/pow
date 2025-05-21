local ReplicatedStorage = game:GetService "ReplicatedStorage"

local parser = require(script.parser)
local ui = require(script.ui)
local runtime = require(script.runtime)
local types = require(script.types)
local builtins = require(script.builtins)
local util = require(script.util)

type PowClient = types.PowClient
type Type = types.Type
type Config = types.Config
type PartialConfig = types.PartialConfig

function init_client(config_: PartialConfig?)
	local remote
	if config_ == nil then
		remote = ReplicatedStorage:WaitForChild "Pow"
		if not remote or not remote:IsA "RemoteFunction" then
			error "can't find pow remote"
			return
		end
		config_ = remote:InvokeServer "get_config"
	end
	if config_ == nil then
		config_ = {}
	end

	local config = config_ :: Config

	local registered_types = table.clone(builtins.builtin_types)
	local commands_to_register = { builtins.builtin_commands }
	local functions_namespace = { type = "namespace", functions = {} }
	local functions_by_id = {}

	local client_requests: { [string]: (...any) -> any } = {}

	local state = { tabs = {} } :: PowClient

	local extras = { commands = {}, types = {}, client_requests = client_requests }
	if config.extras_client then
		for _, client_extra in config.extras_client do
			require(client_extra)(extras)
		end
	end
	if config.extras_shared then
		for _, shared_extra in config.extras_shared do
			require(shared_extra)(extras)
		end
	end

	for name, type in extras.types do
		if registered_types[name] then
			error("type " .. name .. " already registered")
		end
		registered_types[name] = type
	end

	table.insert(commands_to_register, extras.commands)

	util.reload_commands(functions_by_id, functions_namespace, commands_to_register, config.user_permissions)
	util.apply_prototypes(functions_by_id, functions_namespace, config.function_prototypes, config.user_permissions)

	remote.OnClientInvoke = function(type, data)
		if type == "client_request" then
			local func = client_requests[data.type]
			if func then
				return func(unpack(data.args))
			else
				error("no client request " .. data.type)
			end
		elseif type == "client_run" then
			local process = state.tabs[state.current_tab]
			local fun = functions_by_id[data.function_id]
			return runtime.run_function(process, fun, data.args, data.data)
		elseif type == "log" then
			local process = state.tabs[data.process_id]
			table.insert(process.logs, data.log)
			state.ui.update(state)
		-- this is for sudo where the process is unknown
		elseif type == "run_command" then
			local process = state.tabs[state.current_tab]
			if data["function"] then
				if data["function"].type == "custom_function" then
					return runtime.run_commands(process, data["function"].commands, { args = {} })
				else
					return { err = "what" }
				end
			elseif data.command_text then
				return runtime.run_commands_string(process, data.command_text)
			end
		elseif type == "config_updated" then
			config.user_permissions = data.user_permissions
			config.permissions = data.permissions

			util.reload_commands(functions_by_id, functions_namespace, commands_to_register, config.user_permissions)
			util.apply_prototypes(
				functions_by_id,
				functions_namespace,
				config.function_prototypes,
				config.user_permissions
			)
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
		runtime.run_user_command(current_process, command_text)
		local processes = {}
		for id, proc in state.tabs do
			processes[id] = {
				id = id,
				name = proc.name,
				logs = proc.logs,
				history = proc.history,
				global_scope = {
					variables = proc.global_scope.variables,
				},
			}
		end
		remote:InvokeServer("telemetry", processes)
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

	if config.auto_run then
		for _, command in config.auto_run do
			state.submit_command(command)
		end
	end
end

return {
	init_client = init_client,
}
