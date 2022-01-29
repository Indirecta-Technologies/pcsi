
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local name = args[1]
		table.remove(args, 1)
		args = table.concat(args, " ")
		pCsi.xfs.write(name, args)
	end,
}

return cmd
