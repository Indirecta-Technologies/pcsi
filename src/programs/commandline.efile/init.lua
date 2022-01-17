--[[       __ _ _      
  ___ / _(_) | ___ 
 / _ \ |_| | |/ _ \
|  __/  _| | |  __/
 \___|_| |_|_|\___|                                                                                                                                                                                                       --]]local module = {}--[[
                   ]]




				   return function(Essentials, Efile)
					local inputconn;
					function Efile:Start()
						local Folder = script.commands:GetChildren()
				
						local lm = {};
						lm.xfs = require(script.fs:WaitForChild("xfsm",12))
						lm.commands = {}
						function lm:load(folder) 
							for i,v in pairs(folder) do
								if typeof(v) == "Instance" and v:IsA("ModuleScript") then
									v = require(v)
									if not v.name and not v.fn then continue end
									self.commands[v.name] = v
								end
								if typeof(v) == "Instance" and v:IsA("Folder") then
									self:load(v:GetChildren())
								end
							end
						end
				
						lm:load(Folder)
						
						
						
						function lm:execute(command,args)
							local r;
							local s,m = pcall(function()
								r = command.fn(self, Essentials,args)
							end)
							if not s then Essentials.Console.error(m) end
							return r
						end
				
						local function parseCmd(arg, o)
							print(arg)
							arg = string.split(arg," ")
							local command = arg[1]
							print(command)
							local args = arg
							table.remove(args,1)
							if command == "cmds" then 
								local length = 0
								for i, v in pairs(lm.commands) do
									length += 1
								end
								local toprint = {}
								for i,v in pairs(lm.commands) do
									table.insert(toprint, v.name)
								end
								toprint = table.concat(toprint,", ")
								Essentials.Console.info(length.." commands: "..toprint)
								return lm.commands
							elseif command == "cmd" then
								if lm.commands[args[1]] == nil then
									Essentials.Console.warn("Command '"..args[1].."' not found")
								else
									Essentials.Console.info("Description: "..lm.commands[args[1]].desc,"Usage: "..lm.commands[args[1]].usage)
								end
							else
								if lm.commands[command] == nil then
									if lm.xfs.exists(command) and lm.xfs.type(command) == "File" or lm.xfs.type(command) == "Link" then
										local filetype = string.split(command,".")
										filetype = filetype[#filetype]
										if filetype == "luac" then
											lm:execute(lm.commands["luau"],{"interpret",command})
										end
									else
										Essentials.Console.warn("Command or file '"..command.."' not found")
									end
								else
									local r = lm:execute(lm.commands[command],args);
									if r and not o and lm.commands[command].displayOutput then 
										Essentials.Console.info(r) 
									end
									return r
								end
							end
						end
				
						function lm:parseCommand(fEStr)
							fEStr = string.match(fEStr, "^%s*(.-)%s*$")
				
							local time = os.date("%Y/%m/%d %H:%M:%S",os.time())
							Essentials.Console.info("┌ ".. time)
							task.spawn(function()
								wait(0.3)
								Essentials.Console.info("└ "..self.xfs.fullCwd().."> "..fEStr)
							end)
							local fLStr = string.split(fEStr," >> ") or fEStr
							
							for i,v in ipairs(fLStr) do
								local fStr = string.split(v," && ") or v
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
									prevRCmd = parseCmd(v, omit)
								end
								if fLStr[2] then self:execute(self.commands["output"],{fLStr[2], prevRCmd}) end
							end
				
				
				
						end
				
						local bindable = script.Parent.Parent.Parent:WaitForChild("pc_cli")
						local stat = 0
				
						inputconn = bindable.Event:Connect(function(mode,arg,plr)
							if mode == "keyStroke" then
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
								lm:parseCommand(arg)
							end
				
				
						end)
				
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