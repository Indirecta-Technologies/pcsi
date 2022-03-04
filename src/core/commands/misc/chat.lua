local cmd = {
	name = script.Name,
	desc = [[Chat and display your identity]],
	usage = "$ chat",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		-- THIS DOES NOT FILTER MESSAGES YET!!!!!!!!!!!!!!!!

		-- Comunicate over a bindable in Server Storage, support authentication and encryption peer to peer (first person to start)?
		pCsi.io.write("Initializing chat..")
		local MessagingService = game:GetService("MessagingService")
		local topicname = "_xChat" .. game.GameId
		local remote

		remote = game:GetService("ServerStorage"):WaitForChild("_xChat" .. game.JobId, 3)
			or Instance.new("BindableEvent", game:GetService("ServerStorage"))
		remote.Name = "_xChat" .. game.JobId

		local oldparse = pCsi.parseCommand

		local room = pCsi.libs.sha_256().updateStr(game.JobId .. table.concat(args)).finish()
		local roomstr = room.asHex()

		local NAME_COLORS = {
			Color3.new(253 / 255, 41 / 255, 67 / 255), -- BrickColor.new("Bright red").Color,
			Color3.new(1 / 255, 162 / 255, 255 / 255), -- BrickColor.new("Bright blue").Color,
			Color3.new(2 / 255, 184 / 255, 87 / 255), -- BrickColor.new("Earth green").Color,
			BrickColor.new("Bright violet").Color,
			BrickColor.new("Bright orange").Color,
			BrickColor.new("Bright yellow").Color,
			BrickColor.new("Light reddish violet").Color,
			BrickColor.new("Brick yellow").Color,
		}

		local function GetNameValue(pName)
			local value = 0
			for index = 1, #pName do
				local cValue = string.byte(string.sub(pName, index, index))
				local reverseIndex = #pName - index + 1
				if #pName % 2 == 1 then
					reverseIndex = reverseIndex - 1
				end
				if reverseIndex % 4 >= 2 then
					cValue = -cValue
				end
				value = value + cValue
			end
			return value
		end

		local color_offset = 0
		local function ComputeNameColor(pName)
			return NAME_COLORS[((GetNameValue(pName) + color_offset) % #NAME_COLORS) + 1]
		end

		local aes256 = pCsi.libs.aes_256
		local ascii85 = pCsi.libs.ascii85
		local _key = aes256.schedule256(tonumber("0x" .. roomstr))

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

		local function filtermessage(player, message)
			local TextService = game:GetService("TextService")

			local textObject
			local success, errorMessage = pcall(function()
				textObject = TextService:FilterStringAsync(message, player.UserId)
			end)
			if not success then
				message = string.rep("_", #message)
			end

			local filteredMessage
			local success1, errorMessage2 = pcall(function()
				filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
			end)
			if success1 then
				message = filteredMessage
			else
				message = string.rep("_", #message)
			end
			return message
		end

		local subscribeSuccess, subscribeConnection = pcall(function()
			return MessagingService:SubscribeAsync(topicname, function(message)
				local data = message.Data
				data = jsoncrypt.decrypt(data, _key)
				if not data or not data.header or not data.player or not data.roomstr == roomstr then
					return
				end

				local displayname = "<b>?</b>"
				if data.player then
					local color = ComputeNameColor(data.player[2])
					displayname = '<b><font color="rgb('
						.. math.round(color.R * 255)
						.. ","
						.. math.round(color.G * 255)
						.. ","
						.. math.round(color.B * 255)
						.. ')">'
						.. data.player[2]
						.. "</font></b>"
				end

				if data.header == "startSession" then
					local text = displayname .. " joined"

					pCsi.io.write(text)
				elseif data.header == "endSession" then
					local text = displayname .. " left"

					pCsi.io.write(text)

				elseif data.header == "messageSession" and data.message then
					data.message = filtermessage(data.player[1], data.message)
					local text = "("
						.. displayname
						.. "): "
						.. data.message
							:gsub("&", "&amp;")
							:gsub("<", "&lt;")
							:gsub(">", "&gt;")
							:gsub('"', "&quot;")
							:gsub("'", "&apos;")
					pCsi.io.write(text)
				end
			end)
		end)

		essentials.Output:OutputToAll("ClearScreen")
		local text = "Joined chatroom <b>" .. string.upper(roomstr:sub(1, 16)) .. "</b>, use '!q' to leave"
		pCsi.io.write(text)

		local function startSession(plra)
			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(
					topicname,
					jsoncrypt.encrypt({
						header = "startSession",
						roomstr = roomstr,
						player = { plra.UserId, plra.Name },
					}, _key)
				)
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end
		local function endSession(plra)
			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(
					topicname,
					jsoncrypt.encrypt({
						header = "endSession",
						roomstr = roomstr,
						player = { plra.UserId, plra.Name },
					}, _key)
				)
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end

	

		local function processMessage(player, message)
			message = filtermessage(player, message)

			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(
					topicname,
					jsoncrypt.encrypt({
						header = "messageSession",
						roomstr = roomstr,
						player = { player.UserId, player.Name },
						message = message,
					}, _key)
				)
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end

		startSession(plr)
		function pCsi:parseCommand(...)
			input = { ... }
			local plra = input[1]
			table.remove(input, 1)
			input = table.concat(input)
			if input == "!quit" or input == "!q" then
				endSession(plra)

				pCsi.parseCommand = oldparse
			end
			if not plra == plr then
				pCsi.io.write(
					"This chat session is being used by <b>"
						.. plr.Name
						.. "</b>, consider ending the session? '!quit' "
				)
			end
			input = processMessage(plra, input)
		end
	end,
}

return cmd
