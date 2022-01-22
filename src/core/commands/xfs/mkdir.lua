local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		xfs.mkdir(args[1])
		essentials.Console.info("Created folder named "..args[1])

	end,
}

return cmd
