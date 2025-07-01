local types = require(script.Parent.types)
type Config = types.Config
type Suggestion = types.Suggestion

function expand_permissions(permissions: { [string]: { string } })
	local expanded = {}

	local function resolve(key, visited)
		if expanded[key] then
			return expanded[key]
		end

		visited = visited or {}
		visited[key] = true
		local result = { [key] = true }

		for _, dep in (permissions[key] or {} :: { string }) do
			if not visited[dep] then
				local sub_result = resolve(dep, visited)
				for k in sub_result do
					result[k] = true
				end
			end
		end

		expanded[key] = result
		return result
	end

	for key in permissions do
		resolve(key)
	end

	for key in permissions do
		expanded.root[key] = true
	end

	return expanded
end

function set_permission(
	permissions: { [string]: { [string]: number } },
	userid: number,
	permission: string,
	rank: number
)
	-- find and remove user from permissions
	for p, entries in permissions do
		if entries[tostring(userid)] ~= nil then
			permissions[p][tostring(userid)] = nil
		end
	end
	-- add user to permission
	permissions[permission] = permissions[permission] or {}
	permissions[permission][tostring(userid)] = rank
end

-- {[Permission]: {[UserId]: Rank}}
function get_user_permission_and_rank(permissions: { [string]: { [string]: number } }, user: number): (string, number)
	for permission, entries in permissions do
		for userid, entry in entries do
			if tonumber(user) == tonumber(userid) then
				return permission, entry
			end
		end
	end
	return "normal", 0
end

function has_permission(required: { string }, has: { [string]: boolean }): boolean
	for _, permission in required do
		if has[permission] == false then
			return false
		elseif has[permission] == nil then
			return false
			-- error("cant find this permission " .. permission)
		end
	end
	return true
end

function normalize_function(command, name)
	command.type = "lua_function"
	command.name = name
	command.id = name
	if command.permissions == nil then
		warn(`command {name} has no explicit permissions. Defaulting to none`)
		command.permissions = {}
	end
	if command.overloads == nil then
		warn(`command {name} has no explicit overloads. Defaulting to any`)
		command.overloads = {
			{
				returns = "any",
				args = { {
					name = "any",
					type = "any",
					rest = true,
				} },
			},
		}
	end
end

-- a root player outranks everyone, as well as itself
function compare_ranks(permissions, player1: Player, player2: Player | number): boolean
	if player1 == player2 then
		return true
	end
	local player1_permission, player1_rank = get_user_permission_and_rank(permissions, player1.UserId)

	local player2_rank
	local player2_permission
	if type(player2) == "number" then
		player2_rank = player2
	else
		player2_permission, player2_rank = get_user_permission_and_rank(permissions, player2.UserId)
	end
	return player1_permission == "root" or (player2_permission ~= "root") and player1_rank > player2_rank
end

function serialize_config(config: Config, user_permission: string)
	local serialized_config = {
		user_permissions = config.expanded_permission_types[user_permission],
		extras_shared = config.replicated_extras_shared,
		extras_client = config.extras_client,
		function_prototypes = config.function_prototypes,
	}
	if has_permission({ "view_permissions" }, config.expanded_permission_types[user_permission]) then
		serialized_config.permissions = config.permissions
	end
	return serialized_config
end

function deep_equal(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) == "table" then
		if #a ~= #b then
			return false
		end
		for k, v in a do
			if not deep_equal(v, b[k]) then
				return false
			end
		end
		return true
	end
	return a == b
end

function reload_commands(functions_by_id, functions_namespace, commands_to_register, user_permissions: any?)
	functions_namespace.functions = {}
	for _, commands in commands_to_register do
		for name, command in commands do
			if command.type == "namespace" then
				error "todo: namespace"
			end
			if command.permissions and user_permissions then
				if not has_permission(command.permissions, user_permissions) then
					continue
				end
			end
			normalize_function(command, name)
			if functions_by_id[name] then
				local original = functions_by_id[name]
				command = original
			else
				functions_by_id[name] = command
			end
			functions_namespace.functions[name] = command
			if command.alias then
				for _, alias in command.alias do
					functions_namespace.functions[alias] = command
				end
			end
		end
	end
	return functions_namespace
end

function apply_prototypes(functions_by_id, functions_namespace, function_prototypes_namespace, user_permissions: any?)
	for name, command in function_prototypes_namespace.functions do
		if command.type == "namespace" then
			error "todo: namespace"
		end
		if command.permissions and user_permissions then
			if not has_permission(command.permissions, user_permissions) then
				continue
			end
		end
		command.server_run = "<server_run>"
		if not functions_by_id[name] then
			functions_by_id[name] = command
			functions_namespace.functions[name] = command
		else
			local original = functions_by_id[name]
			for k, v in command do
				original[k] = v
			end
		end
	end
end

function search<T>(candidates: { Suggestion }, query: string): { Suggestion }
	local ok = {}
	local new_candidates: { Suggestion } = {}
	for _, candidate in candidates do
		local v = candidate.display_text or candidate.text
		if v:lower() == query:lower() then
			candidate.match_start = 1
			candidate.match_end = #query
			table.insert(ok, 1, candidate)
		elseif v:lower():sub(1, #query) == query:lower() then
			candidate.match_start = 1
			candidate.match_end = #query
			table.insert(ok, candidate)
		else
			table.insert(new_candidates, candidate)
		end
		if #ok > 20 then
			return ok
		end
	end
	for _, candidate in new_candidates do
		local v = candidate.display_text or candidate.text
		local s, e = v:lower():find(query)
		if s == nil then
			continue
		end
		candidate.match_start = s
		candidate.match_end = e
		table.insert(ok, candidate)

		if #ok > 20 then
			return ok
		end
	end
	return ok
end

return {
	search = search,
	expand_permissions = expand_permissions,
	has_permission = has_permission,
	get_user_permission_and_rank = get_user_permission_and_rank,
	normalize_function = normalize_function,
	set_permission = set_permission,
	compare_ranks = compare_ranks,
	serialize_config = serialize_config,
	reload_commands = reload_commands,
	apply_prototypes = apply_prototypes,
}
