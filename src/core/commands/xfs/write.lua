local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[]],
	usage = [[$ ]],
	fn = function(pCsi, essentials,args)
		local name = args[1]
		table.remove(args, 1)
		args = table.concat(args, " ")
		xfs.write(name, args)
	end,
}

return cmd
