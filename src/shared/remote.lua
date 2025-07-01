local module = {}
module.get_remote = function(): RemoteFunction
	return module.remote
end
return module
