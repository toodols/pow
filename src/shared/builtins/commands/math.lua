local commands = {}
commands.add = {
	description = "Adds numbers ",
	permissions = { "math" },
	run = function(context)
		local sum = 0
		for _, arg in context.args do
			sum = sum + arg
		end
		return sum
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Value",
				type = "number",
				rest = true,
			} },
		},
	},
}

commands.add_vec3 = {
	description = "Adds vector3",
	permissions = { "math" },
	run = function(context)
		local sum = Vector3.zero
		for _, arg in context.args do
			sum = sum + arg
		end
		return sum
	end,
	overloads = {
		{
			returns = "vector3",
			args = { {
				name = "Value",
				type = "vector3",
				rest = true,
			} },
		},
	},
}

commands.as = {
	description = "Casts a string to a type",
	permissions = { "math" },
	run = function(context)
		error "this doesnt work yet"
	end,
	overloads = {
		{
			returns = "any",
			args = { {
				name = "Value",
				type = "any",
			}, {
				name = "Type",
				type = "type",
			} },
		},
	},
}

commands.equal = {
	description = "Checks if two values are equal",
	permissions = { "math" },
	alias = { "eq" },
	run = function(context)
		return context.args[1] == context.args[2]
	end,
	overloads = {
		-- this is funny gadget to test type inference but it's better to handle this at runtime
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "number",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "number",
		-- 		},
		-- 	},
		-- },
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "boolean",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "boolean",
		-- 		},
		-- 	},
		-- },
		-- {
		-- 	returns = "boolean",
		-- 	args = {
		-- 		{
		-- 			name = "lhs",
		-- 			type = "string",
		-- 		},
		-- 		{
		-- 			name = "rhs",
		-- 			type = "string",
		-- 		},
		-- 	},
		-- },
		{
			returns = "boolean",
			args = {
				{
					name = "LHS",
					type = "any",
				},
				{
					name = "RHS",
					type = "any",
				},
			},
		},
	},
}

commands["true"] = {
	description = "Returns true",
	permissions = { "math" },
	run = function(context)
		return true
	end,
	overloads = {
		{
			returns = "boolean",
			args = {},
		},
	},
}

commands["false"] = {
	description = "Returns false",
	permissions = { "math" },
	run = function(context)
		return false
	end,
	overloads = {
		{
			returns = "boolean",
			args = {},
		},
	},
}

commands["table"] = {
	description = "Constructs a table from arguments",
	permissions = { "math" },
	run = function(context)
		local t = {}
		for _, arg in context.args do
			table.insert(t, arg)
		end
		return t
	end,
	overloads = {
		{
			returns = "table",
			args = {},
		},
		{
			returns = "table",
			args = {
				{
					name = "Arguments",
					type = "any",
				},
			},
		},
	},
}

commands["nil"] = {
	description = "Returns nil",
	permissions = { "math" },
	run = function(context)
		return nil
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

commands.length = {
	description = "Returns the length of a table",
	permissions = { "math" },
	run = function(context)
		return #context.args[1]
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Table",
				type = "table",
			} },
		},
	},
}

commands.push = {
	description = "Pushes a value to the end of a table",
	permissions = { "math" },
	run = function(context)
		table.insert(context.args[1], context.args[2])
		return #context.args[1]
	end,
	overloads = {
		{
			returns = "nil",
			args = { {
				name = "Table",
				type = "table",
			}, {
				name = "Value",
				type = "any",
			} },
		},
	},
}

commands.pop = {
	description = "Pops a value from the end of a table",
	permissions = { "math" },
	run = function(context)
		return table.remove(context.args[1])
	end,
	overloads = {
		{
			returns = "any",
			args = { {
				name = "Table",
				type = "table",
			} },
		},
	},
}

commands.number = {
	description = "Creates a number",
	permissions = { "math" },
	run = function(context)
		return context.args[1]
	end,
	overloads = {
		{
			returns = "number",
			args = {
				{
					name = "Number",
					type = "number",
				},
			},
		},
	},
}

commands.to_string = {
	description = "Converts number to string",
	permissions = { "math" },
	run = function(context)
		return tostring(context.args[1])
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "Number",
					type = "number",
				},
			},
		},
	},
}

commands.string = {
	description = "Creates a string",
	permissions = { "math" },
	run = function(context)
		return context.args[1]
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
			},
		},
	},
}

commands.substring = {
	description = "Returns a substring",
	permissions = { "math" },
	run = function(context)
		return string.sub(context.args[1], context.args[2], context.args[3])
	end,
	overloads = {
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
				{
					name = "Start",
					type = "number",
				},
				{
					name = "End",
					type = "number",
				},
			},
		},
		{
			returns = "string",
			args = {
				{
					name = "String",
					type = "string",
				},
				{
					name = "Start",
					type = "number",
				},
			},
		},
	},
}

commands.concat = {
	description = "Concatenates strings",
	permissions = { "math" },
	run = function(context)
		return table.concat(context.args, "")
	end,
	overloads = {
		{
			returns = "string",
			args = { {
				name = "Strings",
				type = "string",
				rest = true,
			} },
		},
	},
}

commands.index = {
	description = "Returns the value at the index of a table",
	permissions = { "math" },
	run = function(context)
		return context.args[1][context.args[2]]
	end,
	overloads = {
		{
			returns = "any",
			args = {
				{ name = "Table", type = "table" },
				{ name = "Index", type = "number" },
			},
		},
	},
}

commands.mul = {
	description = "Multiplies two numbers",
	permissions = { "math" },
	run = function(context)
		local product = 1
		for _, arg in context.args do
			product = product * arg
		end
		return product
	end,
	overloads = {
		{
			returns = "number",
			args = { {
				name = "Value",
				type = "number",
				rest = true,
			} },
		},
	},
}

commands.vector3 = {
	description = "Creates a vector3 from components",
	permissions = { "math" },
	run = function(context)
		local x = context.args[1]
		local y = context.args[2]
		local z = context.args[3]
		return Vector3.new(x, y, z)
	end,
	overloads = {
		{
			returns = "vector3",
			args = {
				{
					name = "X",
					type = "number",
				},
				{
					name = "Y",
					type = "number",
				},
				{
					name = "Z",
					type = "number",
				},
			},
		},
	},
}

return commands
