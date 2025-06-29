local RunService = game:GetService "RunService"

local types = require(script.Parent.Parent.types)
local admin_commands = require(script.admin)
local control_flow_commands = require(script.control_flow)
local debug_commands = require(script.debug)
local variable_commands = require(script.variables)
local math_commands = require(script.math)
local instances_commands = require(script.instances)

type Context = types.Context

local builtin_commands: {
	[string]: {
		run: ((Context) -> any)?,
		server_run: ((Context) -> any)?,
		description: string?,
		alias: { string }?,
		permissions: { string }?,
		overloads: { { returns: string, args: { { name: string, type: string } } } }?,
	},
} =
	{}

builtin_commands.clear = {
	description = "clears the console.",
	permissions = { "debug" },
	client_run = function(context: Context)
		context.process.logs = {}
	end,
	overloads = {
		{ returns = "nil", args = {} },
	},
}

builtin_commands.help = {
	description = "Help",
	permissions = {},
	overloads = {
		{ returns = "nil", args = {} },
	},
	client_run = function(context: Context)
		local React = context.React

		local function text(props)
			props.BackgroundTransparency = 1
			props.AutomaticSize = Enum.AutomaticSize.XY
			props.TextColor3 = Color3.fromRGB(255, 255, 255)
			props.FontFace = Font.fromName "SourceSansPro"
			props.TextXAlignment = Enum.TextXAlignment.Left
			props.RichText = true
			props.Size = UDim2.new(0, 0, 0, props.TextSize + 10)
			return props
		end

		local function Runnable(props: { text: string, LayoutOrder: number? })
			return React.createElement("TextButton", {
				BackgroundTransparency = 0.9,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Size = UDim2.new(1, -20, 0, 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.fromEnum(Enum.Font.Code),
				Text = props.text,
				LayoutOrder = props.LayoutOrder,
				AutomaticSize = Enum.AutomaticSize.XY,
				[React.Event.MouseButton1Click] = function()
					context.process.set_input_text(props.text)
				end,
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				}),
			})
		end

		local function HelpMenu()
			return React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 0.95,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				}),
				VerticalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Title = React.createElement(
					"TextLabel",
					text {
						TextSize = 22,
						Text = "Pow Interactive Help Menu",
						LayoutOrder = 10,
					}
				),
				SourceCode = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Source is available on Github: toodols/pow",
						LayoutOrder = 15,
					}
				),
				P1 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "A command is a <b>command name</b> and any number of arguments separated by <b>spaces</b>.",
						LayoutOrder = 20,
					}
				),
				Runnable1 = React.createElement(Runnable, {
					text = `print hello`,
					LayoutOrder = 30,
				}),

				P2 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "<i>Click the code samples to input in the command bar.</i>",
						LayoutOrder = 40,
					}
				),
				PermissionWarning = if not context.process.config.user_permissions.moderator
					then React.createElement(
						"TextLabel",
						text {
							TextSize = 16,
							Text = "<b>You may not have the necessary permissions to run these commands.</b>",
							LayoutOrder = 45,
						}
					)
					else nil,
				P3 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Arguments may be wrapped in quotes to include spaces",
						LayoutOrder = 50,
					}
				),
				Runnable2 = React.createElement(Runnable, {
					text = `print "Hello World"`,
					LayoutOrder = 60,
				}),
				P4 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Some commands take more than one argument",
						LayoutOrder = 70,
					}
				),
				Runnable3 = React.createElement(Runnable, {
					text = `add 123 777`,
					LayoutOrder = 80,
				}),
				P5 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "The values returned by commands can be passed to other commands. Using parentheses",
						LayoutOrder = 90,
					}
				),
				Runnable4 = React.createElement(Runnable, {
					text = `speed {context.executor.Name} (add 20 10)`,
					LayoutOrder = 100,
				}),
				P6 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Nest as many parentheses as you like.\nBelow: <i>Read as: speed = (1+5)*(3+3)</i>",
						LayoutOrder = 110,
					}
				),
				Runnable5 = React.createElement(Runnable, {
					text = `speed {context.executor.Name} (mul (add 1 5) (add 3 3))`,
					LayoutOrder = 120,
				}),

				P7 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Functions are constructed with brackets",
						LayoutOrder = 130,
					}
				),
				Runnable6 = React.createElement(Runnable, {
					text = `repeat 5 \{print hello}`,
					LayoutOrder = 140,
				}),
				P8 = React.createElement(
					"TextLabel",
					text {
						TextSize = 16,
						Text = "Chain commains with semicolon",
						LayoutOrder = 150,
					}
				),
				Runnable7 = React.createElement(Runnable, {
					text = `print hello; wait 1; print world`,
					LayoutOrder = 160,
				}),
				-- e = React.createElement(
				-- 	"TextLabel",
				-- 	text {
				-- 		TextSize = 16,
				-- 		Text = "Special player arguments: @me, @others, @all",
				-- 		LayoutOrder = 130,
				-- 	}
				-- ),
				-- f = React.createElement(Runnable, {
				-- 	text = `teleport @others @me`,
				-- 	LayoutOrder = 140,
				-- }),
			})
		end
		context:log {
			type = "info",
			value = React.createElement(HelpMenu),
		}
	end,
}

builtin_commands.bind_tool = {
	description = "Binds a tool to a function",
	permissions = { "moderator" },
	server_run = function(context)
		local tool = context.args[1]
		tool.Activated:Connect(function()
			context.runtime.run_function(context.process, context.args[2])
		end)
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{ name = "Tool", type = "instance" },
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

builtin_commands.bind = {
	description = "Binds a function to a key",
	permissions = { "moderator" },
	client_run = function(context)
		context.process.bindings[context.args[1]] = context.args[2]
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Key",
					type = "keycode",
				},
				{
					name = "Function",
					type = "function",
				},
			},
		},
	},
}

builtin_commands.unbind = {
	description = "Unbinds a function from a key",
	permissions = { "moderator" },
	client_run = function(context)
		context.process.bindings[context.args[1]] = nil
	end,
	overloads = {
		{
			returns = "nil",
			args = {
				{
					name = "Key",
					type = "keycode",
				},
			},
		},
	},
}

builtin_commands.commands = {
	alias = { "cmds" },
	description = "Lists commands",
	permissions = {},
	client_run = function(context: Context)
		local text = ""
		for _, f in context.process.global_scope.functions.functions do
			text ..= `{f.name} - {f.description}\n`
		end
		context:log {
			type = "info",
			value = text,
		}
	end,
	overloads = {
		{
			returns = "nil",
			args = {},
		},
	},
}

builtin_commands.get_run_context = {
	description = "Returns whether this command is being ran on the server or the client",
	permissions = { "moderator" },
	run = function(context)
		if RunService:IsClient() then
			return "client"
		else
			return "server"
		end
	end,
	overloads = {
		{
			returns = "string",
			args = {},
		},
	},
}

for _, commands in
	{ admin_commands, control_flow_commands, debug_commands, variable_commands, math_commands, instances_commands }
do
	for name, command in commands do
		builtin_commands[name] = command
	end
end

return {
	builtin_commands = builtin_commands,
}
