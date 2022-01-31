
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.append(args[1], table.concat(args, " ", 2))
		essentials.Console.info("Appended "..#table.concat(args, " ", 2).." bytes to "..args[1].."; File is now "..pCsi.xfs:totalBytesInInstance(args[1]).." siB")
	end,
}

return cmd
