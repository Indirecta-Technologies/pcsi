local schedules = {}

local cmd = {
	name = script.Name,
	desc = [[Search for a pattern]],
	usage = [[$ ]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local file = args[1]
		table.remove(1, args)
		local pattern = table.concat(args)
		local function grep(pattern)
			local file = pCsi.xfs.exists(file) and pCsi.xfs.read(file) or file
				local lineNum = 1
				for i,line in ipairs(file.split("\n")) do
					if string.find(line, pattern) ~= nil then
						return lineNum .. ":" .. string.gsub(line, "\n", "")
					end
					lineNum = lineNum + 1
				end
		end
		return grep(pattern)
	end,
}

return cmd
