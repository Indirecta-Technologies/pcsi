local cmd = {
	name = script.Name,
	desc = [[Outputs sha256 of input]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local sha256 = require(script.Parent.Parent.Parent.lib.sha_256)
		return sha256().updateStr(table.concat(args, " ")).finish().asHex()
	end,
}

return cmd
