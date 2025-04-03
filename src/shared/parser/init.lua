-- i wrote this a long time ago that's why it has a different style
local lex = require(script.lex)

-- Considerations:
-- Should commandPath be parsed as one single token or a bunch of tokens?
-- Is a lexer even appropriate for this type of language?

--[[
	start = _? commands _?
	commands = command (_? ";" _? commands)* (_? ";")?
	command = commandPath _ (commandArg _)*
	commandPath = word
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

	self.tokens = tokens
	self.index = 1
	self.failState = nil

	return self
end

function Parser:expectToken(tokenType, failState)
	local token = self.tokens[self.index]
	if not token or token.type ~= tokenType then
		if failState then
			self.failState = failState
		end
		if token then
			error(`Expected token of type {tokenType} but got {token.type} at {token.start} {token.finish} {token.raw}`)
		else
			error(`Expected token of type {tokenType} but no more tokens`)
		end
	end
	self.index = self.index + 1
	return token
end

function Parser:optionalToken(tokenType)
	if self:nextIs(tokenType) then
		self:forward()
	end
end

function Parser:forward()
	self.index = self.index + 1
end

function Parser:nextIs(...): boolean
	if self.tokens[self.index] == nil then
		return false
	end
	for _, v in pairs { ... } do
		if self.tokens[self.index].type == v then
			return true
		end
	end
	return false
end
function Parser:getPos(): number
	return if self.tokens[self.index] then self.tokens[self.index].start else 0
end
function Parser:getFinish(): number
	if self.tokens[self.index - 1] then
		return self.tokens[self.index - 1].finish
	else
		return 0
	end
end

function Parser:parseCommands(): Commands
	local list: { Command } = {}
	local start = self:getPos()
	local trailing_semi = false

	while true do
		if self:nextIs "word" then
			table.insert(list, self:parseCommand())
			if self:nextIs "semicolon" then
				self:forward()
				if self:nextIs "whitespace" then
					self:forward()
				end
				trailing_semi = true
			else
				trailing_semi = false
				break
			end
		else
			self.failState = {
				type = "commandPath",
				path = "",
				finish = self:getFinish(),
				start = self:getFinish(),
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
		finish = self:getFinish(),
	}
end

function Parser:parseFunction(): Function
	local token = self:expectToken "leftBracket"
	self:optionalToken "whitespace"
	local commands = self:parseCommands()
	self:optionalToken "whitespace"
	self:expectToken "rightBracket"
	return {
		type = "function",
		commands = commands,
		start = token.start,
		finish = self:getFinish(),
	}
end

function Parser:parseSubcall(): Subcall
	local token = self:expectToken "leftParen"
	local commands = self:parseCommands()
	self:expectToken "rightParen"
	return {
		type = "subcall",
		commands = commands,
		start = token.start,
		finish = self:getFinish(),
	}
end

function Parser:parseString(): String
	local str = self:expectToken "string"
	return {
		type = "string",
		value = str.value,
		start = str.start,
		finish = str.finish,
		quoted = true,
	}
end

function Parser:parseCommand(): Node<Command>
	local path = self:expectToken("word").raw
	if path:find "," then
		error "path can't contain comma"
	end
	local args: { Expression } = {}
	self.failState = {
		type = "commandPath",
		path = path,
		start = path.start,
		finish = self:getFinish(),
	}
	if self:nextIs "whitespace" then
		self:forward()
		self.failState = {
			type = "commandArguments",
			path = path,
			args = args,
			argNum = #args + 1,
			finish = self:getFinish(),
		}
		while true do
			if self:nextIs "word" then
				local word = self:expectToken "word"
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
			elseif self:nextIs "unquotedString" then
				local token = self:expectToken "unquotedString"
				table.insert(args, {
					type = "string",
					quoted = false,
					value = token.raw,
					start = token.start,
					finish = token.finish,
				})
			elseif self:nextIs "number" then
				local number = self:expectToken "number"
				table.insert(args, {
					type = "string",
					quoted = false,
					value = number.raw,
					start = number.start,
					finish = number.finish,
				})
			elseif self:nextIs "string" then
				table.insert(args, self:parseString())
			elseif self:nextIs "leftBracket" then
				table.insert(args, self:parseFunction())
			elseif self:nextIs "leftParen" then
				table.insert(args, self:parseSubcall())
			else
				break
			end
			if self:nextIs "whitespace" then
				self:forward()
				self.failState = {
					type = "commandArguments",
					path = path,
					args = args,
					argNum = #args + 1,
					finish = self:getFinish(),
				}
			else
				self.failState = {
					type = "commandArguments",
					path = path,
					args = args,
					argNum = #args,
					finish = self:getFinish(),
				}
				break
			end
		end
	end
	return {
		type = "command",
		path = path,
		args = args,
		start = path.start,
		finish = self:getFinish(),
	}
end

local function parse(commandText, finishPos): (boolean, RootCommands, Parser)
	local s1, parser = pcall(function()
		local tokens = lex.lexUntil(commandText, finishPos or #commandText)
		return Parser.new(tokens)
	end)
	if not s1 then
		return false, parser, nil :: any
	end
	local s2, result = pcall(function()
		local res = parser:parseCommands()
		res.raw = commandText
		return res
	end)
	return s2, result, parser
end

return { parse = parse }
