local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local parser = require(script.Parent.parser)
local types = require(script.Parent.types)
local typing = require(script.typing)
local UserInputService = game:GetService "UserInputService"
local RunService = game:GetService "RunService"

type Commands = parser.Commands
type Command = parser.Command
type RootCommands = parser.RootCommands

type Log = types.Log
type Process = types.Process
type Scope = types.Scope
type Function = types.Function
type Param = types.Param
type Context = types.Context
type Type = types.Type
type State = types.State
type Result<T, E> = types.Result<T, E>

local runtime

local id = 0
function new_process()
	local global_scope = new_scope()
	id += 1
	local process: Process = {
		id = tostring(id),
		name = "Tab " .. id,
		owner = Players.LocalPlayer,
		global_scope = global_scope,
		results = {},
		types = {},
		config = {} :: any,
		history = {},
		bindings = {},
		logs = {},
		on_log_updated = function() end,
		destroy = function() end,
	}
	local conn = UserInputService.InputBegan:Connect(function(input_obj, game_processed)
		if game_processed then
			return
		end
		if process.bindings[input_obj.KeyCode] then
			run_function(process, process.bindings[input_obj.KeyCode], {})
		end
	end)
	process.destroy = function()
		conn:Disconnect()
	end
	return process
end

function new_scope(parent: Scope?): Scope
	return {
		functions = { type = "namespace", functions = {} },
		variables = {},
		parent = parent,
	}
end

function run_function(process: Process, fun: Function, args: { any }?, data: any?): Result<any, string>
	data = data or {}
	args = args or {}
	assert(args ~= nil and data ~= nil, "args cannot be nil")
	if fun.type == "custom_function" then
		return run_commands(process, fun.commands, { args = args })
	elseif fun.type == "lua_function" then
		if fun.run then
			return run_lua_function(process, fun.id, fun.run, args, data)
		elseif RunService:IsClient() then
			if fun.client_run then
				return run_lua_function(process, fun.id, fun.client_run, args, data)
			elseif fun.server_run ~= nil then
				local pow_remote = ReplicatedStorage.Pow
				local result = pow_remote:InvokeServer(
					"server_run",
					{ process_id = process.id, function_id = fun.id, args = args, data = data }
				)
				return result
			else
				return { err = "no run, client_run, or server_run found for function" }
			end
		elseif RunService:IsServer() then
			if fun.server_run then
				return run_lua_function(process, fun.id, fun.server_run, args, data)
			else
				local pow_remote = ReplicatedStorage.Pow
				return pow_remote:InvokeClient(process.owner, "client_run", {
					process_id = process.id,
					function_id = fun.id,
					args = args,
					data = data,
				})
			end
		end
	end
	error "unreachable"
end

function find_function(scope: Scope, path: string): Result<Function, string>
	while true do
		local value = find_function_in_current_scope(scope, path)
		if value.err then
			return value
		end
		if value.ok ~= nil then
			return value
		elseif scope.parent then
			scope = scope.parent
		else
			return { err = path .. " not found" }
		end
	end
end
function find_function_in_current_scope(scope: Scope, path: string): Result<Function?, string>
	local parts = string.split(path, ".")
	local current = scope.functions
	for _, part in parts do
		if current.type == "namespace" then
			if current.functions[part] then
				current = current.functions[part]
			else
				return { ok = nil }
			end
		else
			return { err = `not a namespace` }
		end
	end
	if current.type == "custom_function" or current.type == "lua_function" then
		return { ok = current }
	end
	return { err = "what" }
end

