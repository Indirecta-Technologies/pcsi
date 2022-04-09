
local cmd = {
	name = script.Name,
	desc = [[Display difference of two files]],
	displayOutput = true,
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local file1,file2 = pCsi.xfs.read(args[1]), pCsi.xfs.read(args[2])

		--  return difference between file1 and file2
		--[[local diff = {}
		local line_no = 0
		for line in file1:gmatch("[^\r\n]+") do
			line_no = line_no + 1
			if not file2:find(line, 1, true) then
				diff[#diff+1] = line_no
			end
		end
		return #diff == 0 and "(empty)" or table.concat(diff, "\n")]]

		local output = pCsi.libs.diff(file1,file2).to_richtext()
		essentials.Console.info(output)
	end,
}

return cmd
