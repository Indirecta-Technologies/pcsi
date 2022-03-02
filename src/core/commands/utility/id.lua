local cmd = {
	name = script.Name,
	desc = [[User Information]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		return plr.Name.." "..plr.UserId.." "..plr.AccountAge.." "..pCsi.libs.sha_256().updateStr(tostring(plr.UserId)).finish().asHex()
	end,
}

return cmd
