local cmd = {
	name = script.Name,
	desc = [[Xinu HSE Information]],
	displayOutput = true,
	usage = [[$ uname]],
	fn = function(plr, pCsi, essentials, args)
		--edit to behave more like uname command?

		local info = {
			["Manufacturer"] = essentials.Identification.ProductInfo.Product.Manufacturer;
			["Name"] = essentials.Identification.ProductInfo.Software.Name;
			["Version"] = essentials.Identification.ProductInfo.Software.Version;
			["iScriptRev"] = essentials.Identification.ProductInfo.Software.iScriptRevision;
			["SerN"] = essentials.Identification.SERIAL;
			["HwId"] = essentials.Identification.HWID;
		}
		local toret = ""
		print(game:GetService("HttpService"):JSONEncode(args))
		if args.m then toret ..= "Manufacturer: "..info["Manufacturer"].."\n" end
		if args.n then toret ..= "Name: "..info["Name"].."\n" end
		if args.v then toret ..= "Version: "..info["Version"].."\n" end
		if args.i then toret ..= "integratedScript Revision: "..info["iScriptRev"].."\n" end
		if args.s then toret ..= "Serial Identification Number: "..info["SerN"].."\n" end
		if args.h then toret ..= "Hardware Id: "..info["HwId"].."\n" end
		if args.get then toret = args.get..": "..tostring(args.get) return toret end
		print((not args.m) , (not args.n), (not args.v) , (not args.i) , (not args.s) , (not args.h) , (not args.get))
		if (not args.m) and (not args.n) and (not args.v) and (not args.i) and (not args.s) and (not args.h) and (not args.get) then 
				toret ..= "Manufacturer: "..info["Manufacturer"].."\n"
				toret ..= "Name: "..info["Name"].."\n"
				toret ..= "Version: "..info["Version"].."\n"
				toret ..= "integratedScript Revision: "..info["iScriptRev"].."\n"
				toret ..= "Serial Identification Number: "..info["SerN"].."\n"
				toret ..= "Hardware Id: "..info["HwId"]
		end
		
		return toret
	end,
}

return cmd
