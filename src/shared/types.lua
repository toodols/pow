local parser = require(script.Parent.parser)
type Expression = parser.Expression
type Commands = parser.Commands

export type Log = {
	type: "input",
	-- from: Player,
	at: number,
	value: string,
} | {
	type: "output",
	at: number,
	value: Value,
} | {
	type: "error",
	at: number,
	value: string,
} | {
	type: "info",
	at: number,
	value: string,
}

export type Process = {
	id: string,
	name: string,
	owner: Player,
	bindings: { { key: Enum.KeyCode, command: Function } },
	global_scope: Scope,
	results: { any },
	types: { [string]: Type },
	logs: { Log },
	on_log_updated: () -> (),
	history: { string },
	parent: Process?,
	config: Config,
}

type Value = any

export type Suggestion = {
	text: string,
	replace_at: number,
	match_start: number,
	match_end: number,
	title: string?,
	description: string?,
	display_text: string?,
}

export type Type = {
	name: string,
	description: string?,
	coerce_expression: (Expression, Process) -> any,
	coerce_value: (any, Process) -> any,
	autocomplete: ((search: string, replace_at: number, process: Process) -> { Suggestion }) | { string } | nil,
}

export type Param = {
	name: string,
	description: string?,
	type: string,
	rest: boolean,
}

export type Overload = {
	args: { Param },
	returns: Type,
}

export type Function = {
	type: "custom_function",
	commands: Commands,
	-- description: string,
	-- overloads: { { args: { Param }, returns: Type } },
} | {
	type: "lua_function",
	id: string,
	run: ((Context) -> any)?,
	server_run: (({ args: { any } }) -> any)?,
	name: string?,
	description: string,
	overloads: { Overload }?,
}

export type FunctionNamespace = {
	type: "namespace",
	functions: {
		[string]: Function | FunctionNamespace,
	},
}

export type Scope = {
	functions: FunctionNamespace,
	variables: { [string]: Value },
	parent: Scope?,
}

export type Context = {
	process: Process,
	args: { any },
	run_function: (self: Context, fun: Function, args: { any }?) -> any,
	-- executor: Player,
}

export type State = {
	args: { any },
}

export type Tab = {
	id: string,
	name: string,
	process: Process,
}

export type PowClient = {
	tabs: { [string]: { name: string, process: Process } },
	current_tab: string,
	new_tab: () -> (),
	remove_tab: (id: string) -> (),
	select_tab: (id: string) -> (),
	submit_command: (command_text: string) -> (),
	ui: { update: (client: PowClient) -> () },
}

export type Result<T, E> = {
	ok: T,
} | {
	err: E,
}

export type Config = {
	permissions: {
		[string]: {
			[string]: number,
		},
	},
	user_permissions: { [string]: boolean },

	extras: Script?,
	data_store_key: string,
	disable_data_store: boolean?,

	-- derived
	expanded_permission_types: { [string]: { [string]: boolean } },
	replicated_extras: Script?,
}

export type PartialConfig = {
	permissions: {
		[string]: {
			[string]: number,
		},
	}?,
	user_permissions: { [string]: boolean }?,
	extras: Script?,
	data_store_key: string?,
	disable_data_store: boolean?,
}

return {}
