
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.paste(args[1])
		essentials.Console.info("Pasted "..args[1].." from Clipboard to "..pCsi.xfs.cwd())

	end,
}

return cmd
