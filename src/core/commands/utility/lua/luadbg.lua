local xfs = require(script.Parent.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))
local luadbg = require(script.Parent.Parent.Parent.Parent.lib.luaDbg)

local cmd = {
	name = script.Name,
	desc = [[Examine Lua bytecode including VM specs, prototypes, upvalues, constants and instructions]],
	usage = "$ luadbg -e filename", --TO REDO
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		
		if args[1] and args[1] == "-e" then --examine
			local name = args[2]
			local bytecode;
			if xfs.exists(name) then 
				bytecode = xfs.read(name)
				local data = luadbg.Debug(bytecode)
				return data or nil;
			 else 
				error("unable to read file "..name) 
			
			end
		end
	

	end,
}

return cmd
