local cmd = {
	name = script.Name,
	desc = [[Executes the popular esoteric programming language instructions and displays the output\n The greater-than and less-than characters have been replaced with z and x]],
	usage = [[$ brainfudge [code] (input)]],
	fn = function(plr, pCsi, essentials, args)
		
		local function Run(str, inp, memlimit, printf)
			memlimit = memlimit or 12
			local tape = {}
			local pointer = 0
			local input = inp or ""
			local codep = 1
			local inputp = 1
			local ubCount = 0

			local sw = {
				["+"] = function()
					if not tape[pointer] then
						tape[pointer] = 0
					end

					tape[pointer] = ((tape[pointer] + 1) % 256) ~= 0 and ((tape[pointer] + 1) % 256) or nil -- 0 = nil lolol
				end,

				["-"] = function()
					if not tape[pointer] then
						tape[pointer] = 0
					end

					tape[pointer] = ((tape[pointer] - 1) % 256) ~= 0 and ((tape[pointer] - 1) % 256) or nil
				end,

				["z"] = function()
					pointer += 1

					if pointer > memlimit - 1 then
						error(string.format("Pointer out of bound: %d", pointer))
					end
				end,

				["x"] = function()
					pointer -= 1

					if pointer < 0 then
						error(string.format("Pointer out of bound: %d", pointer))
					end
				end,

				["["] = function()
					if not tape[pointer] or tape[pointer] == 0 then
						ubCount += 1
						while string.sub(str, codep, codep) ~= "]" or ubCount ~= 0 do
							print(string.sub(str, codep, codep))
							codep += 1
							local c = string.sub(str, codep, codep)

							if c == "[" then
								ubCount += 1
							elseif c == "]" then
								ubCount -= 1
							end
						end
					end
				end,

				["]"] = function()
					if tape[pointer] and tape[pointer] ~= 0 then
						ubCount += 1
						while string.sub(str, codep, codep) ~= "[" or ubCount ~= 0 do
							codep -= 1
							local c = string.sub(str, codep, codep)

							if c == "]" then
								ubCount += 1
							elseif c == "[" then
								ubCount -= 1
							end
						end
					end
				end,

				["."] = function()
					printf(string.char(tape[pointer] or 0))
				end,

				[","] = function()
					tape[pointer] = string.byte(string.sub(input, inputp, inputp)) or 0
					inputp += 1
				end,
			}

			while codep <= #str do
				local char = string.sub(str, codep, codep)

				if sw[char] then
					sw[char]()
				end

				codep += 1
			end
			return tape, pointer
		end
		
		local buffer = ""
		local input = (#args > 1) and args[1] or nil
		if input then table.remove(args,1) end
		Run(table.concat(args," "),input,nil,function(char)
			buffer = buffer..char
		end)
		essentials.Console.info("Brainfudge: "..buffer)
	end,
}

return cmd

--z++++++++[x+++++++++z-]x.z++++[x+++++++z-]x+.+++++++..+++.zz++++++[x+++++++z-]x++.------------.z++++++[x+++++++++z-]x+.x.+++.------.--------.zzz++++[x++++++++z-]x+.