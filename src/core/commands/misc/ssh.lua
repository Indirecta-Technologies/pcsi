local address_msk = ("255.255.0.0"):split(".")
local address = ""

local topicname = "_xSecureShell" .. game.GameId

local MessagingService = game:GetService("MessagingService")

local cmd = {
	name = script.Name,
	desc = [[Chat and display your identity]],
	usage = "$ ssh",
	displayOutput = true,
	ready = function(pCsi, essentials)
		local aes256 = pCsi.libs.aes_256
		local ascii85 = pCsi.libs.ascii85

		local jsoncrypt = {
			encrypt = function(table, key)
				table["_timestamp"] = tick()
				local success, response = pcall(function()
					table = game:GetService("HttpService"):JSONEncode(table)
				end)
				if not success then
					return nil, response
				end
				return ascii85.encode(aes256.ECB(aes256.encrypt, key, table)) or nil
			end,
			decrypt = function(table, key)
				local success, response = pcall(function()
					table = ascii85.decode(table)
					table = aes256.ECB(aes256.decrypt, key, table) or nil
					table = game:GetService("HttpService"):JSONDecode(table)
				end)
				if not success then
					return nil, response
				end
				return table
			end,
		}
		address = ""
		for i, v in ipairs(address_msk) do
			if v == "255" then
				address ..= (i == 1 and "192" or "168")
			end
			if v == "0" then
				address ..= math.random(1, 255)
			end
			if i < #address_msk then
				address ..= "."
			end
		end

		local room = pCsi.libs.sha_256().updateStr(address).finish()
		local roomstr = room.asHex()

		local _key = aes256.schedule256(tonumber("0x" .. roomstr))

		local subscribeSuccess, subscribeConnection = pcall(function()
			return MessagingService:SubscribeAsync(topicname, function(message)
				local data = message.Data
				data = jsoncrypt.decrypt(data, _key)
				if not data or not data.header or not data.ip or not (data.roomstr == roomstr) then
					return
				end
				print("--> " .. game:GetService("HttpService"):JSONEncode(data))
				if data.header == "sshPacket_start" then
					essentials.Output.onEcho.Event:Connect(function(fullText)
						print(fullText)
						MessagingService:PublishAsync(
							topicname,
							jsoncrypt.encrypt({
								header = "sshPacket_out",
								roomstr = roomstr,
								ip = address,
								message = fullText,
							}, _key)
						)
					end)
					MessagingService:PublishAsync(
						topicname,
						jsoncrypt.encrypt({
							header = "sshPacket_ack",
							roomstr = roomstr,
							ip = address,
						}, _key)
					)
					--(fullText, header, color, text, timedate)
					pCsi.io.write("SSH Session started by <b>" .. data.ip .. "</b>")
				elseif data.header == "sshPacket_end" then
					pCsi.io.write("SSH Session ended by <b>" .. data.ip .. "</b>")
				elseif data.header == "sshPacket_in" and data.message and data.player then
					print(data.player.UserId, data.message)
					pCsi:parseCommand(data.player, data.message)
				end
			end)
		end)
		pCsi.io.write("IP Address: " .. address)
	end,
	fn = function(plr, pCsi, essentials, args)
		local aes256 = pCsi.libs.aes_256
		local ascii85 = pCsi.libs.ascii85

		local jsoncrypt = {
			encrypt = function(table, key)
				table["_timestamp"] = tick()
				local success, response = pcall(function()
					table = game:GetService("HttpService"):JSONEncode(table)
				end)
				if not success then
					return nil, response
				end
				return ascii85.encode(aes256.ECB(aes256.encrypt, key, table)) or nil
			end,
			decrypt = function(table, key)
				local success, response = pcall(function()
					table = ascii85.decode(table)
					table = aes256.ECB(aes256.decrypt, key, table) or nil
					table = game:GetService("HttpService"):JSONDecode(table)
				end)
				if not success then
					return nil, response
				end
				return table
			end,
		}

		if table.concat(args) == address then return pCsi.io.write("ERROR: Cannot ssh into localhost") end

		local room = pCsi.libs.sha_256().updateStr(table.concat(args)).finish()
		local roomstr = room.asHex()

		local _key = aes256.schedule256(tonumber("0x" .. roomstr))

		local subscribeSuccess, subscribeConnection = pcall(function()
			return MessagingService:SubscribeAsync(topicname, function(message)
				local data = message.Data
				data = jsoncrypt.decrypt(data, _key)
				task.wait()
				print("<-- " .. game:GetService("HttpService"):JSONEncode(data))

				if not data or not data.header or not data.ip or not (data.roomstr == roomstr) then
					return
				end
				if data.header == "sshPacket_ack" then
					pCsi.io.write("Estabilished connection with " .. data.ip)
				end
				if data.header == "sshPacket_out" then
					pCsi.io.write(data.ip .. " // " .. data.message)
				end
			end)
		end)
		if subscribeSuccess then essentials.Output:OutputToAll("ClearScreen") end

		local oldparse = pCsi.parseCommand

		function pCsi:parseCommand(...)
			input = { ... }
			local plra = input[1]
			table.remove(input, 1)
			input = table.concat(input)
			if input == "!quit" or input == "!q" then
				MessagingService:PublishAsync(
					topicname,
					jsoncrypt.encrypt({
						header = "sshPacket_end",
						roomstr = roomstr,
						ip = address,
					}, _key)
				)

				pCsi.parseCommand = oldparse
				return
			end
			if not (plra == plr) then
				return pCsi.io.write(
					"This ssh session is being used by <b>" .. plr.Name .. "</b>, consider ending the session? '!quit' "
				)
			end
			MessagingService:PublishAsync(
				topicname,
				jsoncrypt.encrypt({
					header = "sshPacket_in",
					roomstr = roomstr,
					ip = address,
					player = {
						Name = plra.Name,
						UserId = plra.UserId,
						AccountAge = plra.AccountAge,
					},
					message = input,
				}, _key)
			)
		end

		MessagingService:PublishAsync(
			topicname,
			jsoncrypt.encrypt({
				header = "sshPacket_start",
				roomstr = roomstr,
				ip = address,
				player = {
					Name = plr.Name,
					UserId = plr.UserId,
					AccountAge = plr.AccountAge,
				},
			}, _key)
		)
	end,
}

return cmd
