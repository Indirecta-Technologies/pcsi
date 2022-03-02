local schedules = {}

local cmd = {
	name = script.Name,
	desc = [[Search for a pattern]],
	usage = [[$ ]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local filem = table.concat(args)
		local file = pCsi.xfs.exists(filem) and pCsi.xfs.read(filem) or ""
		local function crc32_nt(s)
			-- return crc32 checksum of string s as an integer
			-- uses no lookup table
			-- inspired by crc32b at
			-- http://www.hackersdelight.org/hdcodetxt/crc.c.txt
			local b, crc, mask
			crc = 0xffffffff
			for i = 1, #s do
				b = string.byte(s, i)
				crc = bit32.bxor(crc, b)
				for _ = 1, 8 do --eight times
					mask = - bit32.band(crc, 1)
					crc = bit32.bxor(bit32.rshift(crc, 1), bit32.band(0xedb88320, mask))
				end
			end--for
			return bit32.band(bit32.bxor(crc), 0xffffffff)
		end
		return filem.." "..crc32_nt(file).." "..#file
	end,
}

return cmd
