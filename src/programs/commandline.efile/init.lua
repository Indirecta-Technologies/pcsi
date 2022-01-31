--[[       __ _ _      
  ___ / _(_) | ___ 
 / _ \ |_| | |/ _ \
|  __/  _| | |  __/
 \___|_| |_|_|\___|                                                                                                                                                                                                       --]]local module = {}--[[
                   ]]




				   return function(Essentials, Efile)
					local inputconn;
					function Efile:Start()
						local Folder = script.commands
						local config = require(script.Configuration)

						local lm = {};
						lm.xfs = require(script.fs:WaitForChild("xfsm",12))
						lm.fileTypeBindings = {}
						--lm.libs = {}

						function lm:load(name, folder, recursiv)
							if not folder or not name then return end
							local parent = recursiv or self
							if not parent[name] then 
								parent[name] = {}
								parent[name].__isDir = true
							end
							local newfolder = parent[name]
							for i,v in pairs(folder) do
								if not v then continue end
								if typeof(v) == "Instance" and v:IsA("ModuleScript") then
									local n = v.Name
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
								
								end
								if typeof(v) == "Instance" and v:IsA("Folder") then
									self:load(v.Name, v:GetChildren(), newfolder)
								end
							end
						end
				
						lm:load(script.libs.Name, script.libs:GetChildren())
						lm:load(Folder.Name, Folder:GetChildren())

						print(game:GetService("HttpService"):JSONEncode(lm))
						lm.io = {}

						lm.io.read = function()
							local input = nil
							local oldparse = lm.parseCommand
							function lm:parseCommand(...)
								input = {...}
								table.remove(input, 1)
								input = table.unpack(input)

								task.spawn(function()
									task.wait(0.5)
									lm.parseCommand = oldparse
								end)
							end
							repeat task.wait() until input
							return input
						end

						lm.io.write = function(...)
							Essentials.Console.info(...)
						end
						
						function lm:execute(plr, command,args)
							local r;
							local s,m = pcall(function()
								r = command.fn(plr, self, Essentials,args)
							end)
							if not s then Essentials.Console.error(m) end
							return r
						end

						local function recurseTable(tbl, func)
							for index, value in pairs(tbl) do
								if type(value) == 'table' and not value.name and not value.fn then
									recurseTable(value, func)
								else
									func(index, value)
								end
							end
						end
						
						local allcommands = {};
						recurseTable(lm.commands, function(i, v)
							print(v)
							if type(v) == "table" and not v.__isDir then
								 allcommands[v.name] = v
							end
						end)

						print(game:GetService("HttpService"):JSONEncode(allcommands))

						local function parseCmd(plr, arg, o)
							print(arg)
							arg = string.split(arg," ")
							local command = arg[1]
							print(command)
							local args = arg
							table.remove(args,1)
							if command == "cmds" then 
								local length = 0
								local allnames = {}
								for i, v in pairs(allcommands) do
									length += 1
									table.insert(allnames, v.name)
								end
								Essentials.Console.info(length.." commands: "..table.concat(allnames,", "))
								return table.concat(allnames,", ")
							elseif command == "cmd" then
								if allcommands[args[1]] == nil then
									Essentials.Console.warn("Command '"..args[1].."' not found")
								else
									Essentials.Console.info("Description: "..allcommands[args[1]].desc,"Usage: "..allcommands[args[1]].usage)
								end
							else
								if allcommands[command] == nil then
									if lm.xfs.exists(command) then
										local filetype = string.split(command,".")
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

											lm:execute(plr, allcommands[lm.fileTypeBindings[filetype].command],table.pack(table.unpack(lm.fileTypeBindings[filetype].args), command))
										elseif filetype == "ch" then
											task.wait() -- in case some questionable person writes a batch file that reads itself, just LeftCtrl+RightAlt+F5 to reboot
											local source = lm.xfs.read(command)
											source = string.gsub(source, "$args", table.concat(args))
											lm:parseCommand(source)
										end
									else
										Essentials.Console.warn("'"..command.."' is not recognized as an internal or external command, operable program or batch file.")
									end
								else
									local r = lm:execute(plr, allcommands[command],args);
									if r and not o and allcommands[command].displayOutput then 
										Essentials.Console.info(r) 
									end
									return r
								end
							end
						end
				
						function lm:parseCommand(plr, fEStr)
							fEStr = string.match(fEStr, "^%s*(.-)%s*$")
				
							local time = os.date("%Y/%m/%d %H:%M:%S",os.time())
							Essentials.Console.info("┌ ".. time)
							task.spawn(function()
								wait(0.3)
								Essentials.Console.info("└ "..self.xfs.fullCwd().."> "..fEStr:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
							end)
							local fLStr = string.split(fEStr," > ") or fEStr
							
							for i,v in ipairs(fLStr) do
								local fStr = string.split(v," | ") or v -- pipe char
								local prevRCmd = nil;
								for i,v in ipairs(fStr) do
									if prevRCmd then v = v.." "..prevRCmd end
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
								if fLStr[2] then self:execute(plr, allcommands["output"],{fLStr[2], prevRCmd}) end
							end
				
				
				
						end
				
						local bindable = config.keyboard_bindable
						local stat = 0
						
						lm.onNewOutput = Instance.new("BindableEvent")
						lm.onUpdatedOutput = Instance.new("BindableEvent")
						lm.onKeyStroke = Instance.new("BindableEvent")

						inputconn = bindable.Event:Connect(function(mode,arg,plr)
							if mode == "keyStroke" then
								lm.onKeyStroke:Fire(plr, arg)
								if arg == Enum.KeyCode.LeftControl then
									if stat == 0 then stat = 1 else stat = 0 end
								elseif arg == Enum.KeyCode.RightAlt then
									if stat == 1 then stat = 2 else stat = 0 end
								elseif arg == Enum.KeyCode.F5 then
									if stat == 2 then 
										-- do stuff
										Essentials.Console.warn("Reloading kernel..")
										if Essentials.Freestore["PowerManagerService"] then
											Essentials.Freestore["PowerManagerService"]:reboot()
										end
										stat = 0 
									else stat = 0 end
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
							Essentials.Freestore["pCsi"] = lm
						end

					end
				
					function Efile:Stop()
						if inputconn then inputconn:Disconnect(); inputconn:Destroy(); end
					end
				
					function Efile:construct(instance: Instance)
						Efile:Start()
					end
					function Efile:destroy(instance: Instance)
						Efile:Stop()
					end
				
				end