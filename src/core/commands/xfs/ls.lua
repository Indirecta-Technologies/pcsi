local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		if args[1] == "-m" then
			local buffer = {}
			for obj in xfs.list() do
				table.insert(buffer, obj.Name.."; Size: "..(xfs:totalBytesInInstance(obj.Name).."siB" or "?").."; Type: "..(xfs.type(obj.Name) or "?"))				
			end
			buffer = table.concat(buffer,";\n")
			essentials.Console.info(buffer)
		else
			local buffer = {}
			local i = 0
			for obj in xfs.list() do
				local name = obj.Name
				if xfs.type(obj.Name) == "Folder" then
					name = "<font color='rgb(28, 119, 255)'>"..name.."</font>"
				elseif xfs.type(obj.Name) == "File" then
					name = "<font color='rgb(39, 175, 55)'>"..name.."</font>"
				elseif xfs.type(obj.Name) == "Link" then
					name = "<font color='rgb(45, 221, 210)'>"..name.."</font>"
				end
				
				table.insert(buffer, (i == 4 and name.."\n" or name))		
				i += 1
			end
			buffer = table.concat(buffer,"  ")
			essentials.Console.info(buffer)
		end
	end,
}

return cmd
