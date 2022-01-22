local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		return xfs.diff(args[1],args[2])
	end,
}

return cmd
