return function(core)
	local shell = {}

	function shell.parse(...)
		local params = table.pack(...)
		local args = {}
		local options = {}
		local doneWithOptions = false
		for i = 1, params.n do
			local param = params[i]
			if not doneWithOptions and type(param) == "string" then
				if param == "--" then
					doneWithOptions = true -- stop processing options at `--`
				elseif utf8.sub(param, 1, 2) == "--" then
					if param:match("%-%-(.-)=") ~= nil then
						options[param:match("%-%-(.-)=")] = param:match("=(.*)")
					else
						options[utf8.sub(param, 3)] = true
					end
				elseif utf8.sub(param, 1, 1) == "-" and param ~= "-" then
					for j = 2, utf8.len(param) do
						options[utf8.sub(param, j, j)] = true
					end
				else
					table.insert(args, param)
				end
			else
				table.insert(args, param)
			end
		end
		return args, options
	end

    local function recurseTable(tbl, func)
        for index, value in pairs(tbl) do
            if type(value) == "table" and not value.name and not value.fn then
                recurseTable(value, func)
            else
                func(index, value)
            end
        end
    end

    local allcommands = {}
    recurseTable(core.commands, function(i, v)
        if type(v) == "table" and not v.__isDir then
            allcommands[v.name] = v
        end
    end)

	function shell.get()
		local proxy = newproxy(true)
		return setmetatable(getmetatable(proxy), { 
            __call = function(...)
                local args = {...}
                return allcommands[args[2]] and allcommands[args[2]].fn(...) or nil--function(plr, pCsi, essentials, args)
            end
        })
	end

	function shell.execute(command, env, ...)
		local sh, reason = shell.get()
		if not sh then
			return false, reason
		end
		local result = table.pack(pcall(sh, env, command, ...))
		if not result[1] and type(result[2]) == "table" and result[2].reason == "terminated" then
			if result[2].code then
				return true
			else
				return false, "terminated"
			end
		end
		return table.unpack(result, 1, result.n)
	end

	return shell
end
