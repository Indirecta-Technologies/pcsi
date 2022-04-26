local HttpService = game:GetService("HttpService")

return {
	name = script.Name,
	desc = [[Manage execution files]],
	usage = [[$ efile start|stop|track|list template.efile]],
	fn = function(plr, pCsi, essentials, args)
		local mode = assert(args[1], "First argument/mode not specified")

		if mode == "list" then
			local buffer = "\n| i | Name | ID | Functions | Status | Start Time | Duration |"
			for _, v in pairs(essentials.Efile:GetAllEfiles()) do
				buffer ..= string.format("\n| %s° | %s | ID%s | %dfns | %s | %s | %s |",
					v.index,
					v.component.Name,
					v.id,
					#v.innerFunctions,
					coroutine.status(v.coroutine),
					os.date("%Y%m%d %H:%M:%S", v.startTime),
					math.round((v.endTime and v.endTime-v.startTime or 0) * 10) / 10
				)
			end
			pCsi.io.write(buffer)
		else
			local programName = assert(args[2], "Second argument/program name not specified")
			local program = essentials.Efile:GetEfileByName(programName)

			if program then
				local commandModes = {
					["start"] = function()
						--pCsi.io.write("Starting '"..pname.."' ("..program.index..")")
						program:start()
					end,
					["stop"] = function()
						pCsi.io.write(string.format("Stopping %s (%s)", programName, program.index))
						program:interrupt()
					end,
					["track"] = function()
						local str = "-- "..programName.." --\n"
						for i, v in pairs(program) do
							if type(v) == "thread" then
								v = ("co, ") .. (coroutine.status(v) or "?")
							elseif type(v) == "function" then
								v = "fn"
							elseif type(v) == "table" then
								v = HttpService:JSONEncode(v)
							end
							if v ~= nil then
								str ..= i..": "..tostring(v).."\n"
							end
						end
						pCsi.io.write(str)
					end,
				}

				assert(commandModes[mode], "Invalid mode specified")()
			else
				essentials.Console.warn(string.format("Program '%s' not found", programName))
			end
		end
	end,
}