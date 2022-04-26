--[[       __ _ _      
  ___ / _(_) | ___ 
 / _ \ |_| | |/ _ \
|  __/  _| | |  __/
 \___|_| |_|_|\___|

There's more to life
    than amogus!
--]]
local module = {}--[[
                   ]]

return function(Essentials, Efile)
	local inputconn
	function Efile:Start()
		local error = function(...)
			Essentials.Console.error(
				"<b>pcsi</b>\nCommand line encountered an error: " .. table.concat(...) .. "\n" .. os.date("%c", tick())
			)
		end

		local verinfo = table.freeze({

			sname = "Pointcove/Indirecta(R) pcsi",
			vname = "2022 1.3",
		})

		Essentials.Console.info(verinfo.sname .. " - " .. verinfo.vname)
		Essentials.Console.info("Use 'cmds' to get a list of all available commands | Use 'uac' to set, change, or lock with a password this session")
		
		local Folder = script.commands
		local config = require(script.Configuration)

		local lm = {}
		lm.xfs = require(script.fs:WaitForChild("xfsm", 12))
		lm.fileTypeBindings = {}
		--lm.libs = {}


		-- improve all of this code
	

		lm.vars = {}

		-- sanitize string function
		lm.sanitizeStr = function(str)
			return str:gsub("[^%w%s]", "")
		end

		lm.cleanString = function(str)
			return string.gsub(str, "[^\x00-\x7F]", "")
			:gsub("&", "&amp;")
			:gsub("<", "&lt;")
			:gsub(">", "&gt;")
			:gsub('"', "&quot;")
			:gsub("'", "&apos;")
		end

		lm.setVar = function(i, v)
			rawset(lm.vars, i, v)
		end

		lm.getVars = function(arg1)
			return arg1 == "#" and #lm.vars or lm.vars
		end

		lm.io = {}

		lm.io.read = function()
			local input = nil
			local oldparse = lm.parseCommand
			function lm:parseCommand(...)
				input = { ... }
				table.remove(input, 1)
				input = table.unpack(input)

				task.spawn(function()
					task.wait(0.5)
					lm.parseCommand = oldparse
				end)
			end
			repeat
				task.wait()
			until input
			return input
		end

		lm.io.write = function(...)
			local str = table.concat({...}," ")

			-- Turn ANSI Sequences into Roblox RichText tags
			local colors = 0
			
			str = str:gsub("\x1b%[(%d+)m", function(c)
				local color = tonumber(c)
				if colors == 0 then --remove all richtext tags in the string if using ansi
					str = str:gsub("</[^>]+>", "")
					str = str:gsub("<[^>]+>","")
				end
				colors += 1
				if color == 0 then
					str = str:gsub("</[^>]+>", "")
					str = str:gsub("<[^>]+>","")
					return ""
				elseif color == 1 then
					return "<b>"
				elseif color == 3 then
					return "<i>"
				elseif color == 4 then
					return "<u>"
				elseif color == 30 then
					return "<font color='#000000'>"
				elseif color == 31 then
					return "<font color='#FF0000'>"
				elseif color == 32 then
					return "<font color='#00FF00'>"
				elseif color == 33 then
					return "<font color='#FFFF00'>"
				elseif color == 34 then
					return "<font color='#0000FF'>"
				elseif color == 35 then
					return "<font color='#FF00FF'>"
				elseif color == 36 then
					return "<font color='#00FFFF'>"
				elseif color == 37 then
					return "<font color='#FFFFFF'>"
				else
					return ""
				end
			end)
			-- For every tag add it's corresponding closing tag to the string in reverse order
			
			if not colors == 0 then
				for i = #str, 1, -1  do
					if str:sub(i, i) == "<" then
						local j = i
						while str:sub(j, j) ~= " " and str:sub(j, j) ~= ">" do
							task.wait()
							j = j + 1
						end
						local tag = str:sub(i, j)
						str ..= "</" .. tag:sub(2, -2) .. ">"
	
						-- Addstr = str:gsub(tag, tag .. "</" .. tag:sub(2, -2) .. ">")
					end
				end
			end
		


			-- Close each richtext tag in the string
			--str = str:gsub("<[^>]+>", "</>")
				
			-- Parse ANSI Bell Character and call function if found
			str = str:gsub("\x07", function(str)
				-- Sound a Bell/Beep?
				Essentials.Output:OutputToAll("Bell")
				return str
			end)
			-- Parse ANSI Clear Screen Character and call function if found
			str = str:gsub("\x1b%[2J", function(str)
				Essentials.Output:OutputToAll("ClearScreen")
				return str
			end)

			Essentials.Console.info(str)
		end

		function lm:load(name, folder, recursiv)
			if not folder or not name then
				return
			end
			local parent = recursiv or self
			if not parent[name] then
				parent[name] = {}
				parent[name].__isDir = true
			end
			local newfolder = parent[name]
			for i, v in pairs(folder) do
				if not v then
					continue
				end
				if typeof(v) == "Instance" and v:IsA("ModuleScript") then
					local n = v.Name
					print(n)
					v = require(v)
					if typeof(v) == "table" then
						if v.ready and type(v.ready) == "function" then
							v.ready(lm, Essentials)
						end
						if not v.name and not v.fn then
							newfolder[n] = v
						else
							newfolder[v.name] = v
						end
					elseif typeof(v) == "function" then
						newfolder[n] = v
					end
				elseif typeof(v) == "Instance" and v:IsA("Folder") then
					self:load(v.Name, v:GetChildren(), newfolder)
				elseif typeof(v) == "Instance" and v:IsA("SurfaceGui") then 
					local n = v.Name
					newfolder[n] = v
				end
				
			end
		end

		lm.vars["LIBS_DIR"] = script.libs.Name
		lm.vars["CMDS_DIR"] = Folder.Name
		lm.vars["SHELL"] = script[lm.vars["LIBS_DIR"]]["sh2"].Name

		lm:load(lm.vars["LIBS_DIR"], script[lm.vars["LIBS_DIR"]]:GetChildren())
		lm:load(lm.vars["CMDS_DIR"], script[lm.vars["CMDS_DIR"]]:GetChildren())


		local ArgParser = {
			Trim = function(self, str: string)
				return string.match(str, "^%s*(.-)%s*$")
			end,
		
			ReplaceCharacters = function(self, str: string, chars: {}, replaceWith)
				for i, char in ipairs(chars) do
					str = string.gsub(str, char, replaceWith or "")
				end
				return str
			end,
		
			RemoveQuotes = function(self, str: string)
				return self:ReplaceCharacters(str, {'^"(.+)"$', "^'(.+)'$"}, "%1")
			end,
		
			SplitString = function(self, str: string, splitChar: string, removeQuotes: boolean)
				local segments = {}
				local sentinel = string.char(0)
				local function doSplitSentinelCheck(x: string) return string.gsub(x, splitChar, sentinel) end
				local quoteSafe = self:ReplaceCharacters(str, {'%b""', "%b''"}, doSplitSentinelCheck)
				for segment in string.gmatch(quoteSafe, "([^".. splitChar .."]+)") do
					local result = self:Trim(string.gsub(segment, sentinel, splitChar))
					if removeQuotes then
						result = self:RemoveQuotes(result)
					end
					table.insert(segments, result)
				end
				return segments
			end,
		
			ConvertToParams = function(self, args, stopAtFirstParamArg)
				local result = {}
				local curParam
				local curPos = 1
				local curArg = args[curPos]
		
				while curArg do
					local gotParam = curArg:match("^%-%-(.+)") or curArg:match("^%-(.+)")
					
					if gotParam then
						curParam = gotParam
						result[curParam] = ""
					elseif curParam then
						result[curParam] = result[curParam] .. curArg
		
						--// If we only want one match per param
						if stopAtFirstParamArg then
							curParam = nil
						end
					else
						table.insert(result, curArg)
					end
		
					curPos += 1
					curArg = args[curPos]
				end
		
				return result
			end,
		
			ConvertToDataType = function(self, str)
				if tonumber(str) then
					return tonumber(str)
				elseif string.lower(str) == "false" then
					return false
				elseif string.lower(str) == "true" then
					return true
				else
					return str
				end
			end,
		
			Parse = function(self, str: string, split: string?, removeQuotes: boolean?, stopAtFirstParamArg: boolean?)
				local removeQuotes = if removeQuotes ~= nil then removeQuotes else true
				local stopAtFirstParamArg = if stopAtFirstParamArg ~= nil then stopAtFirstParamArg else true
				local extracted = self:SplitString(str, split or ' ', false)
				local params = self:ConvertToParams(extracted, stopAtFirstParamArg)
		
				for ind,value in pairs(params) do
					local trueVal = self:ConvertToDataType(value)
					params[ind] = if type(trueVal) == "string" and removeQuotes then self:RemoveQuotes(trueVal) else trueVal
				end
				
				return params
			end
		}

		function lm:execute(plr, command, args)
			local r
			local s, m = pcall(function()
				r = command.fn(plr, self, Essentials, args)
			end)
			if not s then
				Essentials.Console.error(m)
			end
			return r
		end

		local function recurseTable(tbl, func)
			for index, value in pairs(tbl) do
				if type(value) == "table" and not value.name and not value.fn then
					recurseTable(value, func)
				else
					func(index, value)
				end
			end
		end

		local allcommands = {}
		local allcommandnames = {}
		recurseTable(lm.commands, function(i, v)
			if type(v) == "table" and not v.__isDir then
				allcommands[v.name] = v
				table.insert(allcommandnames, v.name)
			end
		end)

		local function get_tip(context, wrong_name)
			local context_pool = {}
			local possible_name
			local possible_names = {}

			for name in pairs(context) do
				if type(name) == "string" then
					for i = 1, #name do
						possible_name = name:sub(1, i - 1) .. name:sub(i + 1)

						if not context_pool[possible_name] then
							context_pool[possible_name] = {}
						end

						table.insert(context_pool[possible_name], name)
					end
				end
			end

			for i = 1, #wrong_name + 1 do
				possible_name = wrong_name:sub(1, i - 1) .. wrong_name:sub(i + 1)

				if context[possible_name] then
					possible_names[possible_name] = true
				elseif context_pool[possible_name] then
					for _, name in ipairs(context_pool[possible_name]) do
						possible_names[name] = true
					end
				end
			end

			local first = next(possible_names)
			print(table.concat(possible_names))
			if first then
				if next(possible_names, first) then
					local possible_names_arr = {}

					for name in pairs(possible_names) do
						table.insert(possible_names_arr, "'" .. name .. "'")
					end

					table.sort(possible_names_arr)
					return "\nDid you mean one of these: " .. table.concat(possible_names_arr, ", ") .. "?"
				else
					return "\nDid you mean '" .. first .. "'?"
				end
			else
				return ""
			end
		end

		local function parseCmd(plr, arg, o)
			print(plr.Name .. ": Command '" .. arg .. "'; Omit: " .. tostring(o))
			arg = string.split(arg, " ")
			local command = arg[1]
			table.remove(arg, 1)
			local args = ArgParser:Parse(table.concat(arg))
			if command == "cmds" then --remake cmds and cmd as commands
				local length = #allcommandnames
				lm.io.write(length .. " commands: " .. table.concat(allcommandnames, ", "))
				return table.concat(allcommandnames, ", ")
			elseif command == "cmd" then
				if allcommands[command] == nil then
					lm.io.write("Command '" .. command .. "' not found")
				else
					lm.io.write(
						"Description: " .. allcommands[command].desc,
						"Usage: " .. allcommands[command].usage
					)
				end
			else
				if allcommands[command] == nil then
					if lm.xfs.exists(command) then
						local filetype = string.split(command, ".")
						filetype = filetype[#filetype]
						if lm.fileTypeBindings and lm.fileTypeBindings[filetype] then
							--[[
												
											lm.fileTypeBindings[filetype] = {
												command = "luau",
												args = {
													"interpret" -- insert file arg
												}
											}
											
											]]

							lm:execute(
								plr,
								allcommands[lm.fileTypeBindings[filetype].command],
								table.pack(table.unpack(lm.fileTypeBindings[filetype].args), command)
							)
						elseif filetype == "ch" then
							task.wait() -- in case some questionable person writes a batch file that reads itself, just LeftCtrl+RightAlt+F5 to reboot
							local source = lm.xfs.read(command)
							source = string.gsub(source, "$args", table.concat(args))
							lm:parseCommand(plr, source)
						end
					else
						Essentials.Console.warn(
							"'"
								.. command
								.. "' is not recognized as an internal or external command, operable program or batch file."
								.. get_tip(allcommands, command)
						)
					end
				else
					local r = lm:execute(plr, allcommands[command], args)
					if r and not o and allcommands[command].displayOutput then
						lm.io.write(r)
					end
					return r
				end
			end
		end

		lm.vars["SH_HEADER"] = "\x1b[1m%plr</b> %path&gt; %cmd"

		-- Determine text x and y from rows and columns in TextLabel text
		local function getTextXY(text, rows, cols)
			local x = 0
			local y = 0
			local i = 1
			local j = 1
			local len = #text
			while i <= len do
				if text:sub(i, i) == "\n" then
					y = y + 1
					x = 0
					i = i + 1
				elseif x == cols then
					y = y + 1
					x = 0
					i = i + 1
				else
					x = x + 1
					i = i + 1
				end
				if y == rows then
					break
				end
			end
			return x, y
		end

		-- Blink a | character as a cursor in the text
		local function blinkCursor(text, x, y)
			local len = #text
			local i = 1
			local j = 1
			while i <= len do
				if text:sub(i, i) == "\n" then
					j = j + 1
					i = i + 1
				elseif j == y and i == x then
					return text:sub(1, i - 1) .. "|" .. text:sub(i + 1)
				else
					i = i + 1
				end
			end
			return text
		end

		function lm:parseCommand(plr, fEStr)
			fEStr = string.match(fEStr, "^%s*(.-)%s*$")

			local time = os.date("%Y/%m/%d %H:%M:%S", os.time())
			lm.io.write(table.pack(lm.vars["SH_HEADER"]:gsub("%%plr",plr.Name):gsub("%%path",self.xfs.fullCwd()):gsub("%%cmd",fEStr))[1])

			local fLStr = string.split(fEStr, " > ") or fEStr

			for i, v in ipairs(fLStr) do
				local fStr = string.split(v, " | ") or v -- pipe char
				local prevRCmd = nil
				for i, v in ipairs(fStr) do
					if prevRCmd then
						v = v .. " " .. prevRCmd
					end
					local omit = false
					if #fStr > 1 then
						if i == #fStr then
							omit = false
						else
							omit = true
						end
					end
					prevRCmd = parseCmd(plr, v, omit)
				end
				if fLStr[2] then
					self:execute(plr, allcommands["output"], { fLStr[2], prevRCmd })
				end
			end
		end

		local bindable = config.keyboard_bindable
		local stat = 0

		lm.onNewOutput = Instance.new("BindableEvent")
		lm.onUpdatedOutput = Instance.new("BindableEvent")
		lm.onKeyStroke = Instance.new("BindableEvent")

		lm.reboot = function()
			if Essentials.Freestore[0x000A2] then
				Essentials.Console.warn("Resetting..")
				Essentials.Freestore[0x000A2]:reboot()
			else
				Essentials.Console.warn("Missing PowerManager in 0x000A2 Freestore Address")
			end
		end

		lm.shutdown = function() 
			if Essentials.Freestore[0x000A2] then
				Essentials.Console.warn("Shutting down..")
				Essentials.Freestore[0x000A2]:shutdown()
			else
				Essentials.Console.warn("Missing PowerManager in 0x000A2 Freestore Address")
			end
		end

		inputconn = bindable.Event:Connect(function(mode, arg, plr)
			if mode == "keyStroke" then
				lm.onKeyStroke:Fire(plr, arg)
				if arg == Enum.KeyCode.LeftControl then
					if stat == 0 then
						stat = 1
					else
						stat = 0
					end 
				elseif arg == Enum.KeyCode.RightAlt then
					if stat == 1 then
						stat = 2
					else
						stat = 0
					end
				elseif arg == Enum.KeyCode.F5 then
					if stat == 2 then
						-- do stuff
						lm.reboot()
						stat = 0
					else
						stat = 0
					end
				else
					stat = 0
				end
			end

			if mode == "newOutput" then
				lm.onNewOutput:Fire(plr, arg)
				lm:parseCommand(plr, arg)
			end

			if mode == "newOutput" then
				lm.onUpdatedOutput:Fire(plr, arg)
			end
		end)

		if Essentials.Freestore then
			Essentials.Freestore[0x000A3] = lm
		end
	end

	function Efile:Stop()
		if inputconn then
			inputconn:Disconnect()
			inputconn:Destroy()
		end
	end

	function Efile:construct(instance: Instance)
		Efile:Start()
	end

	function Efile:destroy(instance: Instance)
		Efile:Stop()
	end
end
