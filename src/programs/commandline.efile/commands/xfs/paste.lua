local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		xfs.paste(args[1])
		essentials.Console.info("Pasted "..args[1].." from Clipboard to "..xfs.cwd())

	end,
}

return cmd
