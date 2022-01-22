local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		xfs.append(args[1], table.concat(args, " ", 2))
		essentials.Console.info("Appended "..#table.concat(args, " ", 2).." bytes to "..args[1].."; File is now "..xfs:totalBytesInInstance(args[1]).." siB")
	end,
}

return cmd
