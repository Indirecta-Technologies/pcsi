local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))
local loadstr = require(script.Parent.Parent.Parent.lib.luau)



local cmd = {
	name = script.Name,
	desc = [[Run luau instructions in a sandboxed enviroment]],
	usage = "$ luau compile|interpret|environment (filename) ",
	displayOutput = false,
	fn = function(pCsi, essentials, args)
		local loadstr = require(script.Parent.Parent.Parent.lib.luau)
		-- feel free to add more globals to your environment,
		-- but it may pose a security risk
		local enviroment = {}
		local ver = "LuaJIT 1.3"
		local lev = 1
		
		local oldparse = pCsi.parseCommand
		
		
		enviroment.math = math
		enviroment.print = essentials.Console.info
		enviroment.warn = essentials.Console.warn
		enviroment.error = function(...)
			local errortxt = "stdin:"..lev..": "..table.concat({...}, " ")..debug.traceback("\nstack traceback: ",2)
			essentials.Console.error(errortxt)
		end
		enviroment.wait = task.wait
		enviroment.bit32 = bit32
		enviroment.string = string

		enviroment.Xinu = essentials
		enviroment.pCsi = pCsi

		enviroment.table = table
		enviroment.pcall = pcall
		enviroment.task = task
		enviroment.spawn = spawn
		enviroment.os = os
		enviroment.tick = tick
		enviroment.utf8 = utf8
		enviroment._G = essentials.Freestore
		enviroment._VERSION = ver
		
		local function exec(cmd)
			if cmd == "" then error("luau string is empty") return nil end

			local bytecode, err = loadstr.compile("stdin"..lev, cmd)
			local output, err1 = loadstr.interpret(bytecode, enviroment)

			if err then return enviroment.error("compiler error: "..err) end
			if err1 then return enviroment.error("interpreter error: "..err) end

			return output()
		end
		
		if xfs.exists(table.concat(args, " ")) then
			lev = 2
			return exec(xfs.read(table.concat(args, " ")))
		elseif args[1] then
			lev = 1
			return exec(table.concat(args, " "))
		else
			essentials.Console.info(ver.." -- Copyright (C) Indirecta Technologies 2022, Inspired by Mike Pall's Just In Time Lua interpreter")
			essentials.Console.info("Input 'exit' to return to shell")
			function pCsi:parseCommand(args)
				essentials.Console.info(string.rep(">",lev).." "..args)
				args = string.split(args, " ")
				if args[1] == "exit" then
					self.parseCommand = oldparse
					return
				else
					lev = (lev == 1 and 2 or 1)
					exec(table.concat(args, " "))
				end
			end

		end
		
		
		
	
	end,
}

return cmd
