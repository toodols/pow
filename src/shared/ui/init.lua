local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local TabBar = require(script.tab_bar).TabBar
local Body = require(script.body).Body
local CommandBar = require(script.command_bar).CommandBar
local types = require(script.Parent.types)

local local_player = Players.LocalPlayer

type Process = types.Process
type PowClient = types.PowClient

function Main(props: { pow_client: PowClient, ui: any })
	local is_open, set_is_open = React.useState(false)
	local pow_client = props.pow_client
	local process = pow_client.tabs[pow_client.current_tab]
	local input_ref = React.useRef(nil)
	props.ui.input_ref = input_ref

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 50),
		Size = UDim2.new(1, -40, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = is_open,
	}, {
		VerticalLayout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		}),
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(1000, math.huge),
		}),
		TabBar = React.createElement(TabBar, {
			tabs = pow_client.tabs,
			current_tab = pow_client.current_tab,
			new_tab = pow_client.new_tab,
			remove_tab = pow_client.remove_tab,
			select_tab = pow_client.select_tab,
		}),
		Body = React.createElement(Body, {
			process = process,
		}),
		CommandBar = React.createElement(CommandBar, {
			is_open = is_open,
			set_is_open = set_is_open,
			submit_command = pow_client.submit_command,
			process = process,
			input_ref = input_ref,
		}),
	})
end

function init_ui(pow_client)
	local nonce = 0
	local root_inst = Instance.new "ScreenGui"
	root_inst.Parent = local_player:WaitForChild "PlayerGui"
	root_inst.ResetOnSpawn = false
	root_inst.IgnoreGuiInset = true
	root_inst.Name = "PowGui"
	root_inst.DisplayOrder = 7
	local root = ReactRoblox.createRoot(root_inst)
	local ui = {}
	root:render(React.createElement(Main, { nonce = nonce, pow_client = pow_client, ui = ui }))

	ui.update = function(new_props)
		nonce += 1
		root:render(React.createElement(Main, { nonce = nonce, pow_client = pow_client, ui = ui }))
	end
	
	return ui
end

return {
	init_ui = init_ui,
}
