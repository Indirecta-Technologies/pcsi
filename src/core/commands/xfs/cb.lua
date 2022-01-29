
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local buffer = {}
		for obj in pCsi.xfs.list("clipboard") do
			table.insert(buffer, obj.Name.."; Size: "..(xfs:totalBytesInInstance(obj.Name).."siB" or "?").."; Type: "..(pCsi.xfs.type(obj.Name) or "?"))				
		end
		buffer = table.concat(buffer,";\n")
		essentials.Console.info(buffer)
	end,
}

return cmd
