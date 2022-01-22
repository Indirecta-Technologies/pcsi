local cmd = {
	name = script.Name,
	desc = [[Displays info about Xinu]],
	usage = [[$ info]],
	fn = function(plr, pCsi, essentials, args)
		essentials.Console.info("-- System Information --\n"..
			"Manufacturer: "..essentials.Identification.ProductInfo.Product.Manufacturer.."\n"..
			"Name: "..essentials.Identification.ProductInfo.Software.Name.."\n"..
			"Version: "..essentials.Identification.ProductInfo.Software.Version.."\n"..
			"Serial Identification Number: "..essentials.Identification.SERIAL.."\n"..
			"-- End of System Info --"
		)
	end,
}

return cmd
