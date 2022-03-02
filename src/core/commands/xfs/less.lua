local cmd = {
	name = script.Name,
	desc = [[Display text on a page-by-page basis]],
	displayOutput = true,
	usage = [[$ more file.txt 12]],
	fn = function(plr, pCsi, essentials, args)
		local str = pCsi.xfs.exists(args[1]) and pCsi.xfs.read(args[1]) or table.concat(args)
		local lines = tonumber(args[#args]) or 13
		local buffer = ""

		local inc = 0
		local page = 0

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
          local allines = split_newlines(str)
        
		for i = #allines, 1, -1 do
            local char = allines[i]
			inc += 1
			buffer ..= char .. "\n" --"<b>"..tostring(i < 10 and "0"..i or i).."</b> "..char.."\n"
			if inc >= lines then
				page += 1
                essentials.Output:OutputToAll("ClearScreen");
				pCsi.io.write(buffer:gsub("&", "&amp;")
                :gsub("<", "&lt;")
                :gsub(">", "&gt;")
                :gsub('"', "&quot;")
                :gsub("'", "&apos;"))
				buffer = ""
				inc = 0
                pCsi.io.write("<b> PAGE " .. page .. "/"..math.round(#allines/13).." | "..math.round((i/#allines)*1000)/10 .. "%</b>")
				if pCsi.io.read() == "q" then break end
			end
            print(inc, i, #allines)
		end
	end,
}

return cmd
