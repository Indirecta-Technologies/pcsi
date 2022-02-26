local cmd = {
	name = script.Name,
	desc = [[Outputs sha256 of input]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local passwordEntropy = function(value)
			local total, hasdigit, haslower, hasupper, hasspaces = 0, 0, 0, 0, false

			if string.find(value, "%d") then
				hasdigit = 1
			end
			if string.find(value, "%l") then
				haslower = 1
			end
			if string.find(value, "%u") then
				hasupper = 1
			end
			if string.find(value, " ") then
				hasspaces = true
			end

			local total = hasdigit * 10 + hasupper * 26 + haslower * 26
			local entropy = math.floor(math.log(total) * #value / math.log(2))

			return entropy
		end

		local function log2(x)
			return math.log(x) / math.log(2)
		end

		local function shannonEntropy(X)
			local N, count, sum, i = X:len(), {}, 0
			for char = 1, N do
				i = X:sub(char, char)
				if count[i] then
					count[i] = count[i] + 1
				else
					count[i] = 1
				end
			end
			for n_i, count_i in pairs(count) do
				sum = sum + count_i / N * log2(count_i / N)
			end
			return -sum
		end

		args = table.concat(args, " ")
		local isFile = pCsi.xfs.exists(args)
		local file = isFile and pCsi.xfs.read(args) or nil
		local toreturn = "-- Shannon's Entropy --\n"
		--toreturn..="- 0 represents no randomness (i.e. all the bytes in the data have the same value) whereas 8, the maximum, represents a completely random string.\n- Standard English text usually falls somewhere between 3.5 and 5.\n- Properly encrypted or compressed data of a reasonable length should have an entropy of over 7.5.\nThe following results show the entropy of chunks of the input data. Chunks with particularly high entropy could suggest encrypted or compressed sections.\n"
		local se = shannonEntropy(isFile and file or args)
		toreturn ..= (isFile and "File" or "Text") .. "'s Shannon's Entropy: " .. se .. "\n"
		local progressbar = essentials.Output:ProgressBar((se / 8) * 100, 25, false, true)
		toreturn ..= progressbar .. "\n"
		toreturn ..= "English text: " .. tostring(se > 3.5 and se < 5) .. "\n"
		toreturn ..= "Encrypted/compressed: " .. tostring(se > 7.5) .. "\n"
		toreturn ..= "\n"
		toreturn ..= "-- Password Strength --\n"
		local pe = passwordEntropy(isFile and file or args)
		toreturn ..= (isFile and "File" or "Text") .. "'s Password Strength: " .. pe .. "\n"
		return toreturn
	end,
}

return cmd
