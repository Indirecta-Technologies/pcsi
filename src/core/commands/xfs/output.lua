
local cmd = {
	name = script.Name,
	desc = [[ Output input to a file]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local file = args[1]
		table.remove(args, 1)
		local text = table.concat(args, " ")
		if pCsi.xfs.exists(file) then
			pCsi.xfs.append(file, text)
		else
			pCsi.xfs.mkfile(file)
			pCsi.xfs.append(file, text)
		end
	end,
}

return cmd
