
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.cut(args[1])
		pCsi.io.write("Cut "..args[1].." to Clipboard ")

	end,
}

return cmd
