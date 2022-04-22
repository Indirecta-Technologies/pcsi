return function(lm)
	local sh = {}

    function sh.internal.isWordOf(w, vs)
		return w and #w == 1 and not w[1].qr and lm.libs.text.first(vs, { { w[1].txt } }) ~= nil
	end

	local isWordOf = sh.internal.isWordOf

    function sh.internal.isIdentifier(key)
		if type(key) ~= "string" then
			return false
		end

		return key:match("^[%a_][%w_]*$") == key
	end

    sh.internal.ec = {}
	sh.internal.ec.parseCommand = 127
	sh.internal.ec.last = 0

	function sh.getLastExitCode()
		return sh.internal.ec.last
	end

    function sh.internal.command_result_as_code(ec, reason)
		-- convert lua result to bash ec
		local code
		if ec == false then
			code = 1
		elseif ec == nil or ec == true then
			code = 0
		elseif type(ec) ~= "number" then
			code = 2 -- illegal number
		else
			code = ec
		end

		if reason and code ~= 0 then
			lm.io.write(reason, "\n")
		end
		return code
	end

    function sh.internal.command_passed(ec)
        return sh.internal.command_result_as_code(ec) == 0
      end

    function sh.internal.resolveActions(input, resolved)
		resolved = resolved or {}

		local processed = {}

		local prev_was_delim = true
		local words, reason = lm.libs.text.internal.tokenize(input)

		if not words then
			return nil, reason
		end

		while #words > 0 do
			local next = table.remove(words, 1)
			if isWordOf(next, { ";", "&&", "||", "|" }) then
				prev_was_delim = true
				resolved = {}
			elseif prev_was_delim then
				prev_was_delim = false
				-- if current is actionable, resolve, else pop until delim
				if next and #next == 1 and not next[1].qr then
					local key = next[1].txt
					if key == "!" then
						prev_was_delim = true -- special redo
					elseif not resolved[key] then
						--resolved[key] = shell.getAlias(key)
						local value = resolved[key]
						if value and key ~= value then
							local replacement_tokens, resolve_reason = sh.internal.resolveActions(value, resolved)
							if not replacement_tokens then
								return replacement_tokens, resolve_reason
							end
							words = lm.libs.transforms.concat(replacement_tokens, words)
							next = table.remove(words, 1)
						end
					end
				end
			end

			table.insert(processed, next)
		end

		return processed
	end


	function sh.expand(value)
		local expanded = value
			:gsub("%$([_%w%?]+)", function(key)
				return lm.vars[key] or ""
			end)
			:gsub("%${(.*)}", function(key)
				if sh.internal.isIdentifier(key) then
					return lm.vars[key] or ""
				end
				error("${" .. key .. "}: bad substitution\n")
			end)
		return expanded
	end

    	
