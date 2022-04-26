
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.del(args[1])
		pCsi.io.write("Deleted "..args[1])

	end,
}

return cmd
