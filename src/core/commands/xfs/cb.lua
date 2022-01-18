local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		local buffer = {}
		for obj in xfs.list("clipboard") do
			table.insert(buffer, obj.Name.."; Size: "..(xfs:totalBytesInInstance(obj.Name).."siB" or "?").."; Type: "..(xfs.type(obj.Name) or "?"))				
		end
		buffer = table.concat(buffer,";\n")
		essentials.Console.info(buffer)
	end,
}

return cmd
