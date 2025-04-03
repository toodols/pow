local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(script.Parent.Parent.types)
type Process = types.Process

function TabButton(props: { current_tab: string, process: Process, on_remove: () -> (), select_tab: () -> () })
	return React.createElement("TextButton", {
		Text = "",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		[React.Event.MouseButton1Click] = function()
			props.select_tab()
		end,
	}, {
		React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				LayoutOrder = 1,
				Text = props.process.name or "Unnamed",
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				FontFace = Font.fromName "SourceSansPro",
			}),
			React.createElement("Frame", {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
			}, {
				React.createElement("UIAspectRatioConstraint", {
					AspectRatio = 1,
				}),
				React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6031094678",
					Size = UDim2.new(0, 13, 0, 13),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					[React.Event.MouseEnter] = function(self)
						self.ImageColor3 = Color3.fromRGB(255, 0, 0)
					end,
					[React.Event.MouseLeave] = function(self)
						self.ImageColor3 = Color3.fromRGB(255, 255, 255)
					end,
					[React.Event.MouseButton1Click] = function()
						props.on_remove()
					end,
				}),
			}),
			React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 0),
			}),
		}),
		React.createElement("Frame", {
			Visible = props.current_tab == props.process.id,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(44, 195, 255),
			Size = UDim2.new(1, 0, 0, 2),
		}),
	})
end

function TabBar(props: {
	tabs: { [string]: Process },
	current_tab: string,
	select_tab: (id: string) -> (),
	new_tab: () -> (),
	remove_tab: (id: string) -> (),
})
	local scrolling_frame = React.useRef(nil)
	local tabs = {}
	for id, process in props.tabs do
		tabs[id] = React.createElement(TabButton, {
			process = process,
			current_tab = props.current_tab,
			select_tab = function()
				props.select_tab(id)
			end,
			on_remove = function()
				props.remove_tab(id)
			end,
		})
	end
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 31),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 1),
		}),
		React.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -31, 1, -1),
			CanvasSize = UDim2.new(0, 0, 1, 0),
			ScrollBarThickness = 0,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ref = scrolling_frame,
		}, {
			ListLayout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 1),
				FillDirection = Enum.FillDirection.Horizontal,
			}),
		}, tabs),
		React.createElement("TextButton", {
			Size = UDim2.new(1, 0, 1, -1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Text = "",
			[React.Event.MouseButton1Click] = function()
				props.new_tab()
			end,
		}, {
			React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
			React.createElement("ImageLabel", {
				Image = "http://www.roblox.com/asset/?id=6035047377",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
			}),
		}),
	})
end

return {
	TabBar = TabBar,
}
