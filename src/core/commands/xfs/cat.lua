
local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local str = pCsi.xfs.read(args[1])
		local buffer = ""
		for char in string.gmatch(str, utf8.charpattern) do --"([%z\1-\127\194-\244][\128-\191]*)"
			buffer ..= char -- show only unicode characters, prevents richtext from breaking
		end
		return (#str == 0 and "(empty)" or buffer):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
	end,
}

return cmd
