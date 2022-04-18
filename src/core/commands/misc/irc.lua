local cmd = {
	name = script.Name,
	desc = [[Study current working directory of files and produce a mixed output]],
	displayOutput = true,
	usage = [[$ markovchain true 2500]],
	fn = function(plr, pCsi, essentials, args)
		if #args < 1 then
			print("Usage: irc nickname [server:port]")
			return
		end

		local nick = args[1]
		local host = args[2] or "irc.esper.net:6667"

		-- try to connect to server.
		local WS = pCsi.libs.websocket
		WS.Setup("https://pCsiWSProxy.lollodev5123.repl.co", 2030, "lefishe69420")

		

		-- custom print that uses all except the last line for printing.
		local function print(message, overwrite)
			pCsi.io.write(message)
		end

		-- utility method for reply tracking tables.
		local function autocreate(table, key)
			table[key] = {}
			return table[key]
		end

		-- extract nickname from identity.
		local function name(identity)
			return identity and identity:match("^[^!]+") or identity or "Anonymous"
		end

		-- user defined callback for messages (via `lua function(msg) ... end`)
		local callback = nil

		-- list of whois info per user (used to accumulate whois replies).
		local whois = setmetatable({}, { __index = autocreate })

		-- list of users per channel (used to accumulate names replies).
		local names = setmetatable({}, { __index = autocreate })

		-- timer used to drive socket reading.
		local timer

		-- ignored commands, reserved according to RFC.
		-- http://tools.ietf.org/html/rfc2812#section-5.3
		local ignore = {
			[213] = true,
			[214] = true,
			[215] = true,
			[216] = true,
			[217] = true,
			[218] = true,
			[231] = true,
			[232] = true,
			[233] = true,
			[240] = true,
			[241] = true,
			[244] = true,
			[244] = true,
			[246] = true,
			[247] = true,
			[250] = true,
			[300] = true,
			[316] = true,
			[361] = true,
			[362] = true,
			[363] = true,
			[373] = true,
			[384] = true,
			[492] = true,
			-- custom ignored responses.
			[265] = true,
			[266] = true,
			[330] = true,
		}

		-- command numbers to names.
		local commands = {
			--Replys
			RPL_WELCOME = "001",
			RPL_YOURHOST = "002",
			RPL_CREATED = "003",
			RPL_MYINFO = "004",
			RPL_BOUNCE = "005",
			RPL_LUSERCLIENT = "251",
			RPL_LUSEROP = "252",
			RPL_LUSERUNKNOWN = "253",
			RPL_LUSERCHANNELS = "254",
			RPL_LUSERME = "255",
			RPL_AWAY = "301",
			RPL_UNAWAY = "305",
			RPL_NOWAWAY = "306",
			RPL_WHOISUSER = "311",
			RPL_WHOISSERVER = "312",
			RPL_WHOISOPERATOR = "313",
			RPL_WHOISIDLE = "317",
			RPL_ENDOFWHOIS = "318",
			RPL_WHOISCHANNELS = "319",
			RPL_CHANNELMODEIS = "324",
			RPL_NOTOPIC = "331",
			RPL_TOPIC = "332",
			RPL_NAMREPLY = "353",
			RPL_ENDOFNAMES = "366",
			RPL_MOTDSTART = "375",
			RPL_MOTD = "372",
			RPL_ENDOFMOTD = "376",
			RPL_WHOISSECURE = "671",
			RPL_HELPSTART = "704",
			RPL_HELPTXT = "705",
			RPL_ENDOFHELP = "706",
			RPL_UMODEGMSG = "718",

			--Errors
			ERR_BANLISTFULL = "478",
			ERR_CHANNELISFULL = "471",
			ERR_UNKNOWNMODE = "472",
			ERR_INVITEONLYCHAN = "473",
			ERR_BANNEDFROMCHAN = "474",
			ERR_CHANOPRIVSNEEDED = "482",
			ERR_UNIQOPRIVSNEEDED = "485",
			ERR_USERNOTINCHANNEL = "441",
			ERR_NOTONCHANNEL = "442",
			ERR_NICKCOLLISION = "436",
			ERR_NICKNAMEINUSE = "433",
			ERR_ERRONEUSNICKNAME = "432",
			ERR_WASNOSUCHNICK = "406",
			ERR_TOOMANYCHANNELS = "405",
			ERR_CANNOTSENDTOCHAN = "404",
			ERR_NOSUCHCHANNEL = "403",
			ERR_NOSUCHNICK = "401",
			ERR_MODELOCK = "742",
		}

		-- main command handling callback.
		local function handleCommand(prefix, command, args, message)
			---------------------------------------------------
			-- Keepalive

			if command == "PING" then
				WS.Send(string.format("PONG :%s\r\n", message))

				---------------------------------------------------
				-- General commands
			elseif command == "NICK" then
				print(name(prefix) .. " is now known as " .. tostring(args[1] or message) .. ".")
			elseif command == "MODE" then
				print("[" .. args[1] .. "] Mode is now " .. tostring(args[2] or message) .. ".")
			elseif command == "QUIT" then
				print(name(prefix) .. " quit (" .. (message or "Quit") .. ").")
			elseif command == "JOIN" then
				print("[" .. args[1] .. "] " .. name(prefix) .. " entered the room.")
			elseif command == "PART" then
				print(
					"["
						.. args[1]
						.. "] "
						.. name(prefix)
						.. " has left the room (quit: "
						.. (message or "Quit")
						.. ")."
				)
			elseif command == "TOPIC" then
				print("[" .. args[1] .. "] " .. name(prefix) .. " has changed the topic to: " .. message)
			elseif command == "KICK" then
				print("[" .. args[1] .. "] " .. name(prefix) .. " kicked " .. args[2])
			elseif command == "PRIVMSG" then
				if string.find(message, "\001TIME\001") then
					WS.Send("NOTICE " .. name(prefix) .. " :\001TIME " .. os.date() .. "\001\r\n")
				elseif string.find(message, "\001VERSION\001") then
					WS.Send(
						"NOTICE "
							.. name(prefix)
							.. " :\001VERSION Minecraft/OpenComputers Port to Xinu pCsi Roblox Luau\001\r\n"
					)
				elseif string.find(message, "\001PING") then
					WS.Send("NOTICE " .. name(prefix) .. " :" .. message .. "\001\r\n")
				end
				if string.find(message, nick) then
					--sound??? user got mentioned?
				end
				if string.find(message, "\001ACTION") then
					print(
						"["
							.. args[1]
							.. "] "
							.. name(prefix)
							.. string.gsub(string.gsub(message, "\001ACTION", ""), "\001", "")
					)
				else
					print("[" .. args[1] .. "] " .. name(prefix) .. ": " .. message)
				end
			elseif command == "NOTICE" then
				print("[NOTICE] " .. message)
			elseif command == "ERROR" then
				print("[ERROR] " .. message)

				---------------------------------------------------
				-- Ignored reserved numbers
				-- -- http://tools.ietf.org/html/rfc2812#section-5.3
			elseif tonumber(command) and ignore[tonumber(command)] then
				-- ignore

				---------------------------------------------------
				-- Command replies
				-- http://tools.ietf.org/html/rfc2812#section-5.1
			elseif command == commands.RPL_WELCOME then
				print(message)
			elseif command == commands.RPL_YOURHOST then -- ignore
			elseif command == commands.RPL_CREATED then -- ignore
			elseif command == commands.RPL_MYINFO then -- ignore
			elseif command == commands.RPL_BOUNCE then -- ignore
			elseif command == commands.RPL_LUSERCLIENT then
				print(message)
			elseif command == commands.RPL_LUSEROP then -- ignore
			elseif command == commands.RPL_LUSERUNKNOWN then -- ignore
			elseif command == commands.RPL_LUSERCHANNELS then -- ignore
			elseif command == commands.RPL_LUSERME then
				print(message)
			elseif command == commands.RPL_AWAY then
				print(string.format("%s is away: %s", name(args[1]), message))
			elseif command == commands.RPL_UNAWAY or command == commands.RPL_NOWAWAY then
				print(message)
			elseif command == commands.RPL_WHOISUSER then
				local nick = args[2]:lower()
				whois[nick].nick = args[2]
				whois[nick].user = args[3]
				whois[nick].host = args[4]
				whois[nick].realName = message
			elseif command == commands.RPL_WHOISSERVER then
				local nick = args[2]:lower()
				whois[nick].server = args[3]
				whois[nick].serverInfo = message
			elseif command == commands.RPL_WHOISOPERATOR then
				local nick = args[2]:lower()
				whois[nick].isOperator = true
			elseif command == commands.RPL_WHOISIDLE then
				local nick = args[2]:lower()
				whois[nick].idle = tonumber(args[3])
			elseif command == commands.RPL_WHOISSECURE then
				local nick = args[2]:lower()
				whois[nick].secureconn = "Is using a secure connection"
			elseif command == commands.RPL_ENDOFWHOIS then
				local nick = args[2]:lower()
				local info = whois[nick]
				if info.nick then
					print("Nick: " .. info.nick)
				end
				if info.user then
					print("User name: " .. info.user)
				end
				if info.realName then
					print("Real name: " .. info.realName)
				end
				if info.host then
					print("Host: " .. info.host)
				end
				if info.server then
					print("Server: " .. info.server .. (info.serverInfo and (" (" .. info.serverInfo .. ")") or ""))
				end
				if info.secureconn then
					print(info.secureconn)
				end
				if info.channels then
					print("Channels: " .. info.channels)
				end
				if info.idle then
					print("Idle for: " .. info.idle)
				end
				whois[nick] = nil
			elseif command == commands.RPL_WHOISCHANNELS then
				local nick = args[2]:lower()
				whois[nick].channels = message
			elseif command == commands.RPL_CHANNELMODEIS then
				print("Channel mode for " .. args[1] .. ": " .. args[2] .. " (" .. args[3] .. ")")
			elseif command == commands.RPL_NOTOPIC then
				print("No topic is set for " .. args[1] .. ".")
			elseif command == commands.RPL_TOPIC then
				print("Topic for " .. args[1] .. ": " .. message)
			elseif command == commands.RPL_NAMREPLY then
				local channel = args[3]
				table.insert(names[channel], message)
			elseif command == commands.RPL_ENDOFNAMES then
				local channel = args[2]
				print(
					"Users on "
						.. channel
						.. ": "
						.. (#names[channel] > 0 and table.concat(names[channel], " ") or "none")
				)
				names[channel] = nil
			elseif command == commands.RPL_MOTDSTART then
			elseif command == commands.RPL_MOTD then
			elseif command == commands.RPL_ENDOFMOTD then -- ignore
			elseif
				command == commands.RPL_HELPSTART
				or command == commands.RPL_HELPTXT
				or command == commands.RPL_ENDOFHELP
			then
				print(message)
			elseif
				command == commands.ERR_BANLISTFULL
				or command == commands.ERR_BANNEDFROMCHAN
				or command == commands.ERR_CANNOTSENDTOCHAN
				or command == commands.ERR_CHANNELISFULL
				or command == commands.ERR_CHANOPRIVSNEEDED
				or command == commands.ERR_ERRONEUSNICKNAME
				or command == commands.ERR_INVITEONLYCHAN
				or command == commands.ERR_NICKCOLLISION
				or command == commands.ERR_NOSUCHNICK
				or command == commands.ERR_NOTONCHANNEL
				or command == commands.ERR_UNIQOPRIVSNEEDED
				or command == commands.ERR_UNKNOWNMODE
				or command == commands.ERR_USERNOTINCHANNEL
				or command == commands.ERR_WASNOSUCHNICK
				or command == commands.ERR_MODELOCK
			then
				print("[ERROR]: " .. message)
			elseif tonumber(command) and (tonumber(command) >= 200 and tonumber(command) < 400) then
				print("[Response " .. command .. "] " .. table.concat(args, ", ") .. ": " .. message)

				---------------------------------------------------
				-- Error messages. No real point in handling those manually.
				-- http://tools.ietf.org/html/rfc2812#section-5.2
			elseif tonumber(command) and (tonumber(command) >= 400 and tonumber(command) < 600) then
				print("[Error] " .. table.concat(args, ", ") .. ": " .. message)

				---------------------------------------------------
				-- Unhandled message.
			else
				print("Unhandled command: " .. command .. ": " .. message)
			end
		end

		local kr = false

		-- catch errors to allow manual closing of socket and removal of timer.
		local result, reason = pcall(function()
			-- say hello.
			essentials.Output:OutputToAll("ClearScreen")

			print("Welcome to OpenIRC! (Ported from OpenComputers)")

            if WS.IsConnected() then
                WS.Disconnect()
            end
    
            WS.StartListen(1)
			
			repeat
				task.wait(3)
				WS.Connect("http://"..host)
			until WS.IsConnected()
            WS.onopen = function()print("Connected to "..host) end

			-- http://tools.ietf.org/html/rfc2812#section-3.1
			WS.Send(string.format("NICK %s\r\n", nick))
			WS.Send(string.format("USER %s 0 * :%s [OpenComputers]\r\n", nick:lower(), nick))

			-- socket reading logic (receive messages) driven by a timer.

				WS.onmessage = function(line)
					if not line then
						print("Connection lost.")
						WS.Disconnect()
						WS.onmessage = nil
						return false
					end
					line = string.match(line, "^%s*(.-)%s*$") -- get rid of trailing \r
					local match, prefix = line:match("^(:(%S+) )")
					if match then
						line = line:sub(#match + 1)
					end
					local match, command = line:match("^(([^:]%S*))")
					if match then
						line = line:sub(#match + 1)
					end
					local args = {}
					repeat
						local match, arg = line:match("^( ([^:]%S*))")
						if match then
							line = line:sub(#match + 1)
							table.insert(args, arg)
						end
					until not match
					local message = line:match("^ :(.*)$")

					if callback then
						local result, reason = pcall(callback, prefix, command, args, message)
						if not result then
							print("Error in callback: " .. tostring(reason))
						end
					end
					handleCommand(prefix, command, args, message)
				end

            	-- avoid sock:read locking up the computer.
		
			-- default target for messages, so we don't have to type /msg all the time.
          

			local target = nil

			-- command history.
			local history = {}

			repeat
				local line = pCsi.io.read()
				if WS.onmessage and line and line ~= "" then
					line = string.match(line, "^%s*(.-)%s*$")
					if line:lower():sub(1, 4) == "/me " then
						print("[" .. (target or "?") .. "] You " .. string.gsub(line, "/me ", ""), true)
					else
						print("[" .. (target or "?") .. "] me: " .. line, true)
					end
					if line:lower():sub(1, 5) == "/msg " then
						local user, message = line:sub(6):match("^(%S+) (.+)$")
						if message then
							message = string.match(message, "^%s*(.-)%s*$")
						end
						if not user or not message or message == "" then
							print("Invalid use of /msg. Usage: /msg nick|channel message.")
							line = ""
						else
							target = user
							line = "PRIVMSG " .. target .. " :" .. message
						end
					elseif line:lower():sub(1, 6) == "/join " then
						local channel = string.match(line:sub(7), "^%s*(.-)%s*$")
						if not channel or channel == "" then
							print("Invalid use of /join. Usage: /join channel.")
							line = ""
						else
							target = channel
							line = "JOIN " .. channel
						end
					elseif line:lower():sub(1, 4) == "/me " then
						if not target then
							print("No default target set. Use /msg or /join to set one.")
							line = ""
						else
							line = "PRIVMSG " .. target .. " :\001ACTION " .. line:sub(5) .. "\001"
						end
					elseif line:sub(1, 1) == "/" then
						line = line:sub(2)
					elseif line ~= "" then
						if not target then
							print("No default target set. Use /msg or /join to set one.")
							line = ""
						else
							line = "PRIVMSG " .. target .. " :" .. line
						end
					end
					if line and line ~= "" then
						WS.Send(line .. "\r\n")
					end
				end
			until not WS.onmessage or not line
		end)

		if WS.onmessage then
			WS.Send("QUIT\r\n")
			WS.Disconnect()
            WS.onmessage = nil
		end
	
		if not result then
			error(reason..debug.traceback())
		end
		return reason
	end,
}

return cmd
