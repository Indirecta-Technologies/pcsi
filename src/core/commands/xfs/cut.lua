
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.cut(args[1])
		essentials.Console.info("Cut "..args[1].." to Clipboard ")

	end,
}

return cmd
