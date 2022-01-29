
local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		if args[1] == "-m" then
			local buffer = {}
			for obj in pCsi.xfs.list() do
				local bytes = xfs:totalBytesInInstance(obj.Name)
				bytes = xfs:formatBytesToUnits(bytes)
				table.insert(buffer, obj.Name.."; Size: "..bytes.."; Type: "..(pCsi.xfs.type(obj.Name) or "?").."; Mime: "..xfs:fileType(obj.Name))				
			end
			buffer = table.concat(buffer,";\n")
			essentials.Console.info(buffer)
		else
			local buffer = {}
			local i = 0
			for obj in pCsi.xfs.list() do
				local name = obj.Name
				if pCsi.xfs.type(obj.Name) == "Folder" then
					name = "<font color='rgb(28, 119, 255)'>"..name.."</font>"
				elseif pCsi.xfs.type(obj.Name) == "File" then
					name = "<font color='rgb(39, 175, 55)'>"..name.."</font>"
				elseif pCsi.xfs.type(obj.Name) == "Link" then
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
