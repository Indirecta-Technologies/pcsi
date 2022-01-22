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
	fn = function(plr, pCsi, essentials, args)
		-- luac.lua - partial reimplementation of luac in Lua.
		-- http://lua-users.org/wiki/LuaCompilerInLua
		-- David Manura et al.
		-- Licensed under the same terms as Lua (MIT license).

		local outfile = "luac.out"

		local environment = {}

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

		local tbl = {}
		local osmt = {
				__index = function(t, i)
					if i == "exit" then
						return function(...)
							pCsi.parseCommand = oldparse
							return
						end
					elseif i == "getenv" then
						return function(k)
							return environment[k]
						end
					elseif i == "execute" then
						return function(k)
							oldparse(k)
						end
					elseif i == "tempname" then
						return function() 
							local prefix = "lua_"
							local rand = tostring(math.random(1111,99999))
							
							return prefix..(rand:gsub('.', function (c)
								return string.format('%02X', string.byte(c))
							end))
						end
					else
						return os[i]
					end
				end
		}


		environment.os = setmetatable(tbl, osmt)
		environment.tick = tick
		environment.utf8 = utf8
		environment._G = essentials.Freestore
		environment.loadstring = function(...) 
		return fione(..., nil, environment)
		end




		-- Parse options.
		local chunks = {}
		local allowoptions = true
		local iserror = false
		local parseonly = false
		while args[1] do
			if allowoptions and args[1] == "-" then
				chunks[#chunks + 1] = args[1]
				allowoptions = false
			elseif allowoptions and args[1] == "-l" then
				pCsi.io.write("-l option not implemented\n")
				iserror = true
			elseif allowoptions and args[1] == "-o" then
				outfile = assert(args[2], "-o needs argument")
				table.remove(args, 1)
			elseif allowoptions and args[1] == "-p" then
				parseonly = true
			elseif allowoptions and args[1] == "-s" then
				pCsi.io.write("-s option ignored\n")
			elseif allowoptions and args[1] == "-v" then
				pCsi.io.write(_VERSION .. " Copyright (C) 1994-2008 Lua.org, PUC-Rio\n")
			elseif allowoptions and args[1] == "--" then
				allowoptions = false
			elseif allowoptions and args[1]:sub(1, 1) == "-" then
				pCsi.io.write("luac: unrecognized option '" .. args[1] .. "'\n")
				iserror = true
				break
			else
				chunks[#chunks + 1] = args[1]
			end
			table.remove(args, 1)
		end
		if #chunks == 0 and not iserror then
			pCsi.io.write("luac: no input files given\n")
			iserror = true
		end

		if iserror then
			pCsi.io.write([[
usage: luac [options] [filenames].
Available options are:
  -        process stdin
  -l       list
  -o name  output to file 'name' (default is "luac.out")
  -p       parse only
  -s       strip debug information
  -v       show version information
  --       stop handling options
]])
			return
		end

		-- Load/compile chunks.
		local filenames = {}
		for i, filename in ipairs(chunks) do
			filenames[i] = filename
			chunks[i] = assert(xfs.read(filename))
		end

		if parseonly then
			return
		end

		-- Combine chunks.
		if #chunks == 1 then
			chunks = chunks[1]
		else
			-- Note: the reliance on loadstring is possibly not ideal,
			-- though likely unavoidable.
			local ts = { "local loadstring=loadstring;" }
			for i, f in ipairs(chunks) do
				ts[i] = ("loadstring%q(...);"):format(luac(f, filenames[i], nil))
			end
			--possible extension: ts[#ts] = 'return ' .. ts[#ts]
			chunks = assert(table.concat(ts))
		end

		-- Output.
		if not xfs.exists(outfile) then
			xfs.mkfile(outfile)
		end
		xfs.write(outfile, luac(chunks, outfile, nil))
	end,
}

return cmd
