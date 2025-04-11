local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local parser = require(script.Parent.parser)
local types = require(script.Parent.types)
local typing = require(script.typing)

local local_player = Players.LocalPlayer

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

local id = 0
function new_process()
	local global_scope = new_scope()
	id += 1
	local process: Process = {
		id = tostring(id),
		name = "Tab " .. id,
		owner = Players.LocalPlayer,
		global_scope = global_scope,
		types = {},
		history = {},
		logs = {},
		on_log_updated = function() end,
	}
	return process
end

function new_scope(parent: Scope?): Scope
	return {
		functions = { type = "namespace", functions = {} },
		variables = {},
		parent = parent,
	}
end

function run_function(process: Process, fun: Function, args: { any }?): Result<any, string>
	if fun.type == "custom_function" then
		return run_commands(process, fun.commands, { args = args })
	elseif fun.type == "lua_function" then
		if fun.run then
			return run_lua_function(process, fun.run, args or {})
		elseif fun.server_run then
			local pow_remote = ReplicatedStorage.Pow
			local result =
				pow_remote:InvokeServer("server_run", { process_id = process.id, function_id = fun.id, args = args })
			return result
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
			return { err = "not found" }
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

function run_lua_function(process: Process, fn: (context: Context) -> any, args: { any }): Result<any, string>
	local context: Context = {
		process = process,
		args = args,
		executor = local_player,
		run_function = function(self, value: Function, args_: { any }?)
			run_function(process, value, args_)
		end,
		log = function(self, log: Log)
			table.insert(process.logs, log)
			process.on_log_updated()
		end,
		clear_logs = function(self)
			process.logs = {}
		end,
	}
	local success, err_or_res = pcall(fn, context)
	if success then
		return { ok = err_or_res }
	else
		return { err = err_or_res }
	end
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
	for _, arg in command.args do
		if arg.type == "subcall" then
			-- consideration
			-- if I have a function like this: { if (eq (var 1) 1) { print "first arg == 1" }}
			-- a subcall shouldn't have a new state and it should inherit the state from the parent
			local result = run_commands(process, arg.commands, state)
			if result.err == nil then
				table.insert(args, result.ok)
			else
				return result
			end
		else
			table.insert(args, typing.tag_expression(arg))
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
		return { err = "no overload found" }
	end
	return run_function(process, fun, coerced_res.ok)
end

function run_commands(process: Process, commands: Commands, state: State): Result<any, string>
	local result
	for _, command in commands.list do
		result = run_command(process, command, state)
		if result.err then
			return result
		end
	end
	return result
end

function run_root_commands(process: Process, commands: RootCommands)
	process.on_log_updated()

	local result = run_commands(process, commands, { args = {} })
	if result.ok ~= nil then
		table.insert(process.logs, {
			type = "output",
			value = tostring(result.ok),
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

return {
	new_scope = new_scope,
	new_process = new_process,
	run_root_commands = run_root_commands,
	find_function = find_function,
	coerce_args = typing.coerce_args,
	infer = typing.infer,
	tag_expression = typing.tag_expression,
}
