local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[ Output input to a file]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		local file = args[1]
		table.remove(args, 1)
		local text = table.concat(args, " ")
		if xfs.exists(file) then
			xfs.append(file, text)
		else
			xfs.mkfile(file)
			xfs.append(file, text)
		end
	end,
}

return cmd
