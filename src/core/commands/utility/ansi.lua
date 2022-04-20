local schedules = {}

local cmd = {
	name = script.Name,
	desc = [[Schedule commands at a later time, arg1 must be a %X date (HH:MM:SS)]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local txt = ""
		for i = 1, 47 do
			--pCsi.io.write("\x1b[2J")
			txt ..= "\x1b[" .. i .. "m turtsis"
			if (i % 10) == 0 then
				pCsi.io.write(txt)
				txt = ""
			end
		end
	end,
}

return cmd
