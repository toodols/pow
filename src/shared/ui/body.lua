local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local TextService = game:GetService "TextService"
local React = require(ReplicatedStorage.Packages.react)
local types = require(script.Parent.Parent.types)
type Process = types.Process

function Log(props: { left: string, left_color: Color3, right: string, RichText: boolean? })
	local params = Instance.new "GetTextBoundsParams"
	params.Text = props.right
	params.Size = 16
	params.Font = Font.fromName("SourceSansPro", Enum.FontWeight.Regular)

	local should_use_expand = TextService:GetTextBoundsAsync(params).Y > 300
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
			RichText = props.RichText or true,
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

function LogEl(props: { left: string, left_color: Color3 })
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
		Right = React.createElement("Frame", {
			LayoutOrder = 2,
		}, props.children),
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
		if value.type == "custom_function" then
			return "<pow function>"
		end
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
	elseif typeof(value) == "Vector3" then
		return `Vector3.new({value.X}, {value.Y}, {value.Z})`
	elseif typeof(value) == "UDim2" then
		return `UDim2.new({value.X}, {value.Y})`
	elseif typeof(value) == "Instance" then
		return `Instance({value.Name})`
	else
		return "<" .. typeof(value) .. ">"
	end
end

local react_symbol = React.createElement("Frame")["$$typeof"]
function is_react_el(el)
	return type(el) == "table" and el["$$typeof"] == react_symbol
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
					right = tostring(log.value),
					RichText = false,
				})
			)
		elseif log.type == "output" then
			if is_react_el(log.value) then
				table.insert(
					elements,
					React.createElement(LogEl, {
						left_color = Color3.fromRGB(163, 163, 163),
						left = `OUT {log.index}`,
					}, {
						Inner = log.value,
					})
				)
				continue
			end
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
					right = tostring(log.value),
				})
			)
		elseif log.type == "info" then
			if is_react_el(log.value) then
				table.insert(
					elements,
					React.createElement(LogEl, {
						left_color = Color3.fromRGB(231, 231, 231),
						left = "INFO",
					}, {
						Inner = log.value,
					})
				)
				continue
			end
			table.insert(
				elements,
				React.createElement(Log, {
					left_color = Color3.fromRGB(231, 231, 231),
					left = "INFO",
					right = tostring(log.value),
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
