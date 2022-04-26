local prog = nil
local cmd = {
	name = script.Name,
	desc = [[Executes the popular esoteric programming language instructions and displays the output]],
	usage = [[$ brainfudge [code] ]],
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		local function Run(str, inp, memlimit)
			memlimit = memlimit or 30000
			local tape = {}
			local pointer = 0
			local input = inp or ""
			local codep = 1
			local inputp = 1
			local ubCount = 0

			local buffer = ""

			local Budget = 1 / 60 -- seconds

			local expireTime = 0
			local hasYielded = false
			local continue_ = true

			-- Call at start of process.
			local function ResetTimer()
				expireTime = tick() + Budget
			end

			local codel = 1

			local function memview()
				local mem_slots = #tape
				local pre_slots = math.floor(mem_slots / 2)
				local low_slot = pre_slots - pointer
				if low_slot < 0 then
					low_slot += 256
				end

				local line_1 = ""
				for i=0, mem_slots-1 do
					local slot = low_slot + i
					print(slot, mem_slots, pre_slots, low_slot)
					local label = string.format("%0.3i", tape[slot])
					line_1 ..= label .. " "
				end

				local line_2 = ""
				for i = 1, pre_slots do
					line_2 ..= "    "
				end
				line_2 ..= "^"

				local line_3 = ""
				for i = 1, pre_slots do
					line_3 ..= "    "
				end
				line_3 ..= "Pointer: " .. pointer

				local line_4 = ""
				for i = 1, mem_slots do
					local slot = low_slot + i
					if slot >= 256 then
						slot -= 256
					end
					local label = string.format("%0.3i", slot)
					line_4 ..= label .. " "
				end

				return line_1 .. "\n" .. line_2 .. "\n" .. line_3 .. "\n" .. line_4
			end

			local function onfinish()
				pCsi.io.write(buffer)
				local tapel = #tape
				pCsi.io.write(
					"[brainfudge] :: Ended execution. ("
						.. pCsi.xfs:formatBytesToUnits(math.round((tapel ^ 2) / 256 * 100) / 100)
						.. " bfr size, "
						.. pointer
						.. "/"
						.. #tape
						.. ") "
				)
				buffer, prog = "", nil
			end

			local function StopProg()
				continue_ = false
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
						while string.sub(str, codep, codep) ~= "]" or ubCount ~= 0 and continue_ do
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
						while string.sub(str, codep, codep) ~= "[" or ubCount ~= 0 and continue_ do
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
					buffer ..= string.char(tape[pointer] or 0)
				end,

				["#"] = function()
					local height = 60
					local pre_slots = math.floor(height / 2)
					local low_slot = codel - pre_slots

					local line_1 = ""
					for i = 1, height, 1 do
						local slot = low_slot + i
						if (slot >= 0) and (slot < #str) then
							line_1 ..= str:sub(slot, slot):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
						else
							line_1 ..= "_"
						end
					end

					local line_2 = ""
					for i = 1, pre_slots, 1 do
						line_2 ..= " "
					end
					line_2 ..= "^"

					local line_3 = ""
					for i = 1, pre_slots, 1 do
						line_3 ..= " "
					end

					pCsi.io.write(
						"Memory: "
							.. memview()
							.. "\nTape: "
							.. line_1
							.. "\n"
							.. line_2
							.. "\n"
							.. line_3
							.. "\nChar "
							.. codel
							.. " out of "
							.. #str
					)
				end,

				[","] = function()
					if input == "" then
						pCsi.io.write("[brainfudge] :: Awaiting for input..")
						input = pCsi.io.read()
					end
					tape[pointer] = string.byte(string.sub(input, inputp, inputp)) or 0
					inputp += 1
				end,
			}

			task.spawn(function()
				pCsi.io.write("[brainfudge] :: Executing script..")
				while codep <= #str and continue_ do
					MaybeYield()

					local char = string.sub(str, codep, codep)

					if sw[char] then
						sw[char]()
					end

					codep += 1
					codel = codep % (#str)

				end
				onfinish()
			end)

			return { tape, pointer, StopProg }
		end

		local buffer = ""
		local toint = table.concat(args, " ")

		if prog and toint == "stop" then
			prog[3]()
		end

		toint = pCsi.xfs.exists(toint) and pCsi.xfs.read(toint) or toint

		--local input = (#args > 1) and args[1] or nil
		--if input then table.remove(args,1) end

		prog = Run(toint, nil, nil)

		return buffer
	end,
}

return cmd

--z++++++++[x+++++++++z-]x.z++++[x+++++++z-]x+.+++++++..+++.zz++++++[x+++++++z-]x++.------------.z++++++[x+++++++++z-]x+.x.+++.------.--------.zzz++++[x++++++++z-]x+.
