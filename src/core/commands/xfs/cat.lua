local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local str = xfs.read(args[1])
		local buffer = ""
		for char in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
			buffer ..= char -- show only unicode characters, prevents richtext from breaking
		end
		return (#str == 0 and "(empty)" or str):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
	end,
}

return cmd
