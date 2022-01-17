local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		return xfs.read(args[1])
	end,
}

return cmd
