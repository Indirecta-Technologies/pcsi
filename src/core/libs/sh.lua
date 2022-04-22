return function(core)
	local process = require("process")
	local shell = require("shell")
	local text = require("text")
	local tx = require("transforms")

	local sh = {}
	sh.internal = {}

	local function range_adjust(f,l,s)
		if f==nil then f=1 elseif f<0 then f=s+f+1 end
		if l==nil then l=s elseif l<0 then l=s+l+1 end
		return f,l
	  end
	  local function table_view(tbl,f,l)
		return setmetatable({},
		{
		  __index = function(_, key)
			return (type(key) ~= 'number' or (key >= f and key <= l)) and tbl[key] or nil
		  end,
		  __len = function(_)
			return l
		  end,
		})
	  end
	  local adjust= range_adjust
	  local view= table_view

	local function begins(tbl,v,f,l)
	
		local vs=#v
		f,l=adjust(f,l,#tbl)
		if vs>(l-f+1)then return end
		for i=1,vs do
		  if tbl[f+i-1]~=v[i] then return end
		end
		return true
	  end
	local function first(tbl,pred,f,l)
		if type(pred)=='table'then
			local set;set,pred=pred,function(e,fi,tbl)
			  for vi=1,#set do
				local v=set[vi]
				if begins(tbl,v,fi) then return true,#v end
			  end
			end
		  end
		  local s=#tbl
		  f,l=adjust(f,l,s)
		  tbl=view(tbl,f,l)
		  for i=f,l do
			local si,ei=pred(tbl[i],i,tbl)
			if si then
			  return i,i+(ei or 1)-1
			end
		  end
	end
	function sh.internal.isWordOf(w, vs)
		return w and #w == 1 and not w[1].qr and first(vs, { { w[1].txt } }) ~= nil
	end

	local isWordOf = sh.internal.isWordOf

	-------------------------------------------------------------------------------

	--SH API

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
		local words, reason = text.internal.tokenize(input)

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
						resolved[key] = shell.getAlias(key)
						local value = resolved[key]
						if value and key ~= value then
							local replacement_tokens, resolve_reason = sh.internal.resolveActions(value, resolved)
							if not replacement_tokens then
								return replacement_tokens, resolve_reason
							end
							words = table.concat(replacement_tokens, words)
							next = table.remove(words, 1)
						end
					end
				end
			end

			table.insert(processed, next)
		end

		return processed
	end

	-- returns true if key is a string that represents a valid command line identifier
	function sh.internal.isIdentifier(key)
		if type(key) ~= "string" then
			return false
		end

		return key:match("^[%a_][%w_]*$") == key
	end

	-- expand (interpret) a single quoted area
	-- examples: $foo or "$foo"
	function sh.expand(value)
		local expanded = value
			:gsub("%$([_%w%?]+)", function(key)
				return core.getVar(key) or ""
			end)
			:gsub("%${(.*)}", function(key)
				if sh.internal.isIdentifier(key) then
					return core.getVar(key) or ""
				end
				error("${" .. key .. "}: bad substitution\n")
			end)
		return expanded
	end

	function sh.internal.createThreads(commands, env, start_args)
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
			local thread_env = type(program) == "string" and env or nil
			local thread, reason = process.load(program or "/dev/null", thread_env, function(...)
				if redirects then
					sh.internal.openCommandRedirects(redirects)
				end

				args = table.concat(args, start_args[i] or {}, table.pack(...))

				-- popen expects each process to first write an empty string
				-- this is required for proper thread order
				core.io.write("")
				return table.unpack(args, 1, args.n or #args)
			end, name)

			if not thread then
				for _, t in ipairs(threads) do
					process.internal.close(t)
				end
				return nil, reason
			end

			threads[i] = thread
		end

		if #threads > 1 then
			require("pipe").buildPipeChain(threads)
		end

		return threads
	end

	function sh.internal.executePipes(pipe_parts, eargs, env)
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

		local threads, reason = sh.internal.createThreads(commands, env, { [#commands] = eargs })
		if not threads then
			return false, reason
		end
		return process.internal.continue(threads[1])
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
	  
		local semi_split = tx.first(text.syntax, {{";"}}) -- symbols before ; are redirects and follow slightly different rules, see buildCommandRedirects
		pipes = pipes or tx.sub(text.syntax, semi_split + 1)
	  
		local state = "" -- cannot start on a pipe
		
		for w=1,#words do
		  local word = words[w]
		  for p=1,#word do
			local part = word[p]
			if part.qr then
			  state = nil
			elseif part.txt == "" then
			  state = nil -- not sure how this is possible (empty part without quotes?)
			elseif #text.split(part.txt, pipes, true) == 0 then
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
	  

	function sh.execute(env, command: string, ...)
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
			sh.internal.ec.last = sh.internal.command_result_as_code(sh.internal.executePipes({ words }, eargs, env))
			return sh.internal.ec.last == 0
		end

		return sh.internal.execute_complex(words, eargs, env)
	end

	function sh.hintHandler(full_line, cursor)
		return sh.internal.hintHandlerImpl(full_line, cursor)
	end

	return sh
end