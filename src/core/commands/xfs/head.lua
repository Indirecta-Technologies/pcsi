
local cmd = {
	name = script.Name,
	desc = [[Return the first 10 lines of a file]],
	displayOutput = true,
	usage = [[$ head file.txt 12]],
	fn = function(plr, pCsi, essentials, args)
		local str = pCsi.xfs.read(args[1])
        local lines = tonumber(args[2]) or 10
		local buffer = ""
	
        for i, char in ipairs(string.split(str, "\n")) do
            buffer ..= char.."\n"--"<b>"..tostring(i < 10 and "0"..i or i).."</b> "..char.."\n"
            if i >= lines then break end
        end
        local buffer2 = ""
        for char in string.gmatch(buffer, utf8.charpattern) do
			buffer2 ..= char -- show only unicode characters, prevents richtext from breaking
		end
		return (#buffer2 == 0 and "(empty)" or buffer2):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
	end,
}

return cmd
