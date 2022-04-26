
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		pCsi.xfs.paste(args[1])
		pCsi.io.write("Pasted "..args[1].." from Clipboard to "..pCsi.xfs.cwd())

	end,
}

return cmd
