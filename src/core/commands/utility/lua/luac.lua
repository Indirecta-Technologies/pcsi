local xfs = require(script.Parent.Parent.Parent.Parent.fs:WaitForChild("xfsm", 12))
local luac = require(script.Parent.Parent.Parent.Parent.lib.luac)
local fione = require(script.Parent.Parent.Parent.Parent.lib.fione)
local luadbg = require(script.Parent.Parent.Parent.Parent.lib.luaDbg)

local cmd = {
	name = script.Name,
	desc = [[Translates programs written in the Luau programming language into binary files that can be later loaded and executed]],
	usage = [[-s|-strip - Strips debug information when compiling

	-c|-compile - Compiles input file to output or to "luac.out"

	-l|-load - Load input file and output what it returns if there is a file

	-o|-output - Output file, outputs bytecode if is compiling or function return if interpreting

	Examples:
		luac -c helloworld.luau -o helloworld.luac
		luac -s -c helloworld.luau
		luac -l helloworld.luac
		luac -l 1000digitsofpi.luac -o 1000digitsofpi.txt
		
	]], --TO REDO
	displayOutput = false,
	fn = function(pCsi, essentials, args)
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

	

		local options = { File = "", Compile = false, Load = false, OutFile = "", Strip = false }
		if not args or #args == 0 then
			error("Incorrect usage. Please pass an input file in!")
		end
		local i = 1
		while true do
			local a = args[i]
			local b = a:lower()
			print(a,b)
			if b == "-o" or b == "-output" then
				options.OutFile = args[i + 1]
				i = i + 1
			elseif b == "-l" or b == "-load" then
				options.Load = true
			elseif b == "-c" or b == "-compile" then
				options.Compile = true
			elseif b == "-s" or b == "-strip" then
				options.Strip = true
			else
				options.File = a
			end
			i = i + 1
			if i > #args then
				break
			end
		end
		if options.File == "" then
			error("No input file!")
		end

		local function compile(sdebug, name, output)
			local plaintext
			if xfs.exists(name) then
				plaintext = xfs.read(name)
			else
				error("unable to read file " .. name)
			end
			local ctick = tick()
			local bytecode, err = luac(plaintext, name)
			if not bytecode or err then
				error(err)
			end
			if sdebug then
				bytecode = luadbg.Rip(bytecode)
			end
			if not output then
				output = "luac.out"
			end
			if not xfs.exists(output) then
				xfs.mkfile(output)
			end
			xfs.write(output, bytecode)
			local btick = tick()

			essentials.Console.info(
				"Compiled "
					.. name
					.. " to "
					.. args[3]
					.. " in "
					.. btick - ctick
					.. " seconds, tot. siB "
					.. xfs:totalBytesInInstance(output)
			)
		end

		local function load(name, outputb, file)
			local plaintext
			if xfs.exists(name) then
				plaintext = xfs.read(name)
			else
				error("file " .. name.." does not exist")
			end
			local interpet, err = fione(plaintext, nil, enviroment)
			if not interpet or err then
				error(err)
			end
			local output = interpet()

			if
				type(output) == "string"
				or type(output) == "table"
				or type(output) == "number"
				or type(output) == "number" and file and outputb and output
			then
				if xfs.exists(file) then
					xfs.write(file, output)
				else
					xfs.mkfile(file)
					xfs.write(file, output)
				end
			else
				return output
			end

			return
		end

		if options.Compile then
			options.OutFile = options.OutFile or "luac.out"
			compile(options.Strip, options.File, options.OutFile)
		end
		if options.Load then
			options.OutFile = options.OutFile or nil
			load(options.File, (not options.OutFile == nil), options.OutFile)
		end
	
	
	end,
}

return cmd
