
local cmd = {
	name = script.Name,
	desc = [[Display difference of two files]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local file1,file2 = pCsi.xfs.read(args[1]), pCsi.xfs.read(args[2])

		local output = pCsi.libs.diff(file1,file2).to_richtext()
		essentials.Console.info(output)
	end,
}

return cmd
