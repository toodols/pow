local Players = game:GetService "Players"
local parser = require(script.Parent.Parent.parser)
local types = require(script.Parent.Parent.types)
local util = require(script.Parent.Parent.util)
type Expression = parser.Expression
type Type = types.Type
type Result<T, E> = types.Result<T, E>
type Suggestion = types.Suggestion
type Process = types.Process

function multiple(type: Type): Type
	return {
		name = type.name .. "[]",
		description = type.name .. " separated by commas",
		coerce_expression = function(expression: Expression, process: Process): Result<any, string>
			if expression.type == "string" then
				local fragments = expression.value:split ","
				local coerced_values = {}
				for _, frag in fragments do
					if type.coerce_expression then
						local coerced = type.coerce_expression({ type = "string", value = frag }, process)
						if coerced.err then
							return { err = coerced.err }
						end
						table.insert(coerced_values, coerced.ok)
					else
						table.insert(coerced_values, frag)
					end
				end
				return { ok = coerced_values }
			elseif expression.type == "function" then
				return { err = "This is a function." }
			end
			error "unreachable"
		end,
		coerce_value = function(value, process): Result<any, string>
			if typeof(value) == "table" then
				local coerced_values = {}
				for _, val in value do
					if type.coerce_value then
						local coerced = type.coerce_value(val, process)
						if coerced.err then
							return { err = coerced.err }
						end
						table.insert(coerced_values, coerced.ok)
					else
						table.insert(coerced_values, val)
					end
				end
				return { ok = coerced_values }
			end
			return { err = `cannot coerce {typeof(value)} to ${type.name}[]` }
		end,
		autocomplete = if type.autocomplete
			then function(text: string, replace_at: number, process: Process)
				local last_comma = text:match ".*(),"
				if not last_comma then
					last_comma = 0
				end
				local last_frag = text:sub(last_comma + 1)
				if typeof(type.autocomplete) == "function" then
					return type.autocomplete(last_frag, replace_at + last_comma, process)
				else
					return type.autocomplete
				end
			end
			else nil,
	}
end

function instance_type(name: string, ty: string): Type
	return {
		name = name,
		coerce_expression = function(expression: Expression): Result<Instance, string>
			return { err = "won't convert string to instance of " .. ty }
		end,
		coerce_value = function(value): Result<Instance, string>
			if typeof(value) == "Instance" and value:IsA(ty) then
				return { ok = value }
			end
			return { err = `cannot coerce {typeof(value)} to {ty}` }
		end,
	}
end

