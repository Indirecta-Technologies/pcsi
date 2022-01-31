
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local oldBytes = pCsi.xfs:totalBytesInInstance(args[1])
		pCsi.xfs.compress(args[1])
		local newBytes = pCsi.xfs:totalBytesInInstance(args[1])

		essentials.Console.info("Compressed "..args[1]..": "..oldBytes.." siB --> "..newBytes.." siB")
	end,
}

return cmd
