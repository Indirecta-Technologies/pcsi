local cmd = {
	name = script.Name,
	desc = [[Output connected DisplayOverBindable devices]],
	usage = "$ dob name MyScreen\n$ dob uuid EB127E3A-D774-4A89-8392-8D2BE464D4C9\n$ dob index 1\n$ dob devices",
	fn = function(plr, pCsi, essentials, args)
		--[[
		local newDevice = {
								Name = body.Name,
								Identifier = body.Identifier,
								Script = body.DeviceScript,
								Object = body.Object,
								SurfaceGui = body.SurfaceGui or nil,
								Resolution = body.SurfaceGui and
									{X = body.SurfaceGui.AbsoluteSize.X, Y = body.SurfaceGui.AbsoluteSize.Y} or
									nil,
								TextBuffer = "",
								LegacyTextLabel = body.LegacyTextLabel,
								LegacyTextYLimit = body.LegacyTextYLimit,
								DeviceType = (body.LegacyTextLabel and "LegacyMonitor" or
									(body.SurfaceGui and "Monitor" or (body.Object and "Device" or "Interface")));
								CustomEchoSettings = body.CustomEchoSettings or nil;
								CustomParams = body.CustomParams or nil;
		}
		]]
		
		local function deviceInfo(device)
			if not device or not device.Name or not device.Identifier then
				return essentials.Console.warn("Invalid device object passed to function")
			end
			essentials.Console.info(
				"Name: "..device.Name.."\n"..
				"Identifier: "..device.Name.."\n"..
				"Device Type: "..device.DeviceType.."\n"..
				(device.SurfaceGui and "Resolution: "..device.Resolution.X.."x"..device.Resolution.Y.."\n" or "")
			)
		end
		
		local device;
		
		if args[1] == "devices" then
			local buffer = "\nindex, identifier, name"
			for i,v in pairs(essentials.Output:GetAllDevices()) do
				buffer = buffer.."\n"..i..", "..v.Identifier..", "..v.Name
			end
			return essentials.Console.info(buffer)
		elseif args[1] == "name" then
			device = essentials.Output:GetDeviceByName(args[2])
		elseif args[1] == "index" then
			device = essentials.Output:GetAllDevices()[args[2]]
		elseif args[1] == "uuid" then
			device = essentials.Output:GetDeviceByIdentifier(args[2])
		end
		
		if device then 
			if args[3] == "info" then
				deviceInfo(device)
			end
			if args[3] == "output" then
				local fn = args[4]
				table.remove(args,1)
				table.remove(args,1)
				table.remove(args,1)
				table.remove(args,1)
				local text = table.concat(args, " ")
				device:Output(fn, text)
			end
		end
		
		end,
}

return cmd
