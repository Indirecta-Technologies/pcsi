local cmd = {
	name = script.Name,
	desc = [[Outputs sha256 checksum of input]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local sha256 = pCsi.libs.sha_256
		args = table.concat(args, " ")
		local isFile = pCsi.xfs.exists(args)
		local file = isFile and pCsi.xfs.read(args) or nil

		
		return (isFile and "file: " or "text: ")..sha256().updateStr(isFile and file or args).finish().asHex()
	end,
}

return cmd
