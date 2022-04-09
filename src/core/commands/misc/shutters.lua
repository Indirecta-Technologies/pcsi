local events = {}
local Network = workspace:FindFirstChild("Record Firewall Fire Shutter System"):FindFirstChild("Network")

local cmd = {
	name = script.Name,
	desc = [[PLACEHOLDER]],
	usage = [[$ S ]],
	displayOutput = true,
    ready = function(pCsi, essentials)
        Network.Event:Connect(function(handshake, zone, command, actiontime)
            table.insert(events,os.date("%c",os.time()).." | "..command.." | "..zone.." | "..actiontime)
		end)
    end,
	fn = function(plr, pCsi, essentials, args)

		local function open(zone, delay)
			Network:Fire("@3ZCGdZ5#qtH2b_DBG7f2pj-d+nqa*mQ", zone, "open", delay or 0)
		end
		local function close(zone, delay)
			Network:Fire("@3ZCGdZ5#qtH2b_DBG7f2pj-d+nqa*mQ", zone, "close", delay or 0)
		end

        if args[1] then
            if args[1] == "open" then
                local zone = args.z or args.zone or 1
                local delay = args.d or args.delay or 0
                open(zone)
                return "Sent open command to zone "..zone..(delay == 0 and "" or "with a delay of "..delay)
            elseif args[1] == "close" then
                local zone = args.z or args.zone or 1
                local delay = args.d or args.delay or 0
                close(zone)
                return "Sent close command to zone "..zone..(delay == 0 and "" or "with a delay of "..delay)
            elseif args[1] == "logs" then
                return "| TIMESTAMP | COMMAND | ZONE | ACTION TIME |\n"..table.concat(events,"\n")
            elseif args[1] == "clear-logs" then
                events = {}
                return "Cleared ".. #events.." logs"
            end
        end

	end,
}

return cmd
