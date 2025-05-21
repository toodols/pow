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
	bindings: { [Enum.KeyCode]: Function },
	global_scope: Scope,
	results: { any },
	types: { [string]: Type },
	logs: { Log },
	on_log_updated: () -> (),
	history: { string },
	parent: Process?,
	server: any?,
	config: Config,
	destroy: () -> (),
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
	-- May be run in any context, at the convenience of the current "side"
	run: ((Context) -> any)?,
	-- Must be run in server, client will defer to server
	server_run: ((Context) -> any)?,
	-- Must be run in client, server will defer to client
	client_run: ((Context) -> any)?,
	name: string,
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
	executor: Player?,
	data: { any },
	args: { any },
	defer: () -> (),
}

export type State = {
	args: { any },
}

export type PowClient = {
	tabs: { [string]: Process },
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

	extras_shared: { ModuleScript }?,
	extras_client: { ModuleScript }?,
	extras_server: { ModuleScript }?,

	data_store_key: string,
	disable_data_store: boolean?,

	-- derived
	auto_run: { string },
	expanded_permission_types: { [string]: { [string]: boolean } },
	replicated_extras_shared: { ModuleScript }?,
	function_prototypes: FunctionNamespace,
}

export type PartialConfig = {
	permissions: {
		[string]: {
			[string]: number,
		},
	}?,
	user_permissions: { [string]: boolean }?,
	extras_shared: { ModuleScript }?,
	extras_client: { ModuleScript }?,
	extras_server: { ModuleScript }?,
	data_store_key: string?,
	disable_data_store: boolean?,
}

return {}
