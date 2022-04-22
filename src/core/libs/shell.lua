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

    function sh.internal.resolveActions(input, resolved)
		resolved = resolved or {}

		local processed = {}

		local prev_was_delim = true
		local words, reason = tokenize(input)

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
							words = tx.concat(replacement_tokens, words)
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

	return sh
end
