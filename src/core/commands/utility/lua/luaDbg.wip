local xfs = require(script.Parent.Parent.Parent.fs:WaitForChild("xfsm",12))

local cmd = {
	name = script.Name,
	desc = [[Translates programs written in the Luau programming language into binary files that can be later loaded and executed.]],
	usage = "$ luau compile|interpret|environment (filename) ", --TO REDO
	displayOutput = false,
	fn = function(pCsi, essentials,args)
		local loadstr = require(script.Parent.Parent.Parent.lib.luau)
		-- feel free to add more globals to your environment,
		-- but it may pose a security risk
		local enviroment = {}
		enviroment.math = math
		enviroment.print = essentials.Console.info
		enviroment.warn = essentials.Console.warn
		enviroment.error = essentials.Console.error
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
		
		
		
		if args[1] and args[1] == "compile" then
			local name = args[2]
			local plaintext;
			if xfs.exists(name) then plaintext = xfs.read(name) else error("unable to read file "..name) end
			local ctick = tick()
			local bytecode, err = loadstr.compile(name,plaintext)
			if not bytecode or err then error(err) end
			if not args[3] then args[3] = "output.luac"end
				if xfs.exists(args[3]) then
				else
					xfs.mkfile(args[3])
				end
			xfs.write(args[3], bytecode)
			local btick = tick()

			essentials.Console.info("Compiled "..name.." to "..args[3].." in ".. btick-ctick .." seconds, tot. siB "..xfs:totalBytesInInstance(args[3]))
		elseif args[1] and args[1] == "interpret" then
			local name = args[2]
			local plaintext;
			print("aha")
			if xfs.exists(name) then 
				
				plaintext = xfs.read(name) 
				
			else 
				error("unable to read file "..name)
				
			end
			print(plaintext)
			local interpet, err = loadstr.interpret(plaintext, enviroment)
			print("obbbb")
			if not interpet or err then error(err)  end
			local output = interpet()
			
			if type(output) == "string" or type(output) == "table" or type(output) == "number" or type(output) == "number" and args[3] and output then
				if xfs.exists(args[3]) then
					xfs.write(args[3], output)
				else
					xfs.mkfile(args[3])
					xfs.write(args[3], output)
				end
			else
				return output
			end

			
			return 
		
		elseif args[1] and args[1] == "environment" then
			essentials.Console.info(game:GetService("HttpService"):JSONEncode(enviroment))
		end
	

	end,
}

return cmd
