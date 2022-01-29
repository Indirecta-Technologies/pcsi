
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.mkdir(args[1])
		essentials.Console.info("Created folder named "..args[1])

	end,
}

return cmd
