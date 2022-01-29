
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.del(args[1])
		essentials.Console.info("Deleted "..args[1])

	end,
}

return cmd
