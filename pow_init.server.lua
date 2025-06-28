local ServerScriptService = game:GetService "ServerScriptService"
local pow = require(ServerScriptService.pow)
pow.init {
	permissions = {
		owner = {
			["195294332"] = 5,
			["-1"] = 5,
		},
	},
}