local global = {}
function run_lua_function(
	process: Process,
	fn_id: string,
	fn: (context: Context) -> any,
	args: { any },
	data: any
): Result<any, string>
	local context: Context = {
		global = global,
		process = process,
		args = args,
		executor = process.owner,
		data = data,
		runtime = runtime,
		log = function(self, log: Log)
			if RunService:IsClient() then
				table.insert(self.process.logs, log)
				self.process.on_log_updated()
			elseif RunService:IsServer() then
				local pow_remote = ReplicatedStorage.Pow
				pow_remote:InvokeClient(self.executor, "log", {
					process_id = self.process.id,
					log = log,
				})
			end
		end,
		-- defers a command to run on the server now
		defer = function(self)
			local pow_remote = ReplicatedStorage.Pow
			if RunService:IsClient() then
				return pow_remote:InvokeServer("server_run", {
					process_id = process.id,
					function_id = fn_id,
					data = self.data,
					args = args,
				})
			elseif RunService:IsServer() then
				return pow_remote:InvokeClient(self.executor, "client_run", {
					process_id = process.id,
					function_id = fn_id,
					data = self.data,
					args = args,
				})
			else
				error "unreachable"
			end
		end,
	}
	local success, err_or_res = pcall(fn, context)
	if success then
		return { ok = err_or_res }
	else
		return { err = err_or_res }
	end
end

function run_commands_string(process: Process, text: string): Result<any, string>
	local success, parse_result, parse_state = parser.parse(text)
	if not success then
		return { err = parse_result }
	end
	return run_commands(process, parse_result, { args = {} })
end

function run_command(process: Process, command: Command, state: State): Result<any, string>
	if command.type == "empty_command" then
		return { ok = nil }
	end

	local fun_res = find_function(process.global_scope, command.path)
	if fun_res.err then
		return fun_res
	end

	local fun = fun_res.ok
	local args = {}
	for i, arg in command.args do
		if arg.type == "subcall" then
			-- consideration
			-- if I have a function like this: { if (eq (var 1) 1) { print "first arg == 1" }}
			-- a subcall shouldn't have a new state and it should inherit the state from the parent
			local result = run_commands(process, arg.commands, state)
			if result.err == nil then
				args[i] = result.ok
			else
				return result
			end
		else
			args[i] = typing.tag_expression(arg)
		end
	end
	if fun.overloads == nil or #fun.overloads == 0 then
		fun.overloads = { {
			returns = "any",
			args = {
				{ type = "any", name = "arg", rest = true },
			},
		} }
	end
	local coerced_res = typing.coerce_args(args, fun.overloads, process)
	if coerced_res.err then
		return coerced_res
	end
	if coerced_res.ok == nil then
		return { err = "failed to coerce: ...??" }
	end
	return run_function(process, fun, coerced_res.ok)
end

function run_commands(process: Process, commands: Commands, state: State): Result<any, string>
	local result = { ok = nil } :: Result<any, string>
	for _, command in commands.list do
		result = run_command(process, command, state)
		if result.err then
			return result
		end
	end
	return result
end

function deep_copy(obj: any, visited: { [string]: any }, depth: number): any
	if depth > 10 then
		return "<error: max depth reached>"
	end
	if type(obj) == "table" then
		if visited[tostring(obj)] then
			return visited[tostring(obj)]
		end
		local copy = {}
		visited[tostring(obj)] = copy
		for key, value in obj do
			copy[key] = deep_copy(value, visited, depth + 1)
		end
		return copy
	else
		return obj
	end
end

function run_user_command(process: Process, text: string)
	table.insert(process.history, text)
	table.insert(process.logs, {
		type = "input",
		value = text,
		at = tick(),
	})
	process.on_log_updated()
	local success, parse_result, parse_state = parser.parse(text)
	if not success then
		table.insert(process.logs, {
			type = "error",
			value = parse_result,
			at = tick(),
		})
		return
	end

	local result = run_commands(process, parse_result, { args = {} })
	if result.ok ~= nil then
		table.insert(process.results, result.ok)

		table.insert(process.logs, {
			type = "output",
			value = deep_copy(result.ok, {}, 0),
			index = #process.results,
			at = tick(),
		})
	elseif result.err then
		table.insert(process.logs, {
			type = "error",
			value = result.err,
			at = tick(),
		})
	end
end

runtime = {
	new_scope = new_scope,
	new_process = new_process,
	run_user_command = run_user_command,
	run_commands = run_commands,
	run_commands_string = run_commands_string,
	run_function = run_function,
	find_function = find_function,
	coerce_args = typing.coerce_args,
	infer = typing.infer,
	tag_expression = typing.tag_expression,
}

return runtime