local builtin_types: {
	[string]: Type,
} = {}
builtin_types.string = {
	name = "string",
	coerce_expression = function(expression: Expression): Result<string, string>
		if expression.type == "string" then
			return { ok = expression.value }
		elseif expression.type == "function" then
			return { ok = "<function>" }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<string, string>
		if typeof(value) == "string" then
			return { ok = value }
		end
		return { err = `cannot coerce {typeof(value)} to string` }
	end,
}
builtin_types.boolean = {
	name = "boolean",
	coerce_expression = function(expression: Expression): Result<boolean, string>
		if expression.type == "string" then
			if expression.value == "true" then
				return { ok = true }
			elseif expression.value == "false" then
				return { ok = false }
			else
				return { err = "cannot coerce string to boolean" }
			end
		elseif expression.type == "function" then
			return { ok = true }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<boolean, string>
		if typeof(value) == "boolean" then
			return { ok = value }
		elseif typeof(value) == "string" then
			if value == "true" then
				return { ok = true }
			elseif value == "false" then
				return { ok = false }
			end
		end
		return { err = `cannot coerce {typeof(value)} to boolean` }
	end,
	autocomplete_simple = { "true", "false" },
}
builtin_types.number = {
	name = "number",
	coerce_expression = function(expression: Expression): Result<number, string>
		if expression.type == "string" then
			local value = tonumber(expression.value)
			if value == nil then
				return { err = "not a number" }
			end
			return { ok = value }
		elseif expression.type == "function" then
			return { err = "cannot coerce function to number" }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<number, string>
		if typeof(value) == "number" then
			return { ok = value }
		elseif typeof(value) == "string" then
			local num = tonumber(value)
			if num == nil then
				return { err = "not a number" }
			end
			return { ok = num }
		end
		return { err = `cannot coerce {typeof(value)} to number` }
	end,
}
builtin_types.player = {
	name = "player",
	coerce_expression = function(expression: Expression): Result<Player, string>
		if expression.type == "string" then
			if expression.value == "@me" then
				return { ok = Players.LocalPlayer }
			end
			local player = Players:FindFirstChild(expression.value)
			if player then
				return { ok = player }
			end
			return { err = `Cannot find player {expression.value}` }
		elseif expression.type == "function" then
			return { err = "This is a function." }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<Player, string>
		if typeof(value) == "Instance" and value:IsA "Player" then
			return { ok = value }
		end
		return { err = `Cannot coerce {typeof(value)} to player` }
	end,
	autocomplete = function(text: string, replace_at: number, process: Process)
		local suggestions = {}
		if text:sub(1, 1) == "@" then
			suggestions = {
				{
					text = "@me",
					replace_at = replace_at,
					display_text = `@me`,
				},
			}
		else
			for _, player in Players:GetPlayers() do
				table.insert(suggestions, {
					text = player.Name,
					display_text = if player.Name == player.DisplayName
						then player.Name
						else `{player.Name} ({player.DisplayName})`,
					replace_at = replace_at,
				})
			end
		end
		return util.search(suggestions, text)
	end,
}
builtin_types["function"] = {
	name = "function",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { ok = { type = "custom_function", commands = expression.commands } }
		elseif expression.type == "string" then
			return { err = "cannot coerce string to function" }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "table" and (value.type == "lua_function" or value.type == "custom_function") then
			return { ok = value }
		end
		return { err = `cannot coerce {typeof(value)} to function` }
	end,
}
-- players is a special case because there is @all,@others,...
builtin_types.players = {
	name = "players",
	coerce_expression = function(expression: Expression, process: Process): Result<{ Player }, string>
		if expression.type == "string" then
			local fragments = expression.value:split ","
			local coerced_values = {}
			for _, frag in fragments do
				if frag == "@me" then
					table.insert(coerced_values, process.owner)
				elseif frag == "@all" then
					for _, player in Players:GetPlayers() do
						table.insert(coerced_values, player)
					end
				elseif frag == "@others" then
					for _, player in Players:GetPlayers() do
						if player ~= process.owner then
							table.insert(coerced_values, player)
						end
					end
				else
					local coerced = builtin_types.player.coerce_expression({ type = "string", value = frag }, process)
					if coerced.err then
						return { err = coerced.err }
					end
					table.insert(coerced_values, coerced.ok)
				end
			end
			return { ok = coerced_values }
		elseif expression.type == "function" then
			return { err = "This is a function." }
		end
		error "unreachable"
	end,

	coerce_value = function(value, process): Result<any, string>
		if typeof(value) == "table" then
			local coerced_values = {}
			for _, val in value do
				local coerced = builtin_types.player.coerce_value(val, process)
				if coerced.err then
					return { err = coerced.err }
				end
				table.insert(coerced_values, coerced.ok)
			end
			return { ok = coerced_values }
		end
		return { err = `cannot coerce {typeof(value)} to player[]` }
	end,
	autocomplete = function(text, replace_at, process)
		local last_comma = text:match ".*(),"
		if not last_comma then
			last_comma = 0
		end
		local last_frag = text:sub(last_comma + 1)

		if last_frag:sub(1, 1) == "@" then
			local values = {
				"@all",
				"@me",
				"@others",
			}
			local matches = {}
			for _, value in values do
				table.insert(matches, {
					replace_at = replace_at + last_comma,
					text = value,
				})
			end
			return util.search(matches, last_frag)
		end
		return (builtin_types.player.autocomplete :: (...any) -> any)(last_frag, replace_at + last_comma, process)
	end,
}
builtin_types.any = {
	name = "any",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { ok = { type = "custom_function", commands = expression.commands } }
		elseif expression.type == "string" then
			return { ok = expression.value }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		return { ok = value }
	end,
}
builtin_types.table = {
	name = "table",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { err = "Cannot convert function to table" }
		elseif expression.type == "string" then
			return { ok = expression.value:split "," }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "table" then
			return { ok = value }
		end
		return { err = `cannot coerce {typeof(value)} to table` }
	end,
}

builtin_types.cframe = {
	name = "cframe",
	coerce_expression = function(expression: Expression): Result<any, string>
		return { err = "cannot be constructed from expression" }
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "CFrame" then
			return { ok = value }
		elseif typeof(value) == "Vector3" then
			return { ok = CFrame.new(value) }
		end
		return { err = `cannot coerce {typeof(value)} to cframe` }
	end,
}
builtin_types.vector3 = {
	name = "vector3",
	coerce_expression = function(expression: Expression): Result<any, string>
		return { err = "cannot be constructed from expression" }
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "Vector3" then
			return { ok = value }
		elseif typeof(value) == "CFrame" then
			return { ok = value.Position }
		end
		return { err = `cannot coerce {typeof(value)} to vector3` }
	end,
}
builtin_types.instance = {
	name = "instance",
	coerce_expression = function(expression: Expression): Result<any, string>
		return { err = "cannot be constructed from expression" }
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "Instance" then
			return { ok = value }
		end
		return { err = `cannot coerce {typeof(value)} to instance` }
	end,
}
builtin_types.variable_name = {
	name = "variable_name",
	coerce_expression = function(expression: Expression, process: Process): Result<any, string>
		if expression.type == "string" then
			return { ok = expression.value }
		end
		return { err = "not a string" }
	end,
	coerce_value = function(value): Result<any, string>
		if typeof(value) == "string" then
			return { ok = value }
		end
		return { err = `cannot coerce {typeof(value)} to variable_name` }
	end,
	autocomplete = function(text, replace_at, process)
		local matches = {}
		for k in process.global_scope.variables do
			table.insert(matches, {
				replace_at = replace_at,
				text = k,
			})
		end
		return util.search(matches, text)
	end,
}
builtin_types.instances = multiple(builtin_types.instance)
builtin_types.humanoid = instance_type("humanoid", "Humanoid")
builtin_types.model = instance_type("model", "Model")
builtin_types.pvinstance = instance_type("pvinstance", "PVInstance")

