local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local TextService = game:GetService "TextService"
local React = require(ReplicatedStorage.Packages.react)
local types = require(script.Parent.Parent.types)
type Process = types.Process

function Log(props: { left: string, left_color: Color3, right: string })
	local should_use_expand = TextService:GetTextSize(
		props.right,
		16,
		Enum.Font.SourceSans,
		Vector2.new(math.huge, math.huge)
	).X > 200
	local is_expanded, set_is_expanded = React.useState(false)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		HorizontalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
		Left = React.createElement("TextLabel", {
			Size = UDim2.new(0, 50, 0, 25),
			-- AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Left,
			RichText = true,
			TextSize = 16,
			Text = props.left,
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			TextColor3 = props.left_color,
			FontFace = Font.fromName("SourceSansPro", Enum.FontWeight.Bold),
		}),
		RightExpand = React.createElement("TextButton", {
			Size = UDim2.new(0, 0, 0, 25),
			BackgroundTransparency = 0.9,
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 2,
			Visible = should_use_expand,
			Text = if is_expanded then " - " else "...",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			[React.Event.MouseButton1Click] = function()
				set_is_expanded(not is_expanded)
			end,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}),
		}),
		Right = React.createElement("TextBox", {
			Size = UDim2.new(0, 0, 0, 25),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 16,
			RichText = true,
			Visible = not should_use_expand or is_expanded,
			BackgroundTransparency = 1,
			FontFace = Font.fromName "SourceSansPro",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextEditable = false,
			ClearTextOnFocus = false,
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = props.right,
		}),
	})
end

function pretty(value: any, indent: number?, visited: { [string]: boolean }?): string
	local indent_ = indent or 0
	local visited_ = visited or {}
	local indent_str = string.rep(" ", indent_)
	if type(value) == "string" then
		return '"' .. value .. '"'
	elseif type(value) == "number" then
		return tostring(value)
	elseif type(value) == "boolean" then
		return value and "true" or "false"
	elseif type(value) == "table" then
		if visited_[tostring(value)] then
			return "<circular>"
		end
		visited_[tostring(value)] = true
		if #value == 0 then
			local str = "{\n"
			for k, v in value do
				str = str
					.. indent_str
					.. "\t"
					.. pretty(k, indent_ + 2, visited_)
					.. ": "
					.. pretty(v, indent_ + 2, visited_)
					.. ",\n"
			end

			return str .. indent_str .. "  }"
		else
			local str = "{\n"
			for k, v in value do
				str = str .. indent_str .. "\t" .. pretty(v, indent_ + 2, visited_) .. ",\n"
			end
			return str .. indent_str .. "  }"
		end
	elseif type(value) == "userdata" then
		if typeof(value) == "Instance" then
			return value.Name
		else
			return "<userdata>"
		end
	else
		return "<" .. type(value) .. ">"
	end
end

function Body(props: { process: Process })
	local scrolling_frame = React.useRef(nil)
	local list_layout = React.useRef(nil)

	local elements = {}
	for i, log in props.process.logs do
		if log.type == "input" then
			table.insert(
				elements,
				React.createElement(Log, {
					left_color = Color3.fromRGB(243, 245, 202),
					left = "USER",
					right = log.value,
				})
			)
		elseif log.type == "output" then
			table.insert(
				elements,
				React.createElement(Log, {
					left_color = Color3.fromRGB(163, 163, 163),
					left = `OUT {log.index}`,
					right = pretty(log.value),
				})
			)
		elseif log.type == "error" then
			table.insert(
				elements,
				React.createElement(Log, {
					left_color = Color3.fromRGB(180, 0, 0),
					left = "ERR",
					right = log.value,
				})
			)
		elseif log.type == "info" then
			table.insert(
				elements,
				React.createElement(Log, {
					left_color = Color3.fromRGB(231, 231, 231),
					left = "INFO",
					right = log.value,
				})
			)
		end
	end

	React.useEffect(function()
		scrolling_frame.current.CanvasPosition = Vector2.new(0, scrolling_frame.current.AbsoluteCanvasSize.Y)
	end, { #props.process.logs })

	return React.createElement("ScrollingFrame", {
		LayoutOrder = 2,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		[React.Event.MouseEnter] = function(self)
			TweenService:Create(self, TweenInfo.new(), {
				ScrollBarImageTransparency = 0,
			}):Play()
		end,
		[React.Event.MouseLeave] = function(self)
			TweenService:Create(self, TweenInfo.new(), {
				ScrollBarImageTransparency = 1,
			}):Play()
		end,
		ref = scrolling_frame,
	}, {
		LeftPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 15),
		}),
		ListLayout = React.createElement("UIListLayout", {
			ref = list_layout,
			SortOrder = Enum.SortOrder.LayoutOrder,
			[React.Change.AbsoluteContentSize] = function(self)
				local canvasHeight = list_layout.current.AbsoluteContentSize.Y
				scrolling_frame.current.Size = UDim2.new(1, 0, 0, math.min(300, canvasHeight))
				scrolling_frame.current.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
			end,
		}),
	}, elements)
end

return {
	Body = Body,
}
