

local cmd = {
	name = script.Name,
	desc = [[Output the input]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		
		local function hex_dump(buf)
			local buffer = ""
			for byte=1, #buf, 16 do
				local chunk = buf:sub(byte, byte+15)
				buffer ..= (string.format('%08X  ',byte-1))
				chunk:gsub('.', 
					function (c) 
						buffer ..= (string.format('%02X ',string.byte(c))) 
				end)
				buffer ..= (string.rep(' ',3*(16-#chunk)))
				buffer ..= (' '..chunk:gsub('%c','.').."\n") 
			end
			return buffer
		end
		
		if pCsi.xfs.exists(table.concat(args, " ")) then
			return hex_dump(pCsi.xfs.read(table.concat(args, " ")))
		else
			return hex_dump(table.concat(args, " "))
		end
	end,
}

return cmd
