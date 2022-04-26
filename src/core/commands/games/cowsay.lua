local cmd = {
	name = script.Name,
	desc = [[]],
	usage = "$ ",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local buffer = ""

		local bufferprint = function(...)
			buffer ..= ...
		end
		local print = function(...)
			buffer ..= (... or "")
			pCsi.io.write(
				({buffer:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")})[1]
			)
			buffer = ""
		end

		local eyestr = "oo"
		local cowname = "apt"
		local deadstr = "  "
		local argmode = "none"
		local saytext = ""
		local charlimit = 40
		local exit = false
		for _, text in ipairs(args) do
			if argmode == "cowsel" then
				cowname = text
				argmode = "none"
			elseif argmode == "eyes" then
				eyestr = text:sub(1, -text:len() + 1)
				argmode = "none"
			elseif argmode == "text" then
				saytext = saytext .. " " .. text
			elseif argmode == "charsel" then
				charlimit = tonumber(text)
				argmode = "none"
				if charlimit == nil then
					print("-w must be a Number")
					return
				end
			else
				if args.f then
					argmode = "cowsel"
				elseif args.e then
					argmode = "eyes"
				elseif args.d then
					deadstr = "U "
					eyestr = "xx"
				elseif args.p then
					eyestr = "@@"
				elseif args.w then
					argmode = "charsel"
				elseif args.l then
					-- list all cowmodes
					exit = true
				else
					argmode = "text"
					saytext = text
				end
			end
		end

		if exit == true then
			return 0
		end

		if saytext == "" then
			print("Usage: cowsay [options] <cowfile>")
			return 1
		end

		local cowta = {}

		local function readFile(name)
			local fileha = pCsi.libs.cowsay[name]
			local tmpta = {}

			for i, v in ipairs(fileha:split("\n")) do
				local linecon = v
				if linecon == nil then
					break
				elseif linecon:find("$the_cow = ") == 1 then
					--nothing
				elseif linecon:find("EOC") == 1 then
					--nothing
				elseif linecon:find("#") == 1 then
					--nothing
				else
					linecon = linecon:gsub("$thoughts", "\\")
					linecon = linecon:gsub("$eyes", eyestr)
					linecon = linecon:gsub("\\\\", "\\")
					linecon = linecon:gsub("$tongue", deadstr)
					table.insert(tmpta, linecon)
				end
			end
			cowta[name] = tmpta
		end

		if not pCsi.libs.cowsay[cowname] then
			print("Could not find " .. cowname .. " cowfile!")
			return 2
		end

		readFile(cowname)

		if saytext:len() < charlimit then
			bufferprint(" ")
			for i = saytext:len() + 2, 1, -1 do
				bufferprint("_")
			end
			print()
			print("< " .. saytext .. " >")
			bufferprint(" ")
			for i = saytext:len() + 2, 1, -1 do
				bufferprint("-")
			end
			print()
		else
			bufferprint(" ")
			for i = charlimit, 1, -1 do
				bufferprint("_")
			end
			print()
			local charcou = 1
			local charpos = "start"
			bufferprint("/ ")

			for i = 1, #saytext do
				local c = saytext:sub(i, i)
				if charcou == charlimit then
					if charpos == "start" then
						print(" \\")
						charpos = nil
					else
						print(" |")
					end
					if saytext:len() - i < charlimit then
						bufferprint("\\ ")
					else
						bufferprint("| ")
					end
					charcou = 1
				else
					bufferprint(c)
					charcou = charcou + 1
				end
			end

			for i = charlimit - charcou, 1, -1 do
				bufferprint(" ")
			end
			print(" /")
			bufferprint(" ")
			for i = charlimit, 1, -1 do
				bufferprint("-")
			end
			print()
		end

		--cowname = cowname..".cow"
		for _, text in ipairs(cowta[cowname]) do
			print(text)
		end
		return
	end,
}

return cmd
