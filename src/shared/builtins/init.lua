local ContextActionService = game:GetService "ContextActionService"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local parser = require(script.Parent.parser)
local types = require(script.Parent.types)
local builtin_types = require(script.types).builtin_types
local builtin_commands = require(script.commands).builtin_commands

type Context = types.Context
type Type = types.Type
type Expression = parser.Expression

local builtin_permission_types = {
	-- hard-coded role that automatically has all permissions,
	-- present and future, and thus does not need explicit derived roles
	root = {},

	-- standard 5-tier roles found in most admin commands
	owner = { "admin" },
	admin = { "moderator", "control_flow", "automation", "variables" },
	moderator = { "vip", "fun", "math", "view_permissions" },
	vip = { "normal" },
	normal = { "debug" },

	-- other partial permission types
	fun = {},
	debug = {},
	math = {},
	automation = {},
	variables = {},
	control_flow = {},
	view_permissions = {},
}

local builtin_client_requests = {}

local flying_cleanup = function() end

function builtin_client_requests.set_flying(new_val: boolean)
	flying_cleanup()
	if new_val then
		local character = Players.LocalPlayer.Character
		local humanoid: Humanoid = character:FindFirstChildOfClass "Humanoid"
		local root_part: Part = character.HumanoidRootPart

		local camera = workspace.CurrentCamera
		local attachment = Instance.new "Attachment"
		attachment.Parent = root_part

		local align_orientation = Instance.new "AlignOrientation"
		align_orientation.Parent = root_part
		align_orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align_orientation.RigidityEnabled = true
		align_orientation.CFrame = root_part.CFrame

		local align_position = Instance.new "AlignPosition"
		align_position.Parent = root_part
		align_position.Position = root_part.Position
		align_position.Mode = Enum.PositionAlignmentMode.OneAttachment
		align_position.RigidityEnabled = true
		align_position.Responsiveness = 1000

		align_orientation.Attachment0 = attachment
		align_position.Attachment0 = attachment

		local move_vector = Vector3.new()
		local keys = {}
		local function update_move_vector()
			move_vector = Vector3.new(
				(if keys[Enum.KeyCode.D] then 1 else 0) - (if keys[Enum.KeyCode.A] then 1 else 0),
				(if keys[Enum.KeyCode.E] then 1 else 0) - (if keys[Enum.KeyCode.Q] then 1 else 0),
				(if keys[Enum.KeyCode.S] then 1 else 0) - (if keys[Enum.KeyCode.W] then 1 else 0)
			).Unit
		end
		ContextActionService:BindAction(
			"fly",
			function(action_name, input_state: Enum.UserInputState, input_object: InputObject)
				keys[input_object.KeyCode] = input_state == Enum.UserInputState.Begin
				update_move_vector()
			end,
			false,
			Enum.KeyCode.A,
			Enum.KeyCode.S,
			Enum.KeyCode.W,
			Enum.KeyCode.D,
			Enum.KeyCode.E,
			Enum.KeyCode.Q
		)
		local render_conn = RunService.RenderStepped:Connect(function()
			if move_vector.Magnitude > 0 then
				align_position.Position = root_part.Position + root_part.CFrame:VectorToWorldSpace(move_vector)
			end
			align_orientation.CFrame = camera.CFrame
		end)
		humanoid.PlatformStand = true

		flying_cleanup = function()
			humanoid.PlatformStand = false
			ContextActionService:UnbindAction "fly"
			attachment:Destroy()
			align_orientation:Destroy()
			align_position:Destroy()
			render_conn:Disconnect()
		end
	end
end

return {
	builtin_commands = builtin_commands,
	builtin_permission_types = builtin_permission_types,
	builtin_types = builtin_types,
	builtin_client_requests = builtin_client_requests,
}
