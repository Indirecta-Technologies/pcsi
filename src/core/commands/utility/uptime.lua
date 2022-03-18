local stTime = 0

local cmd = {
	name = script.Name,
	desc = [[pCsi uptime]],
    displayOutput = true,
	usage = [[$ uptime]],
    ready = function()
        stTime = tick()
    end,
	fn = function(plr, pCsi, essentials, args)
		--edit to behave more like uname command?

		local seconds = math.floor(tick() - stTime)
		local minutes, hours = 0, 0
		if seconds >= 60 then
			minutes = math.floor(seconds / 60)
			seconds = seconds % 60
		end
		if minutes >= 60 then
			hours = math.floor(minutes / 60)
			minutes = minutes % 60
		end
		return (string.format("%02d:%02d:%02d", hours, minutes, seconds))
	end,
}

return cmd
