
local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		return pCsi.xfs.fullCwd()
	end,
}

return cmd
