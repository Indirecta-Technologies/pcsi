local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		local oldBytes = xfs:totalBytesInInstance(args[1])
		xfs.compress(args[1])
		local newBytes = xfs:totalBytesInInstance(args[1])

		essentials.Console.info("Compressed "..args[1]..": "..oldBytes.." siB --> "..newBytes.." siB")
	end,
}

return cmd
