local cmd = {
	name = script.Name,
	desc = [[Executes the popular esoteric programming language instructions and displays the output]],
	usage = [[$ brainfudge [code] (input)]],
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		
		local function Run(str, inp, memlimit, printf)
			memlimit = memlimit or 30000
			local tape = {}
			local pointer = 0
			local input = inp or ""
			local codep = 1
			local inputp = 1
			local ubCount = 0

			local Budget = 1/60 -- seconds

			local expireTime = 0
			local hasYielded = false

			-- Call at start of process.
			local function ResetTimer()
				expireTime = tick() + Budget
			end

			ResetTimer()

			-- Call where appropriate, such as at the top of loops.
			local function MaybeYield()
				if tick() >= expireTime then
					hasYielded = true
					task.wait() -- insert preferred yielding method
					ResetTimer()
				end
			end

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

				[">"] = function()
					pointer += 1

					if pointer > memlimit - 1 then
						error(string.format("Pointer out of bound: %d", pointer))
					end
				end,

				["<"] = function()
					pointer -= 1

					if pointer < 0 then
						error(string.format("Pointer out of bound: %d", pointer))
					end
				end,

				["["] = function()
					if not tape[pointer] or tape[pointer] == 0 then
						ubCount += 1
						while string.sub(str, codep, codep) ~= "]" or ubCount ~= 0 do
							MaybeYield()
							--print(string.sub(str, codep, codep))
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
							MaybeYield()
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
					if input == "" then essentials.Console.info("[brainfudge] :: Awaiting for input.."); input = pCsi.io.read(); end
					tape[pointer] = string.byte(string.sub(input, inputp, inputp)) or 0
					inputp += 1
				end,
			}

			while codep <= #str do
				MaybeYield()

				local char = string.sub(str, codep, codep)

				if sw[char] then
					sw[char]()
				end

				codep += 1
			end
			return tape, pointer
		end
		
		local buffer = ""
		local toint = table.concat(args," ")

		toint = pCsi.xfs.exists(toint) and pCsi.xfs.read(toint) or toint

		--local input = (#args > 1) and args[1] or nil
		--if input then table.remove(args,1) end
		essentials.Console.info("[brainfudge] :: Executing script..")
		
		local tape,pointer = Run(toint,nil,nil,function(char)
			buffer = buffer..char
		end)
		essentials.Console.info(buffer)
		essentials.Console.info("[brainfudge] :: Ended execution. ("..pCsi.xfs:formatBytesToUnits(math.round(((#tape)^2)/256*100)/100).." bfr size, "..pointer.."/"..#tape..") ")

		return buffer
	end,
}

return cmd

--z++++++++[x+++++++++z-]x.z++++[x+++++++z-]x+.+++++++..+++.zz++++++[x+++++++z-]x++.------------.z++++++[x+++++++++z-]x+.x.+++.------.--------.zzz++++[x++++++++z-]x+.