local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local React = require(ReplicatedStorage.Packages.react)
local types = require(script.Parent.Parent.types)
type Process = types.Process

function log_props(props)
	props.Size = UDim2.new(1, 0, 0, 25)
	props.TextXAlignment = Enum.TextXAlignment.Left
	props.TextSize = 16
	props.RichText = true
	props.BackgroundTransparency = 1
	props.FontFace = Font.fromName "SourceSansPro"
	props.TextColor3 = Color3.fromRGB(255, 255, 255)
	props.TextEditable = false
	props.ClearTextOnFocus = false
	return props
end

function Body(props: { process: Process })
	local scrolling_frame = React.useRef(nil)
	local list_layout = React.useRef(nil)

	local elements = {}
	for i, log in props.process.logs do
		if log.type == "input" then
			table.insert(
				elements,
				React.createElement(
					"TextBox",
					log_props {
						Text = `<b><font color="#f3f5ca">USER</font></b> <i>{log.value}</i>`,
						LayoutOrder = i,
					}
				)
			)
		elseif log.type == "output" then
			table.insert(
				elements,
				React.createElement(
					"TextBox",
					log_props {
						LayoutOrder = i,
						Text = `<b><font color="#a3a3a3">OUT</font></b> {log.value}`,
					}
				)
			)
		elseif log.type == "error" then
			table.insert(
				elements,
				React.createElement(
					"TextBox",
					log_props {
						LayoutOrder = i,
						Text = `<b><font color="#d00000">ERROR</font></b> {log.value}`,
					}
				)
			)
		elseif log.type == "info" then
			table.insert(
				elements,
				React.createElement(
					"TextBox",
					log_props {
						LayoutOrder = i,
						Text = `<b><font color="#FFFFFF">INFO</font></b> {log.value}`,
					}
				)
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
