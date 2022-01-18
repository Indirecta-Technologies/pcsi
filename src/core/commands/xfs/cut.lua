local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		xfs.cut(args[1])
		essentials.Console.info("Cut "..args[1].." to Clipboard ")

	end,
}

return cmd
