local cmd = {
	name = script.Name,
	desc = [[Displays info about Xinu]],
	usage = [[$ info]],
	fn = function(plr, pCsi, essentials, args)
		local perf = essentials.PerformanceStats()
		--[[
		
		{
			ClockSpeed = clockspeed,
			"GHz",
			ClockJitter = clockjitter,
			"xJ",
			GCMemory = gcinfo() * 0.9,
			"KB",
			ResourceUtilization = resourceutilization,
			"%",
			Units = { "GHz", "xJ", "KB", "%" },
		}

		]]
		essentials.Console.info("-- System Performance --\n"..
			"Clock Speed: "..perf.ClockSpeed.." "..perf.Units[1].."\n"..
			"Clock Jitter: "..perf.ClockJitter.." "..perf.Units[2].."\n"..
			"GCMemory: "..perf.GCMemory.." "..perf.Units[3].."\n"..
			"RAM Utilization: "..perf.ResourceUtilization.." "..perf.Units[4].."\n"..
			"- docs/xinu/introduction-to-xinu/performance-stats -\n"..
			"-- End of System Performance --"
		)
	end,
}

return cmd
