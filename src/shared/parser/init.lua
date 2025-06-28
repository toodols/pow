-- i wrote this a long time ago that's why it has a different style
local lex = require(script.lex)

-- Considerations:
-- Should command_path be parsed as one single token or a bunch of tokens?
-- Is a lexer even appropriate for this type of language?

--[[
	start = _? commands _?
	commands = command (_? ";" _? commands)* (_? ";")?
	command = command_path _ (commandArg _)*
	command_path = word
	commandArg = function | subcall | number | string
	function = "{" _? commands _? "}"
	number = [0-9]+(\.[0-9]+)?
	string = \" (\\. | [^"])* \"
	word = [a-zA-Z0-9_-/.]+
	subcall = "(" _? commands _? ")"
]]

type Token = {
	type: string,
	value: any,
	raw: string,
	start: number,
	finish: number,
}

type Node<T> = T & {
	start: number,
	finish: number,
}

export type Subcall = Node<{
	type: "subcall",
	commands: Commands,
}>

export type Function = Node<{
	type: "function",
	commands: Commands,
}>

export type String = Node<{
	type: "string",
	value: string,
	quoted: boolean,
}>

export type Word = Node<{
	type: "word",
	raw: string,
}>

export type Expression = Subcall | Function | String | { type: "lua_value", value: any }

export type Command = Node<{
	type: "command",
	path: string,
	args: { Expression },
}> | {
	type: "empty_command",
}

export type Commands = Node<{
	type: "commands",
	list: { Command },
}>
export type RootCommands = Node<{
	type: "commands",
	list: { Command },
	raw: string,
}>

type Parser = {}

local Parser = {}
Parser.__index = Parser
function Parser.new(tokens)
	local self = setmetatable({}, Parser)
	self.tokens = {}
	for _, token in tokens do
		if token.type ~= "whitespace" and token.type ~= "comment" then
			table.insert(self.tokens, token)
		end
	end
	self.finish = 0
	if tokens[#tokens] then
		self.finish = tokens[#tokens].finish
	end
	self.index = 1
	self.fail_state = nil

	return self
end

function Parser:expect_token(token_type, fail_state)
	local token = self.tokens[self.index]
	if not token or token.type ~= token_type then
		if fail_state then
			self.fail_state = fail_state
		end
		if token then
			error(
				`Expected token of type {token_type} but got {token.type} at {token.start} {token.finish} {token.raw}`
			)
		else
			error(`Expected token of type {token_type} but no more tokens`)
		end
	end
	self.index = self.index + 1
	return token
end

function Parser:next_is(...): boolean
	if self.tokens[self.index] == nil then
		return false
	end
	for _, v in { ... } do
		if self.tokens[self.index].type == v then
			return true
		end
	end
	return false
end

function Parser:get_pos(): number
	return if self.tokens[self.index] then self.tokens[self.index].start else 0
end

function Parser:get_finish(): number
	if self.tokens[self.index - 1] then
		return self.tokens[self.index - 1].finish
	else
		return 0
	end
end

function Parser:parse_commands(): Commands
	local list: { Command } = {}
	local start = self:get_pos()
	local trailing_semi = false

	while true do
		if self:next_is "word" then
			table.insert(list, self:parse_command())
			if self:next_is "semicolon" then
				self:expect_token "semicolon"
				trailing_semi = true
			else
				trailing_semi = false
				break
			end
		else
			self.fail_state = {
				type = "command_path",
				path = "",
				finish = self:get_finish(),
				start = self:get_finish(),
			}
			break
		end
	end
	if trailing_semi then
		table.insert(list, {
			type = "empty_command",
		})
	end
	return {
		type = "commands",
		list = list,
		start = start,
		finish = self:get_finish(),
	}
end

function Parser:parse_function(): Function
	local token = self:expect_token "left_bracket"
	local commands = self:parse_commands()
	self:expect_token "right_bracket"
	self.fail_state = nil
	return {
		type = "function",
		commands = commands,
		start = token.start,
		finish = self:get_finish(),
	}
end

function Parser:parse_subcall(): Subcall
	local token = self:expect_token "left_paren"
	local commands = self:parse_commands()
	self:expect_token "right_paren"
	self.fail_state = nil
	return {
		type = "subcall",
		commands = commands,
		start = token.start,
		finish = self:get_finish(),
	}
end

function Parser:parse_string(): String
	local str = self:expect_token "string"
	return {
		type = "string",
		value = str.value,
		start = str.start,
		finish = str.finish,
		quoted = true,
	}
end

function Parser:parse_incomplete_string(): String
	local str = self:expect_token "incomplete_string"
	return {
		type = "string",
		value = str.value,
		start = str.start,
		finish = str.finish,
		quoted = true,
	}
end

function Parser:parse_command(): Node<Command>
	local path = self:expect_token("word").raw
	if path:find "," then
		error "path can't contain comma"
	end
	local args: { Expression } = {}
	self.fail_state = {
		type = "command_path",
		path = path,
		start = path.start,
		finish = self:get_finish(),
	}

	while true do
		if self.finish ~= self:get_finish() then
			self.fail_state = {
				type = "command_arguments",
				path = path,
				args = args,
				argNum = #args + 1,
				finish = self:get_finish(),
			}
		end
		if self:next_is "word" then
			local word = self:expect_token "word"
			-- if word.raw:match("^%d+$") then
			-- 	table.insert(args, {
			-- 		type = "number",
			-- 		value = tonumber(word.raw),
			-- 		start = word.start,
			-- 		finish = word.finish,
			-- 	})
			-- else
			table.insert(args, {
				type = "string",
				quoted = false,
				value = word.raw,
				start = word.start,
				finish = word.finish,
			})
			-- end
		elseif self:next_is "unquoted_string" then
			local token = self:expect_token "unquoted_string"
			table.insert(args, {
				type = "string",
				quoted = false,
				value = token.raw,
				start = token.start,
				finish = token.finish,
			})
		elseif self:next_is "number" then
			local number = self:expect_token "number"
			table.insert(args, {
				type = "string",
				quoted = false,
				value = number.raw,
				start = number.start,
				finish = number.finish,
			})
		elseif self:next_is "string" then
			table.insert(args, self:parse_string())
		elseif self:next_is "left_bracket" then
			table.insert(args, self:parse_function())
		elseif self:next_is "left_paren" then
			table.insert(args, self:parse_subcall())
		elseif self:next_is "incomplete_string" then
			table.insert(args, self:parse_incomplete_string())
			error "incomplete string"
		else
			break
		end
		self.fail_state = {
			type = "command_arguments",
			path = path,
			args = args,
			argNum = #args,
			finish = self:get_finish(),
		}
	end
	return {
		type = "command",
		path = path,
		args = args,
		start = path.start,
		finish = self:get_finish(),
	}
end

local function parse(command_text, finish_pos): (boolean, RootCommands, Parser)
	local s1, parser = pcall(function()
		local tokens = lex.lex_until(command_text, finish_pos or #command_text)
		return Parser.new(tokens)
	end)
	if not s1 then
		return false, parser, nil :: any
	end
	local s2, result = pcall(function()
		local res = parser:parse_commands()
		if parser.index ~= #parser.tokens + 1 then
			parser.fail_state = nil
			error("expected EOF but found " .. parser.tokens[parser.index].type)
		end
		res.raw = command_text
		return res
	end)
	return s2, result, parser
end

return { parse = parse }
