function expand_permissions(permissions)
	local expanded = {}

	local function resolve(key, visited)
		if expanded[key] then
			return expanded[key]
		end

		visited = visited or {}
		visited[key] = true
		local result = { [key] = true }

		for _, dep in (permissions[key] or {}) do
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

	return expanded
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
		if not has[permission] then
			return false
		end
	end
	return true
end

function normalize_function(command, name)
	command.type = "lua_function"
	command.name = name
	command.id = name
	if command.overloads == nil then
		command.overloads = {
			{
				returns = "any",
				args = {
					name = "any",
					type = "any",
					rest = true,
				},
			},
		}
	end
end

return {
	expand_permissions = expand_permissions,
	has_permission = has_permission,
	get_user_permission_and_rank = get_user_permission_and_rank,
	normalize_function = normalize_function,
}
