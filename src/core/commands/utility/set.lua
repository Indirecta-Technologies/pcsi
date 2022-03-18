local cmd = {
	name = script.Name,
	desc = [[Set OS Variable]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		if #args < 1 then
            local bfr = ""
            for k,v in pairs(pCsi.getVars()) do
              bfr ..= k .. "='" .. string.gsub(v, "'", [['"'"']]) .. "'\n"
            end
            return bfr
          else
            local count = 0 
            for _, expr in ipairs(args) do
              local e = expr:find('=')
              if e then
                pCsi.setVar(expr:sub(1,e-1), expr:sub(e+1))
              else
                if count == 0 then
                  for i = 1, pCsi.getVars('#') do
                    pCsi.setVar(i, nil)
                  end
                end
                count = count + 1
                pCsi.setVar(count, expr)
              end
            end
          end
	end,
}

return cmd
