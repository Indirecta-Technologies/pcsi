
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.write(args[1], table.concat(args, " ", 2))
	end,
}

return cmd