-- just for autocomplete this doesn't actually check anything
builtin_types.types = {
	name = "types",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { err = "not a string" }
		elseif expression.type == "string" then
			return { ok = expression.value }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		return { ok = value }
	end,
	autocomplete_simple = { "any", "string", "number", "boolean", "function", "player", "players" },
}
builtin_types.permission = {
	name = "permission",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { err = "not a string" }
		elseif expression.type == "string" then
			return { ok = expression.value }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		return { ok = value }
	end,
	autocomplete = function(text, replace_at, process)
		local matches = {}
		for k in (process.config.expanded_permission_types or process.config.user_permissions) do
			if k:sub(1, #text):lower() == text:lower() then
				table.insert(matches, {
					replace_at = replace_at,
					text = k,
				})
			end
		end
		return matches
	end,
}
builtin_types.keycode = {
	name = "keycode",
	coerce_expression = function(expression: Expression): Result<any, string>
		if expression.type == "function" then
			return { err = "not a string" }
		elseif expression.type == "string" then
			local value: Enum.KeyCode = (Enum.KeyCode :: any):FromName(expression.value)
			if value then
				return { ok = value }
			else
				return { err = `Cannot find keycode {expression.value}` }
			end
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<any, string>
		return { ok = value }
	end,
	autocomplete = function(text, replace_at, process)
		local matches = {}
		for _, keycode in Enum.KeyCode:GetEnumItems() do
			local k = keycode.Name
			table.insert(matches, {
				replace_at = replace_at,
				text = k,
			})
		end
		return util.search(matches, text)
	end,
}
builtin_types.test_quoted_enum = {
	autocomplete_simple = {
		`hello world`,
		`yes please`,
		`abc`,
		`def`,
		`ggg`,
		`hhh`,
		`good`,
		`bad`,
		`easy`,
		`more`,
	},
}

builtin_types.gearid = {
	name = "gearid",
	coerce_expression = function(expression: Expression): Result<number, string>
		if expression.type == "string" then
			local value = tonumber(expression.value)
			if value == nil then
				return { err = "not a number" }
			end
			return { ok = value }
		elseif expression.type == "function" then
			return { err = "cannot coerce function to number" }
		end
		error "unreachable"
	end,
	coerce_value = function(value): Result<number, string>
		if typeof(value) == "number" then
			return { ok = value }
		elseif typeof(value) == "string" then
			local num = tonumber(value)
			if num == nil then
				return { err = "not a number" }
			end
			return { ok = num }
		end
		return { err = `cannot coerce {typeof(value)} to number` }
	end,
	autocomplete = function(text, replace_at, process)
		local matches = {}
		local gears = {
			{
				125013769,
				"Linked Sword",
			},
			{
				16688968,
				"Gravity Coil",
			},
			{
				10472779,
				"Bloxy Cola",
			},
			{
				225921000,
				"Rainbow Magic Carpet",
			},
			{
				212296936,
				"Red Hyperlaser Gun",
			},
			{
				130113146,
				"Hyperlaser Gun",
			},
			{
				11999247,
				"Subspace Tripmine",
			},
			{
				99119158,
				"Speed Coil",
			},
			{
				83704165,
				"Icedagger",
			},
			{
				16726030,
				"Cheezburger",
			},
			{
				22596452,
				"Pepperoni Pizza",
			},
			{
				116040770,
				"Flashlight",
			},
			{
				78730532,
				"Body Swap Potion",
			},
			{
				111876831,
				"April Showers",
			},
			{
				113328094,
				"Lightblox Jar",
			},
			{
				67747912,
				"Heat Seeking Missile Launcher",
			},
			{
				115377964,
				"Laser Finger Pointers",
			},
			{
				11419882,
				"Red Stratobloxxer",
			},
			{
				10727852,
				"Witches Brew",
			},
			{ 16722267, "Moneybag" },
			{ 81154592, "Firebrand" },
			{ 68603324, "Venomshank" },
			{ 16641274, "Illumina" },
			{ 37816777, "Ghostwalker" },
			{ 16895215, "Darkheart" },
			{ 77443704, "Windforce" },
		}
		for _, gear in gears do
			table.insert(matches, {
				replace_at = replace_at,
				text = tostring(gear[1]),
				display_text = `{gear[1]} ({gear[2]})`,
			})
		end
		return util.search(matches, text)
	end,
}

return {
	builtin_types = builtin_types,
}
