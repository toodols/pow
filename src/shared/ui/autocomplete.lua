local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"
local React = require(ReplicatedStorage.Packages.react)
local types = require(script.Parent.Parent.types)
type Suggestion = types.Suggestion

function Autocomplete(props: {
	offset: number,
	suggestions: { Suggestion },
	type: string?,
	title: string?,
	description: string?,
	aside_title: string?,
	aside_description: string?,
	index: number,
	set_index: ((index: number) -> ()) -> (),
	select: (option: Suggestion) -> (),
	suppress_tab: () -> (),
})
	local suggestions_ref = React.useRef(nil)
	local selected_item = React.useRef(nil)

	React.useEffect(function()
		if props.suggestions ~= nil then
			local user_input_connection = UserInputService.InputBegan:Connect(function(input_obj)
				if input_obj.KeyCode == Enum.KeyCode.Down then
					props.set_index(function(idx)
						return (idx + 1) % #props.suggestions
					end)
				elseif input_obj.KeyCode == Enum.KeyCode.Up then
					props.set_index(function(idx)
						return (idx - 1) % #props.suggestions
					end)
				elseif input_obj.KeyCode == Enum.KeyCode.Tab then
					if props.suggestions[props.index + 1] then
						props.suppress_tab()
						props.select(props.suggestions[props.index + 1])
					end
				end
			end)

			return function()
				user_input_connection:Disconnect()
			end
		else
			return function() end
		end
	end, {
		props.suggestions,
		props.index,
	})

	React.useEffect(function()
		if selected_item.current == nil or suggestions_ref.current == nil then
			return
		end
		if
			selected_item.current.AbsolutePosition.Y
			> suggestions_ref.current.AbsolutePosition.Y
				+ suggestions_ref.current.AbsoluteSize.Y
				- selected_item.current.AbsoluteSize.Y
		then
			local offset = selected_item.current.AbsolutePosition.Y
				- suggestions_ref.current.AbsolutePosition.Y
				+ suggestions_ref.current.CanvasPosition.Y
				- suggestions_ref.current.AbsoluteSize.Y
				+ selected_item.current.AbsoluteSize.Y
			suggestions_ref.current.CanvasPosition = Vector2.new(0, offset)
		elseif selected_item.current.AbsolutePosition.Y < suggestions_ref.current.AbsolutePosition.Y then
			local offset = selected_item.current.AbsolutePosition.Y
				- suggestions_ref.current.AbsolutePosition.Y
				+ suggestions_ref.current.CanvasPosition.Y
			suggestions_ref.current.CanvasPosition = Vector2.new(0, offset)
		end
	end, { props.index })

	local items = {}
	if props.suggestions then
		for sidx, suggestion in props.suggestions do
			local text = suggestion.display_text or suggestion.text
			table.insert(
				items,
				React.createElement("TextButton", {
					Size = UDim2.new(1, 0, 0, 25),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					BackgroundColor3 = if sidx == props.index + 1
						then Color3.fromRGB(11, 50, 50)
						else Color3.fromRGB(0, 0, 0),
					RichText = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ref = if sidx == props.index + 1 then selected_item else nil,
					[React.Event.MouseButton1Down] = function()
						props.select(suggestion)
					end,
					Text = "  " .. text:sub(1, suggestion.match_start - 1) .. '<font color="#50C0FF">' .. text:sub(
						suggestion.match_start,
						suggestion.match_end
					) .. "</font>" .. text:sub(suggestion.match_end + 1),
				})
			)
		end
	end

	local current_suggestion = props.suggestions and props.suggestions[props.index + 1]
	return React.createElement(React.Fragment, {}, {
		Left = React.createElement("Frame", {
			Size = UDim2.new(0, 200, 0, 0),
			Position = UDim2.new(0, props.offset, 1, 2),
			BackgroundTransparency = 1,
		}, {
			VerticalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Info = React.createElement("Frame", {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
			}, {
				ListLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Title = React.createElement("TextLabel", {
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 25),
					LayoutOrder = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					RichText = true,
					Text = `{props.title or "<title>"}: <i>{props.type or "<type>"}</i>`,
					TextSize = 10,
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				}, {
					LeftPadding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
					}),
				}),
				Description = if true
					then React.createElement("TextLabel", {
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 25),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Text = props.description or "No description",
						TextWrapped = true,
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					}, {
						LeftPadding = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
							PaddingBottom = UDim.new(0, 10),
						}),
					})
					else nil,
			}),
			Suggestions = if props.suggestions
				then React.createElement("ScrollingFrame", {
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BackgroundTransparency = 0.9,
					ScrollBarThickness = 4,
					ref = suggestions_ref,
				}, {
					ListLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						[React.Change.AbsoluteContentSize] = function(self)
							self.Parent.CanvasSize = UDim2.new(0, 0, 0, self.AbsoluteContentSize.Y)
							self.Parent.Size = UDim2.new(1, 0, 0, math.clamp(self.AbsoluteContentSize.Y, 10, 150))
						end,
					}),
				}, items)
				else nil,
		}),

		Right = if current_suggestion and current_suggestion.title or props.aside_title
			then React.createElement("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0, props.offset + 201, 1, 2),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			}, {
				ListLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Title = React.createElement("TextLabel", {
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(0, 0, 0, 25),
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					RichText = true,
					Text = props.aside_title or current_suggestion.title,
					TextSize = 10,
					BackgroundTransparency = 1,
				}, {
					LeftPadding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
					}),
				}),
				Description = if true
					then React.createElement("TextLabel", {
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 2,
						RichText = true,
						TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.XY,
						Size = UDim2.new(0, 0, 0, 25),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Text = props.aside_description
							or current_suggestion and current_suggestion.description
							or "No description",
						BackgroundTransparency = 1,
					}, {
						MinSize = React.createElement("UISizeConstraint", {
							MinSize = Vector2.new(200, 0),
						}),
						Padding = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
							PaddingRight = UDim.new(0, 10),
						}),
					})
					else nil,
			})
			else nil,
	})
end

return {
	Autocomplete = Autocomplete,
}
