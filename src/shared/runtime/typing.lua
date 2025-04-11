local types = require(script.Parent.Parent.types)
local parser = require(script.Parent.Parent.parser)

type Expression = parser.Expression
type Type = types.Type
type Param = types.Param
type Result<T, E> = types.Result<T, E>
type Overload = types.Overload
type Process = types.Process

local tag_expression_meta = {}
local function tag_expression(value: Expression)
	return setmetatable(value :: {}, tag_expression_meta)
end

-- Returns the overload that best matches
-- args can be either a type of an expression
function infer(args: { string | Expression }, overloads: { Overload }, process: Process): Result<Overload, string>
	local fail_reason = { err = "error" }
	if #overloads == 0 then
		return {
			err = "no overloads",
		}
	end
	for _, overload in overloads do
		local has_rest = if #overload.args > 0 then overload.args[#overload.args].rest else false
		if not has_rest and #args > #overload.args then
			if fail_reason == nil then
				fail_reason = {
					err = "too many arguments",
				}
			end
			continue
		end
		local args_success = true
		local rest_type = nil
		for i, arg in args do
			local param = overload.args[i]
			local param_type
			if not param and rest_type then
				param_type = rest_type
			elseif param.rest then
				rest_type = param.type
				param_type = param.type
			else
				param_type = param.type
			end

			local type_obj = process.types[param_type]
			if type_obj == nil then
				return { err = "cannot find type " .. param_type }
			end
			local result = if getmetatable(arg) == tag_expression_meta
				then type_obj.coerce_expression(arg, process)
				elseif arg == param_type or arg == "any" then { ok = arg }
				else { err = `{arg} != {param_type}` }

			if result.err == nil then
				-- table.insert(coerced_args, result.ok)
			else
				fail_reason = result
				args_success = false
				break
			end
		end
		if args_success then
			return { ok = overload }
		end
	end
	return fail_reason
end

function coerce_args(
	args: { any },
	overloads: { { args: { Param }, returns: Type } },
	process: Process
): Result<{ any }, string>
	local fail_reason = { err = "no overloads found" }
	if #overloads == 0 then
		return {
			err = "no overloads",
		}
	end
	for _, overload in overloads do
		local has_rest = if #overload.args > 0 then overload.args[#overload.args].rest else false
		if not has_rest and #args ~= #overload.args then
			if fail_reason == nil then
				fail_reason = {
					err = "wrong number of arguments",
				}
			end
			continue
		end
		local coerced_args = {}
		local args_success = true
		local rest_type = nil
		for i, arg in args do
			local param = overload.args[i]
			local param_type
			if not param and rest_type then
				param_type = rest_type
			elseif param.rest then
				rest_type = param.type
				param_type = param.type
			else
				param_type = param.type
			end

			local type_obj = process.types[param_type]
			if type_obj == nil then
				return { err = "cannot find type " .. param_type }
			end
			local result = if getmetatable(arg) == tag_expression_meta
				then type_obj.coerce_expression(arg, process)
				else type_obj.coerce_value(arg, process)
			if result.err == nil then
				table.insert(coerced_args, result.ok)
			else
				fail_reason = {
					err = tostring(result.err),
				}
				args_success = false
				break
			end
		end
		if args_success then
			return { ok = coerced_args }
		end
	end
	return fail_reason
end

return {
	coerce_args = coerce_args,
	tag_expression = tag_expression,
	infer = infer,
}
