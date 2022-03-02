local cmd = {
	name = script.Name,
	desc = [[Return the last 10 lines of a file]],
	displayOutput = true,
	usage = [[$ tail file.txt 12]],
	fn = function(plr, pCsi, essentials, args)
		local str = pCsi.xfs.exists(args[1]) and pCsi.xfs.read(args[1]) or table.concat(args)
		local lines = tonumber(args[#args]) or 10
		local buffer = ""

		local function split_newlines(s)
			local ts = {}
			local posa = 1
			while 1 do
			  local pos, chars = s:match('()([\r\n].?)', posa)
			  if pos then
				if chars == '\r\n' then pos = pos + 1 end
				local line = s:sub(posa, pos)
				ts[#ts+1] = line
				posa = pos + 1
			  else
				local line = s:sub(posa)
				if line ~= '' then ts[#ts+1] = line end
				break      
			  end
			end
			return ts
		  end

        local splitt = split_newlines(str)

        local inc = 0
		for i = #splitt, 1, -1 do
            inc += 1
			local object = splitt[i]
            buffer ..= object .. "\n"--"<b>" .. tostring(i < 10 and "0" .. i or i) .. "</b> " .. object .. "\n"
            if inc >= lines then break end
		end

		local buffer2 = ""
		for char in string.gmatch(buffer, utf8.charpattern) do
			buffer2 ..= char -- show only unicode characters, prevents richtext from breaking
		end
		return (#buffer2 == 0 and "(empty)" or buffer2)
			:gsub("&", "&amp;")
			:gsub("<", "&lt;")
			:gsub(">", "&gt;")
			:gsub('"', "&quot;")
			:gsub("'", "&apos;")
	end,
}

return cmd