function sh.internal.splitStatements(words, semicolon)

	semicolon = semicolon or ";"
	
	return lm.libs.transforms.partition(words, function(g, i)
	  if isWordOf(g, {semicolon}) then
		return i, i
	  end
	end, true)
  end
  
  function sh.internal.splitChains(s,pc)
	
	pc = pc or "|"
	return lm.libs.transforms.partition(s, function(w)
	  -- each word has multiple parts due to quotes
	  if isWordOf(w, {pc}) then
		return true
	  end
	end, true) -- drop |s
  end
  
  function sh.internal.groupChains(s)
	return lm.libs.transforms.partition(s,function(w)return isWordOf(w,{"&&","||"})end)
  end 
  
  function sh.internal.remove_negation(chain)
	if isWordOf(chain[1], {"!"}) then
	  table.remove(chain, 1)
	  return not sh.internal.remove_negation(chain)
	end
	return false
  end
  
  function sh.internal.execute_complex(words, eargs, env)
	-- we shall validate pipes before any statement execution
	local statements = sh.internal.splitStatements(words)
	for i=1,#statements do
	  local ok, why = sh.internal.hasValidPiping(statements[i])
	  if not ok then return nil,why end
	end
  
	for si=1,#statements do local s = statements[si]
	  local chains = sh.internal.groupChains(s)
	  local last_code, reason = sh.internal.boolean_executor(chains, function(chain, chain_index)
		local pipe_parts = sh.internal.splitChains(chain)
		local next_args = chain_index == #chains and si == #statements and eargs or {}
		return sh.internal.executePipes(pipe_parts, next_args, env)
	  end)
	  sh.internal.ec.last = sh.internal.command_result_as_code(last_code, reason)
	end
	return sh.internal.ec.last == 0
  end
  
  -- params: words[tokenized word list]
  -- return: command args, redirects
  function sh.internal.evaluate(words)
	local redirects, why = sh.internal.buildCommandRedirects(words)
	if not redirects then
	  return nil, why
	end
  
	do
	  local normalized = lm.libs.text.internal.normalize(words)
	  local command_text = table.concat(normalized, " ")
	  local subbed = sh.internal.parse_sub(command_text)
	  if subbed ~= command_text then
		words = lm.libs.text.internal.tokenize(subbed)
	  end
	end
  
	local repack = false
	for _, word in ipairs(words) do
	  for _, part in pairs(word) do
		if not (part.qr or {})[3] then
		  local expanded = sh.expand(part.txt)
		  if expanded ~= part.txt then
			part.txt = expanded
			repack = true
		  end
		end
	  end
	end
  
	if repack then
	  local normalized = lm.libs.text.internal.normalize(words)
	  local command_text = table.concat(normalized, " ")
	  words = lm.libs.text.internal.tokenize(command_text)
	end
  
	local args = {}
	for _, word in ipairs(words) do
	  local eword = { txt = "" }
	  for _, part in ipairs(word) do
		eword.txt = eword.txt .. part.txt
		eword[#eword + 1] = { qr = part.qr, txt = part.txt }
	  end
	  for _, arg in ipairs(sh.internal.glob(eword)) do
		args[#args + 1] = arg
	  end
	end
  
	return args, redirects
  end
  
  function sh.internal.parse_sub(input, quotes)
	-- unquoted command substituted text is parsed as individual parameters
	-- there is not a concept of "keeping whitespace" as previously thought
	-- we see removal of whitespace only because they are separate arguments
	-- e.g. /echo `echo a    b`/ becomes /echo a b/ quite literally, and the a and b are separate inputs
	-- e.g. /echo a"`echo b c`"d/ becomes /echo a"b c"d/ which is a single input
  
	if quotes and quotes[1] == '`' then
	  input = string.format("`%s`", input)
	  quotes[1], quotes[2] = "", "" -- substitution removes the quotes
	end
  
	-- cannot use gsub here becuase it is a [C] call, and io.popen needs to yield at times
	local packed = {}
	-- not using for i... because i can skip ahead
	local i, len = 1, #input
  
	while i <= len do
	  local fi, si, capture = input:find("`([^`]*)`", i)
  
	  if not fi then
		table.insert(packed, input:sub(i))
		break
	  end
	  table.insert(packed, input:sub(i, fi - 1))
  
	  local sub = lm.xfs.read(capture)
	  local result = sub:read("*a")
	  sub:close()
  
	  -- command substitution cuts trailing newlines
	  table.insert(packed, (result:gsub("\n+$","")))
	  i = si+1
	end
  
	return table.concat(packed)
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
  local allcommandnames = {}
  recurseTable(lm.commands, function(i, v)
      if type(v) == "table" and not v.__isDir then
          allcommands[v.name] = v
          table.insert(allcommandnames, v.name)
      end
  end)

  local function get_tip(context, wrong_name)
      local context_pool = {}
      local possible_name
      local possible_names = {}

      for name in pairs(context) do
          if type(name) == "string" then
              for i = 1, #name do
                  possible_name = name:sub(1, i - 1) .. name:sub(i + 1)

                  if not context_pool[possible_name] then
                      context_pool[possible_name] = {}
                  end

                  table.insert(context_pool[possible_name], name)
              end
          end
      end

      for i = 1, #wrong_name + 1 do
          possible_name = wrong_name:sub(1, i - 1) .. wrong_name:sub(i + 1)

          if context[possible_name] then
              possible_names[possible_name] = true
          elseif context_pool[possible_name] then
              for _, name in ipairs(context_pool[possible_name]) do
                  possible_names[name] = true
              end
          end
      end

      local first = next(possible_names)
      print(table.concat(possible_names))
      if first then
          if next(possible_names, first) then
              local possible_names_arr = {}

              for name in pairs(possible_names) do
                  table.insert(possible_names_arr, "'" .. name .. "'")
              end

              table.sort(possible_names_arr)
              return "\nDid you mean one of these: " .. table.concat(possible_names_arr, ", ") .. "?"
          else
              return "\nDid you mean '" .. first .. "'?"
          end
      else
          return ""
      end
  end

  function sh.internal.createThreads(commands, env, start_args, plr)
    -- Piping data between programs works like so:
    -- program1 gets its output replaced with our custom stream.
    -- program2 gets its input replaced with our custom stream.
    -- repeat for all programs
    -- custom stream triggers execution of "next" program after write.
    -- custom stream triggers yield before read if buffer is empty.
    -- custom stream may have "redirect" entries for fallback/duplication.
    local threads = {}
    for i = 1, #commands do
        local command = commands[i]
        local program, args, redirects = table.unpack(command)
        local name = tostring(program)
        if not allcommands[name] then
            lm.io.write(
							"'"
								.. command
								.. "' is not recognized as an internal or external command, operable program or batch file."
								.. get_tip(allcommands, command)
						)
        end
        local thread_env = type(program) == "string" and env or nil
        local r = lm:execute(plr, allcommands[command], args)
        if r and allcommands[command].displayOutput then
            lm.io.write(r)
        end
    

            args = table.concat(args, start_args[i] or {}, table.pack(r))

            -- popen expects each process to first write an empty string
            -- this is required for proper thread order
            lm.io.write("")
            local thread = table.unpack(args, 1, args.n or #args)

        if not thread then

            return nil, ""
        end

        threads[i] = thread
    end

    return threads
end

    function sh.internal.executePipes(pipe_parts, eargs, env, plr)
		local commands = {}
		for _, words in ipairs(pipe_parts) do
			local args = {}
			local reparse
			for _, word in ipairs(words) do
				local value = ""
				for _, part in ipairs(word) do
					reparse = reparse or part.qr or part.txt:find("[%$%*%?<>]")
					value = value .. part.txt
				end
				args[#args + 1] = value
			end

			local redirects
			if reparse then
				args, redirects = sh.internal.evaluate(words)
				if not args then
					return false, redirects -- in this failure case, redirects has the error message
				end
			end

			commands[#commands + 1] = table.pack(table.remove(args, 1), args, redirects)
		end

		local threads, reason = sh.internal.createThreads(commands, env, { [#commands] = eargs }, plr)
		if not threads then
			return false, reason
		end
		return threads, reason
	end

    function sh.internal.remove_negation(chain)
		if isWordOf(chain[1], {"!"}) then
		  table.remove(chain, 1)
		  return not sh.internal.remove_negation(chain)
		end
		return false
	  end

	  function sh.internal.hasValidPiping(words, pipes)
		
	  
		if #words == 0 then
		  return true
		end
	  
		local semi_split = lm.libs.transforms.first(lm.libs.text.syntax, {{";"}}) -- symbols before ; are redirects and follow slightly different rules, see buildCommandRedirects
		pipes = pipes or lm.libs.transforms.sub(lm.libs.text.syntax, semi_split + 1)
	  
		local state = "" -- cannot start on a pipe
		
		for w=1,#words do
		  local word = words[w]
		  for p=1,#word do
			local part = word[p]
			if part.qr then
			  state = nil
			elseif part.txt == "" then
			  state = nil -- not sure how this is possible (empty part without quotes?)
			elseif #lm.libs.text.split(part.txt, pipes, true) == 0 then
			  local prev = state
			  state = part.txt
			  if prev then -- cannot have two pipes in a row
				word = nil
				break
			  end
			else
			  state = nil
			end
		  end
		  if not word then -- bad pipe
			break
		  end
		end
	  
		if state then
		  return false, "syntax error near unexpected token " .. state
		else
		  return true
		end
	  end
	  
	  function sh.internal.boolean_executor(chains, predicator)
		local function not_gate(result, reason)
		  return sh.internal.command_passed(result) and 1 or 0, reason
		end
	  
		local last = true
		local last_reason
		local boolean_stage = 1
		local negation_stage = 2
		local command_stage = 0
		local stage = negation_stage
		local skip = false
	  
		for ci=1,#chains do
		  local next = chains[ci]
		  local single = #next == 1 and #next[1] == 1 and not next[1][1].qr and next[1][1].txt
	  
		  if single == "||" then
			if stage ~= command_stage or #chains == 0 then
			  return nil, "syntax error near unexpected token '"..single.."'"
			end
			if sh.internal.command_passed(last) then
			  skip = true
			end
			stage = boolean_stage
		  elseif single == "&&" then
			if stage ~= command_stage or #chains == 0 then
			  return nil, "syntax error near unexpected token '"..single.."'"
			end
			if not sh.internal.command_passed(last) then
			  skip = true
			end
			stage = boolean_stage
		  elseif not skip then
			local chomped = #next
			local negate = sh.internal.remove_negation(next)
			chomped = chomped ~= #next
			if negate then
			  local prev = predicator
			  predicator = function(n,i)
				local result, reason = not_gate(prev(n,i))
				predicator = prev
				return result, reason
			  end
			end
			if chomped then
			  stage = negation_stage
			end
			if #next > 0 then
			  last, last_reason = predicator(next,ci)
			  stage = command_stage
			end
		  else
			skip = false
			stage = command_stage
		  end
		end
	  
		if stage == negation_stage then
		  last = not_gate(last)
		end
	  
		return last, last_reason
	  end

    function sh.internal.execute_complex(words, eargs, env, plr)
		-- we shall validate pipes before any statement execution
		local statements = sh.internal.splitStatements(words)
		for i=1,#statements do
		  local ok, why = sh.internal.hasValidPiping(statements[i])
		  if not ok then return nil,why end
		end
	  
		for si=1,#statements do local s = statements[si]
		  local chains = sh.internal.groupChains(s)
		  local last_code, reason = sh.internal.boolean_executor(chains, function(chain, chain_index)
			local pipe_parts = sh.internal.splitChains(chain)
			local next_args = chain_index == #chains and si == #statements and eargs or {}
			return sh.internal.executePipes(pipe_parts, next_args, env, plr)
		  end)
		  sh.internal.ec.last = sh.internal.command_result_as_code(last_code, reason)
		end
		return sh.internal.ec.last == 0
	  end

  

    function sh.execute(plr, env, command: string, ...)
		if command:find("^%s*#") then
			return true, 0
		end

		local words, reason = sh.internal.resolveActions(command)
		if type(words) ~= "table" then
			return words, reason
		elseif #words == 0 then
			return true
		end

		-- MUST be table.pack for non contiguous ...
		local eargs = table.pack(...)

		-- simple
		if not command:find("[;%$&|!<>]") then
			sh.internal.ec.last = sh.internal.command_result_as_code(sh.internal.executePipes({ words }, eargs, env, plr))
			return sh.internal.ec.last == 0
		end

		return sh.internal.execute_complex(words, eargs, env)
	end

	return sh
end
