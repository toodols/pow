local function generate_pat_token(pat, type)
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

local tk_word = generate_pat_token("^[a-zA-Z0-9%_-%.$,@]+", "word")
-- local tkSlash = generatePatToken("^/", "slash")
local tk_whitespace = generate_pat_token("^%s+", "whitespace")
local tk_left_bracket = generate_pat_token("^{", "left_bracket")
local tk_right_bracket = generate_pat_token("^}", "right_bracket")
local tk_left_paren = generate_pat_token("^%(", "left_paren")
local tk_right_paren = generate_pat_token("^%)", "right_paren")
local tk_comma = generate_pat_token("^,", "comma")
local tk_semicolon = generate_pat_token("^;", "semicolon")

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
local function tk_number(text, start)
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

	-- return {
	-- 	type = "number",
	-- 	raw = t,
	-- 	start = start,
	-- 	finish = start + #t - 1,
	-- 	value = if neg then -(tonumber(t) :: number) else tonumber(t),
	-- }
	return {
		type = "string",
		raw = t,
		start = start - 1,
		finish = start + #t - 1,
		value = t,
	}
end

local function tk_string(text, start)
	local match = text:match('^"', start)
	if not match then
		return nil
	end
	local local_start = start + #match
	while true do
		local t = text:match("^\\.", local_start) or text:match('^[^"\\]', local_start)
		if t then
			local_start = local_start + #t
		else
			break
		end
	end
	local t = text:match('^"', local_start)
	if t then
		local_start = local_start + #t
		return {
			type = "string",
			raw = text:sub(start, local_start - 1),
			start = start,
			value = text:sub(start + 1, local_start - 2):gsub("\\(.)", "%1"),
			finish = local_start - 1,
		}
	else
		return {
			type = "incomplete_string",
			raw = text:sub(start, local_start - 1),
			start = start,
			value = text:sub(start + 1, local_start - 1):gsub("\\(.)", "%1"),
			finish = local_start - 1,
		}
	end
end

local function tk_comment(text, start)
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

local token_types = {
	tk_whitespace,
	tk_word,
	-- tkSlash,
	tk_number,
	tk_string,
	tk_left_bracket,
	tk_right_bracket,
	tk_left_paren,
	tk_right_paren,
	tk_comma,
	tk_semicolon,
	tk_comment,
	-- tkParam,
}

-- Tokenizes until the current token exceeds the given position
local function lex_until(text, target)
	local tokens = {}
	local pos = 1
	while true do
		if pos > target then
			break
		end
		local t = nil
		for _, token_type in token_types do
			t = token_type(text, pos)
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
	return lex_until(text, #text)
end

function test()
	local result = lex(`print 123 "hello`)
	print(result)
end
test()

return { lex = lex, lex_until = lex_until }
