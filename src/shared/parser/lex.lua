local function generatePatToken(pat, type)
	return function(text, start)
		local t = text:match(pat, start)
		return t and {
			type = type,
			raw = t,
			start = start,
			finish = start + #t - 1,
		}
	end
end

local tkWord = generatePatToken("^[a-zA-Z0-9%_-%.$,@]+", "word")
-- local tkSlash = generatePatToken("^/", "slash")
local tkWhitespace = generatePatToken("^%s+", "whitespace")
local tkLeftBracket = generatePatToken("^{", "leftBracket")
local tkRightBracket = generatePatToken("^}", "rightBracket")
local tkLeftParen = generatePatToken("^%(", "leftParen")
local tkRightParen = generatePatToken("^%)", "rightParen")
local tkComma = generatePatToken("^,", "comma")
local tkSemicolon = generatePatToken("^;", "semicolon")

-- local function tkParam(text, start)
-- 	local t = text:match("^%@%d+", start)
-- 	if not t then
-- 		return nil
-- 	end
-- 	return {
-- 		type = "param",
-- 		raw = t,
-- 		start = start,
-- 		finish = start + #t - 1,
-- 		value = tonumber(t:sub(2)),
-- 	}
-- end
local function tkNumber(text, start)
	local neg = false
	if text:sub(start, start) == "-" then
		neg = true
		start = start + 1
	end

	local t = text:match("^%d+", start)
	if not t then
		return nil
	end

	local t2 = text:match("^%.%d+", start + #t)
	if t2 then
		t = t .. t2
	end

	return {
		type = "number",
		raw = t,
		start = start,
		finish = start + #t - 1,
		value = if neg then -(tonumber(t) :: number) else tonumber(t),
	}
end

local function tkString(text, start)
	local match = text:match('^"', start)
	if not match then
		return nil
	end
	local localStart = start + #match
	while true do
		local t = text:match("^\\.", localStart) or text:match('^[^"\\]', localStart)
		if t then
			localStart = localStart + #t
		else
			break
		end
	end
	local t = text:match('^"', localStart)
	if t then
		localStart = localStart + #t
		return {
			type = "string",
			raw = text:sub(start, localStart - 1),
			start = start,
			value = text:sub(start + 1, localStart - 2):gsub("\\(.)", "%1"),
			finish = localStart - 1,
		}
	else
		return nil
	end
end

local function tkComment(text, start)
	if text:sub(start, start + 1) ~= "/*" then
		return
	end

	local close = text:find("*/", start + 1)
	if not close then
		error "unterminated comment"
	end
	return {
		type = "comment",
		raw = text:sub(start, close + 1),
		start = start,
		finish = close + 1,
	}
end

local tokenTypes = {
	tkWhitespace,
	tkWord,
	-- tkSlash,
	tkNumber,
	tkString,
	tkLeftBracket,
	tkRightBracket,
	tkLeftParen,
	tkRightParen,
	tkComma,
	tkSemicolon,
	tkComment,
	-- tkParam,
}

-- Tokenizes until the current token exceeds the given position
local function lexUntil(text, target)
	local tokens = {}
	local pos = 1
	while true do
		if pos > target then
			break
		end
		local t = nil
		for _, tokenType in tokenTypes do
			t = tokenType(text, pos)
			if t then
				break
			end
		end
		if t then
			table.insert(tokens, t)
			pos = t.finish + 1
		else
			break
		end
	end
	if pos < target + 1 then
		error(("Tokenizer failed: Stopped at %s but needs to continue to %s"):format(pos, target))
	end
	return tokens
end

local function lex(text)
	return lexUntil(text, #text)
end

return { lex = lex, lexUntil = lexUntil }
