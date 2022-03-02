local cmd = {
	name = script.Name,
	desc = [[Return the last 10 lines of a file]],
	displayOutput = true,
	usage = [[$ tail file.txt 12]],
	fn = function(plr, pCsi, essentials, args)
		local str = pCsi.xfs.read(args[1])
		local lines = tonumber(args[2]) or 10
		local buffer = ""

        local splitt = string.split(str, "\n")

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
