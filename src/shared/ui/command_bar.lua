local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local UserInputService = game:GetService "UserInputService"
local Autocomplete = require(script.Parent.autocomplete).Autocomplete
local TextService = game:GetService "TextService"
local parser = require(script.Parent.Parent.parser)
local types = require(script.Parent.Parent.types)
local runtime = require(script.Parent.Parent.runtime)
local util = require(script.Parent.Parent.util)

type Process = types.Process
type Subcall = parser.Subcall
type Type = types.Type
type Expression = parser.Expression
type Result<T, E> = types.Result<T, E>
type Command = parser.Command
type Overload = types.Overload

local function infer_command(command: Command, process: Process, arg_num: number?): Result<Overload, string>
	-- the type is always the last command
	if command == nil then
		return { err = "command is nil" }
	end
	if command.type == "empty_command" then
		return { ok = "nil" }
	end
	local res = runtime.find_function(process.global_scope, command.path)
	if res.err then
		return res
	end
	local fun = res.ok
	-- if #fun.overloads == 1 then
	-- 	return { ok = fun.overloads[1].returns }
	-- end

	local args = {}
	for i = 1, arg_num or #command.args do
		local arg = command.args[i]
		if arg == nil then
			table.insert(args, "any")
			continue
		end
		if arg.type == "subcall" then
			local last_command = arg.commands.list[#arg.commands.list]
			local result = infer_command(last_command, process)
			if result.err then
				return result
			end
			table.insert(args, result.ok.returns)
		else
			table.insert(args, runtime.tag_expression(arg))
		end
	end
	local infer_res = runtime.infer(args, fun.overloads, process)
	return infer_res
end

local function overloads(func, selected)
	local overload_text = ""
	for i, overload in func.overloads do
		if overload == selected then
			overload_text ..= "<b>"
		end
		overload_text ..= i .. ". ("
		for j, arg in overload.args do
			if type(j) == "string" then
				error(j)
			end

			if j > 1 then
				overload_text ..= ", "
			end
			if arg.rest then
				overload_text ..= "..."
			end
			overload_text ..= arg.name .. ": " .. arg.type
		end
		overload_text ..= ") => " .. overload.returns
		if overload == selected then
			overload_text ..= "</b>"
		end
		overload_text ..= "\n"
	end
	return overload_text
end

function CommandBar(props: {
	is_open: boolean,
	set_is_open: (open: boolean) -> (),
	submit_command: (commandText: string) -> (),
	process: Process,
	input_ref: any,
})
	local input_ref = props.input_ref
	local offset, set_offset = React.useState(0)
	local autocomplete, set_autocomplete = React.useState {
		enabled = false,
		suggestions = {},
		err = nil,
		title = nil,
		type = nil,
		description = nil,
		aside_title = nil,
		aside_description = nil,
	}
	local autocomplete_index, set_autocomplete_index = React.useState(0)
	local err, set_error = React.useState { enabled = false, value = nil }

	local history_index = React.useRef(0)

	local function update_autocomplete()
		set_autocomplete { enabled = false }
		set_error { enabled = false }
		local input = input_ref.current
		if input == nil or not input:IsFocused() then
			return
		end
		local text = input.Text:sub(1, input.CursorPosition - 1)
		local x = 30 + TextService:GetTextSize(text, input.TextSize, input.Font, input.AbsoluteSize).X
		set_offset(x)
		local succ, res, parser_state = parser.parse(text)

		if parser_state == nil or parser_state.fail_state == nil then
			set_error {
				enabled = true,
				value = res,
			}
			return
		end

		local fail_state = parser_state.fail_state
		if fail_state.type == "command_path" then
			local suggestions = {}
			if #fail_state.path == 0 then
				return
			end
			for name, func in props.process.global_scope.functions.functions do
				table.insert(suggestions, {
					text = name,
					replace_at = fail_state.finish - #fail_state.path + 1,
					match_start = 1,
					match_end = #fail_state.path,
					title = func.name,
					description = `{func.description}\n\n{overloads(func)}`,
				})
			end
			set_autocomplete {
				enabled = true,
				suggestions = util.search(suggestions, fail_state.path),
				title = "Command",
				type = "command",
				description = "Command to run",
			}
			set_autocomplete_index(0)
			return
		elseif fail_state.type == "command_arguments" then
			local args = {}
			for i = 1, fail_state.argNum do
				if fail_state.args[i] then
					table.insert(args, fail_state.args[i])
				end
			end
			local cmd = {
				type = "command",
				path = fail_state.path,
				args = args,
			}
			local func = runtime.find_function(props.process.global_scope, fail_state.path)
			local infer_res = infer_command(cmd, props.process, fail_state.argNum)

			if infer_res.err then
				local args2 = {}
				-- that may have been too many. try acknowledging only 1..argNum-1 args
				for i = 1, fail_state.argNum - 1 do
					table.insert(args2, fail_state.args[i])
				end
				local cmd2 = {
					type = "command",
					path = fail_state.path,
					args = args2,
				}
				infer_res = infer_command(cmd2, props.process, fail_state.argNum)
				if infer_res.err then
					set_error {
						enabled = true,
						value = infer_res.err,
					}
					return
				end
			end
			local arg
			local overload_args = infer_res.ok.args
			local rest = false
			if overload_args[fail_state.argNum] then
				arg = overload_args[fail_state.argNum]
			elseif overload_args[#overload_args] then
				if overload_args[#overload_args].rest then
					rest = true
					arg = overload_args[#overload_args]
				end
			end
			if arg == nil then
				return
			end
			local ty_obj = props.process.types[arg.type]
			if ty_obj.autocomplete == nil and ty_obj.autocomplete_simple == nil then
				set_autocomplete {
					enabled = true,
					title = if rest then `{arg.name} [+ {fail_state.argNum - #overload_args}]` else arg.name,
					description = arg.description,
					type = arg.type,
					aside_title = func.ok.name,
					aside_description = `{func.ok.description}\n\n{overloads(func.ok, infer_res.ok)}`,
				}

				return
			end

			local arg_at_num = fail_state.args[fail_state.argNum]
			local replace_at = if arg_at_num then arg_at_num.start else parser_state.finish + 1
			local text
			if arg_at_num then
				if arg_at_num.type == "string" then
					text = arg_at_num.value
				end
			else
				text = ""
			end
			if text == nil then
				set_autocomplete {
					enabled = true,
					title = arg.name,
					description = arg.description,
					type = arg.type,
					aside_title = func.ok.name,
					aside_description = `{func.ok.description}\n\n{overloads(func.ok, infer_res.ok)}`,
				}
				return
			end

			local suggestions = {}
			if ty_obj.autocomplete ~= nil then
				suggestions = ty_obj.autocomplete(text, replace_at, props.process)
				for _, suggestion in suggestions do
					local is_word = suggestion.text:match "^[a-zA-Z0-9%_-%.$,@]+$" ~= nil
					if not is_word then
						if suggestion.display_text == nil then
							suggestions.display_text = suggestion.text
						end
						suggestion.value = suggestion.text
						suggestion.text = `"{suggestion.text}"`
					end
				end
			elseif ty_obj.autocomplete_simple ~= nil then
				local values = {}
				if typeof(ty_obj.autocomplete_simple) == "function" then
					values = ty_obj.autocomplete_simple(text, replace_at, props.process)
				else
					values = ty_obj.autocomplete_simple
				end
				local all_suggestions = {}
				for _, value in values do
					local is_word = value:match "^[a-zA-Z0-9%_-%.$,@]+$" ~= nil
					table.insert(all_suggestions, {
						replace_at = replace_at,
						display_text = value,
						value = value,
						text = if is_word then value else `"{value}"`,
					})
				end
				suggestions = util.search(all_suggestions, text)
			end

			if suggestions == nil then
				error "suggestions is nil"
				return
			end
			set_autocomplete {
				enabled = true,
				title = arg.name,
				description = arg.description,
				type = arg.type,
				suggestions = suggestions,
				aside_title = func.ok.name,
				aside_description = `{func.ok.description}\n\n{overloads(func.ok, infer_res.ok)}`,
			}
			set_autocomplete_index(0)
		end
	end

	React.useEffect(function()
		local input = input_ref.current
		assert(input, "input_ref.current is nil")
		local focus_lost = input.FocusLost:Connect(function(enterPressed, input_obj)
			update_autocomplete()
			if not props.is_open then
				return
			end
			if enterPressed then
				local command_text = input.Text
				if command_text == "" then
					return
				end
				task.wait()
				input.Text = ""
				input:CaptureFocus()
				task.wait()
				props.submit_command(command_text)
				history_index.current = 0
			elseif input_obj and input_obj.KeyCode == Enum.KeyCode.Escape then
				if input.Text == "" then
					props.set_is_open(false)
				else
					input:CaptureFocus()
					input.Text = ""
				end
			end
		end)

		local input_began = UserInputService.InputBegan:Connect(function(input_obj, game_processed)
			if input_obj.KeyCode == Enum.KeyCode.Semicolon then
				if props.is_open then
					if not input:IsFocused() then
						if not game_processed then
							task.wait()
							input:CaptureFocus()
						end
					elseif input.Text == "" then
						props.set_is_open(false)
						input:ReleaseFocus()
					end
				elseif not game_processed then
					props.set_is_open(true)
					task.wait()
					input:CaptureFocus()
				end
			elseif input_obj.KeyCode == Enum.KeyCode.Escape then
			elseif not autocomplete.enabled or autocomplete.suggestions == nil then
				if input_obj.KeyCode == Enum.KeyCode.Up then
					history_index.current = math.max((history_index.current - 1), -#props.process.history)
					if history_index.current == 0 then
						input_ref.current.Text = ""
					else
						input_ref.current.Text =
							props.process.history[#props.process.history + history_index.current + 1]
						input_ref.current.CursorPosition = #input_ref.current.Text + 1
					end
				elseif input_obj.KeyCode == Enum.KeyCode.Down then
					history_index.current = math.min(0, (history_index.current + 1))
					if history_index.current == 0 then
						input_ref.current.Text = ""
					else
						input_ref.current.Text =
							props.process.history[#props.process.history + history_index.current + 1]
						input_ref.current.CursorPosition = #input_ref.current.Text + 1
					end
				end
			end
		end)

		local focused = input.Focused:Connect(function()
			update_autocomplete()
		end)

		return function()
			focus_lost:Disconnect()
			input_began:Disconnect()
			focused:Disconnect()
		end
	end, { props.is_open, autocomplete })

	React.useEffect(function()
		if input_ref.current then
			update_autocomplete()
		end
	end, {})
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		LayoutOrder = 3,
	}, {
		TextLabel = React.createElement("TextLabel", {
			Text = ">",
			FontFace = Font.fromName "SourceSansPro",
			TextSize = 16,
			Size = UDim2.new(0, 30, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(44, 195, 255),
		}),
		TextBox = React.createElement("TextBox", {
			Text = "",
			ClearTextOnFocus = false,
			FontFace = Font.fromName "SourceSansPro",
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 30, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextColor3 = if err.enabled then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(255, 255, 255),
			ref = input_ref,
			[React.Change.CursorPosition] = function()
				update_autocomplete()
			end,
			[React.Change.Text] = function()
				update_autocomplete()
			end,
		}),
		Autocomplete = if autocomplete.enabled
			then React.createElement(Autocomplete, {
				offset = offset,
				suggestions = autocomplete.suggestions,
				type = autocomplete.type,
				title = autocomplete.title,
				description = autocomplete.description,
				aside_title = autocomplete.aside_title,
				aside_description = autocomplete.aside_description,
				index = autocomplete_index,
				set_index = set_autocomplete_index,
				suppress_tab = function()
					input_ref.current:GetPropertyChangedSignal("Text"):Wait()
				end,
				select = function(option)
					local new_text = input_ref.current.Text:sub(1, option.replace_at - 1)
						.. option.text
						.. input_ref.current.Text:sub(option.replace_at + option.text:len() + 1)
					input_ref.current.Text = new_text
					input_ref.current.CursorPosition = option.replace_at + option.text:len()
				end,
			})
			else nil,
	})
end

return {
	CommandBar = CommandBar,
}
