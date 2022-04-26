
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.mkfile(args[1])
		pCsi.io.write("Created file named "..args[1])

	end,
}

return cmd
