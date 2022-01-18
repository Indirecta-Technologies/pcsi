local xfs = require(script.Parent.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))
local luac = require(script.Parent.Parent.Parent.Parent.lib.luac)
local fione = require(script.Parent.Parent.Parent.Parent.lib.fione)



local cmd = {
	name = script.Name,
	desc = [[Run luau instructions in a sandboxed enviroment]],
	usage = "$ luau compile|interpret|environment (filename) ",
	displayOutput = false,
	fn = function(pCsi, essentials, args)
		-- feel free to add more globals to your environment,
		-- but it may pose a security risk
		local environment = {}
		local ver = "LuaJIT 1.3"
		local lev = 1
		
		local oldparse = pCsi.parseCommand
		
		local customerror = function(...)
			local errortxt = table.concat({...}, " ")
			print(errortxt)
			essentials.Console.error(errortxt)
		end

		environment.math = math
		environment.print = essentials.Console.info
		environment.warn = essentials.Console.warn
		environment.error = essentials.Console.error

		environment.wait = task.wait
		environment.bit32 = bit32
		environment.string = string

		environment.Xinu = essentials
		environment.pCsi = pCsi

		environment.table = table
		environment.pcall = pcall
		environment.task = task
		environment.spawn = task.spawn
		environment.os = os
		environment.tick = tick
		environment.utf8 = utf8
		environment._G = essentials.Freestore
		environment._VERSION = ver
		
		local function exec(cmd)
			if cmd == "" then error("luau string is empty") return nil end
			local output;

			local success, err2 = pcall(function()
				local bytecode, err = luac(cmd, "stdin", customerror)
				print(bytecode)
				
				local err1
				output, err1 = fione(bytecode, customerror, environment)
				
	
				if err then return customerror("compiler error: "..err) end
				if err1 then return customerror("interpreter error: "..err) end
			end)
			
			if not success or err2 then return nil end

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
