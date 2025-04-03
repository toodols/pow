local ReplicatedStorage = game:GetService "ReplicatedStorage"
local pow_remote = ReplicatedStorage:FindFirstChild "Pow"
if not pow_remote or not pow_remote:IsA "RemoteFunction" then
	warn "cant find pow remote"
	return
end

function report_server(process)
	pow_remote:InvokeServer("telemetry", process)
end

return { report_server = report_server }
