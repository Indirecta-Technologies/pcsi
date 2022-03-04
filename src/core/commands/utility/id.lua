local cmd = {
	name = script.Name,
	desc = [[User Information]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local LocalizationService = game:GetService("LocalizationService")

		local nation = "?"
		--Methods||
		local success, code = pcall(function()
			--Get the country code
			nation = LocalizationService:GetCountryRegionForPlayerAsync(plr)
		end)

		return plr.Name
			.. " "
			.. plr.UserId
			.. " "
			.. plr.AccountAge
			.. " "
			.. (success and nation or "")
			.. " "
			.. pCsi.libs.sha_256().updateStr(tostring(plr.UserId..nation)).finish().asHex()
	end,
}

return cmd
