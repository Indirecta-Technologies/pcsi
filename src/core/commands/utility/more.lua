local cmd = {
	name = script.Name,
	desc = [[Split input into pages]],
	usage = [[$ more input]], -- allow user to input lines per page
    displayOutput = true,
	fn = function(pCsi, essentials,args)
		local oldparse = pCsi.parseCommand


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

		  local linesXPage = 9
		  local lines = split_newlines(table.concat(args, " "))

		  local buffer = ""
		  local mainI = 0
		  for i, v in ipairs(lines) do
			mainI += 1
			buffer ..= lines[mainI] 
			if i >= linesXPage then
				essentials.Console.info(buffer)
				essentials.Console.info("SPACE + ENTER = MORE | "..math.round((mainI/#lines)*1000)/10 .. "% | L"..mainI)
				i = 0
				local inputted = false
				function pCsi:parseCommand(args)
					inputted = true
				end
				repeat task.wait() until inputted
			elseif i == #lines then
				essentials.Console.info(buffer)
				pCsi.parseCommand = oldparse
			end
		  end

	end,
}

return cmd
