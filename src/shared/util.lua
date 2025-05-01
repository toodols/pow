local types = require(script.Parent.types)
type Config = types.Config

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
		error(`command {name} has no permissions`)
	end
	if command.overloads == nil then
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
		extras = config.replicated_extras,
	}
	if has_permission({ "view_permissions" }, config.expanded_permission_types[user_permission]) then
		serialized_config.permissions = config.permissions
	end
	return serialized_config
end

return {
	expand_permissions = expand_permissions,
	has_permission = has_permission,
	get_user_permission_and_rank = get_user_permission_and_rank,
	normalize_function = normalize_function,
	set_permission = set_permission,
	compare_ranks = compare_ranks,
	serialize_config = serialize_config,
}
