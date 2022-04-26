local cmd = {
	name = script.Name,
	desc = [[]],
	usage = "$ ",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)

		return pCsi.libs.fortunecookie()
	end,
}

return cmd
