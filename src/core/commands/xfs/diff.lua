
local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		return pCsi.xfs.diff(args[1],args[2])
	end,
}

return cmd
