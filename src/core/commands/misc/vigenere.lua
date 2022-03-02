local cmd = {
	name = script.Name,
	desc = [[Study current working directory of files and produce a mixed output]],
	displayOutput = true,
	usage = [[$ markovchain true 2500]],
	fn = function(plr, pCsi, essentials, args)
		-- Vigenere.lua
		-- Raymas
		--
		-- decryptor for vigenere method

		-- paramters
		local params = args
        local print = pCsi.io.write
		-- LANGUAGE FREQUENCIES
		local alphabet = "abcdefghijklmnopqrstuvwxyz"
		local english = "eariotnslcudpmhgbfywkvxzjq"
		local french = "eaisnrtoludcmpégbvhfqyxjèàkwzêçôâîûùïüëö"
		local spanish = "eaosnrildtucmpbhqyvgÓÍfjzÁÉÑxÚkwÜ"

		-- 1. Cracking key length
		local function keylengthguess(text, language, maxkeylength, verbose)
			if maxkeylength == nil then
				maxkeylength = 20
			end
			if verbose == nil then
				verbose = false
			end

			local results = {}
			local minMax = 0

            -- N/A usefull functions
		local function compare(a, b)
			return a[1] < b[1]
		end

		local function printDict(d)
			for k, v in pairs(d) do
				print(k, v)
			end
		end

		local function getKeysSortedByValue(tbl, sortFunction)
			local keys = {}
			for key in pairs(tbl) do
				table.insert(keys, key)
			end
			table.sort(keys, function(a, b)
				return sortFunction(tbl[a], tbl[b])
			end)
			return keys
		end

		local function letterValue(letter)
			return (letter:byte() - ("a"):byte())
		end

		local function onePadding(int)
			return (int > 0) and int or 1
		end

		local function isInList(key, list)
			for _, v in pairs(list) do
				if v == key then
					return true
				end
			end
			return false
		end

		local function getIndex(key, list)
			for t, v in pairs(list) do
				if v == key then
					return t
				end
			end
			return nil
		end

		local function split(s, delimiter)
			local result = {}
			for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
				table.insert(result, match)
			end
			return result
		end

			for keylength = 1, maxkeylength, 1 do
				-- count every character in text
				local charmap = {}
				local keyindex = 0
				for i = 1, #text do
					local c = text:lower():sub(i, i)
					if language:find(c) then
						if keyindex % keylength == 0 then
							if charmap[c] then
								charmap[c] = charmap[c] + 1
							else
								charmap[c] = 1
							end
						end
						keyindex = keyindex + 1
					end
				end
				-- end of key search
				local sortedOccurences = getKeysSortedByValue(charmap, function(a, b)
					return a < b
				end)
				local occurencesOfMinLetter = charmap[sortedOccurences[1]]
				local occurencesOfMaxLetter = charmap[sortedOccurences[#sortedOccurences]]
				local minProb = occurencesOfMinLetter / keyindex * keylength * 100
				local maxProb = occurencesOfMaxLetter / keyindex * keylength * 100
				-- the probability of key length is greater than previuously : updating results
				if (maxProb - minProb) > minMax then
					minMax = maxProb - minProb
					results["prob"] = minMax
					results["keylength"] = keylength
					results["keyindex"] = keyindex
					results["charmap"] = charmap
				end
			end
			return results
		end

		-- 2. Cracking key
		local function guessingKey(text, language, keylength, verbose)
			if verbose == nil then
				verbose = false
			end
			local key = ""

			for index = 1, keylength, 1 do
				local charmap = {}
				local keyindex = 1
				for i = 1, #text do
					local c = text:lower():sub(i, i)
					if language:find(c) then
						if keyindex == index then
							if charmap[c] then
								charmap[c] = charmap[c] + 1
							else
								charmap[c] = 1
							end
						end
						keyindex = onePadding((keyindex + 1) % (keylength + 1))
					end
				end
				-- guessing statistically the key
				local sortedOccurences = getKeysSortedByValue(charmap, function(a, b)
					return a < b
				end)
				if #sortedOccurences ~= 0 then
					local k = language:sub(1, 1)
					local maxLetter = string.char(
						((letterValue(sortedOccurences[#sortedOccurences]) - letterValue(k)) % 26) + string.byte("a")
					)
					key = key .. maxLetter
				end
			end
			return key
		end

		-- 3. Decrypt
		local function decrypt(text, key, language)
			local decrypted = ""
			local keyindex = 1
			key = key:lower()
			for i = 1, #text, 1 do
				local c = text:lower():sub(i, i)
				if language:find(c) then
					local k = key:sub(keyindex, keyindex)
					decrypted = decrypted
						.. string.char(((26 + letterValue(c) - letterValue(k)) % 26) + string.byte("a"))
					keyindex = onePadding((keyindex + 1) % (#key + 1))
				else
					decrypted = decrypted .. c
				end
			end
			return decrypted
		end

		-- 4. Encrypt
		local function encrypt(text, key, language)
			local crypted = ""
			local keyindex = 1
			key = key:lower()
			for i = 1, #text, 1 do
				local c = text:lower():sub(i, i)
				if language:find(c) then
					local k = key:sub(keyindex, keyindex)
					crypted = crypted .. string.char(((26 + letterValue(c) + letterValue(k)) % 26) + string.byte("a"))
					keyindex = onePadding((keyindex + 1) % (#key + 1))
				else
					crypted = crypted .. c
				end
			end
			return crypted
		end

		

		-- Help
		local function printHelp()
            local buffer = {}
            local print = function(...) table.insert(buffer, ...) end
			print("Usage : lua vigenere.lua [MODE] [OPTIONS]")
			print("")
			print("# MODES: #")
			print("\te\tencrypt by entering a key, and a text")
			print("\td\tdecrypt by entering a key, and a text")
			print("\tc\tcrack")
			print("#-------------------------------------------#")
			print("\te parameter : lua vigenere.lua e [OPTIONS --raw | OPTIONS --file] key")
			print("")
			print("\t\t--raw 'text in console'")
			print("\t\t--file [path to file]")
			print("#-------------------------------------------#")
			print("\td parameter : lua vigenere.lua [OPTIONS --raw | OPTIONS --file] key")
			print("")
			print("\t\t--raw 'text in console'")
			print("\t\t--file [path to file]")
			print("#-------------------------------------------#")
			print("\tc parameter : lua vigenere.lua [(OPTIONS --raw | OPTIONS --file) && --maxkeylength keylength]")
			print("\t\t--raw 'text in console'")
			print("\t\t--file [path to file]")
			print("\t\t--maxkeylength [integer keylength] : this parameter is mandatory")
			print(
				"\t\t--trylength [lower:upper] : this parameter is mandatory and should not be used with maxkeylength"
			)
			print("#-------------------------------------------#")
            print(table.concat(buffer,"\n"))
		end

		local function cmdEncode(cli)
			local string = nil
			local key = nil
			local language = english

			if isInList("--file", cli) then
				local path = getIndex("--file", cli) + 1
				if cli[path] ~= nil then
					file = pCsi.xfs.read(cli[path])
					string = file
				else
					print("Error argument : incorrect path")
					return
				end
			elseif isInList("--raw", cli) then
				local text = getIndex("--raw", cli) + 1
				if cli[text] ~= nil then
					string = cli[text]
				else
					print("Error argument : incorrect text")
					return
				end
			end
			key = cli[#cli]
			print(encrypt(string, key, english))
		end

		local function cmdDecode(cli)
			local string = nil
			local key = nil
			local language = english

			if isInList("--file", cli) then
				local path = getIndex("--file", cli) + 1
				if cli[path] ~= nil then
					file = pCsi.xfs.read(cli[path])
					string = file
				else
					print("Error argument : incorrect path")
					return
				end
			elseif isInList("--raw", cli) then
				local text = getIndex("--raw", cli) + 1
				if cli[text] ~= nil then
					string = cli[text]
				else
					print("Error argument : incorrect text")
					return
				end
			end
			key = cli[#cli]
			print(decrypt(string, key, language))
		end

		local function cmdCrack(cli)
			local string = nil
			local keylength = nil
			local lower = nil
			local upper = nil
			local language = english

			if isInList("--file", cli) then
				local path = getIndex("--file", cli) + 1
				if cli[path] ~= nil then
					file = pCsi.xfs.read(cli[path])
					string = file
				else
					print("Error argument : incorrect path")
					return
				end
			elseif isInList("--raw", cli) then
				local text = getIndex("--raw", cli) + 1
				if cli[text] ~= nil then
					string = cli[text]
				else
					print("Error argument : incorrect text")
					return
				end
			end

			if isInList("--maxkeylength", cli) then
				local mkl = getIndex("--maxkeylength", cli) + 1
				if cli[mkl] ~= nil then
					keylength = cli[mkl]
				end
			elseif isInList("--trylength", cli) then
				local tl = getIndex("--trylength", cli) + 1
				if cli[tl] ~= nil then
					lower, upper = cli[tl]:match("([^,]+):([^,]+)")
				end
			end

			if keylength then
				local keyguess = guessingKey(string, language, keylength)
				print("Key guess is : " .. keyguess)
				print(decrypt(string, keyguess, language))
			elseif lower and upper then
				for try = tonumber(lower), tonumber(upper), 1 do
					local keyguess = guessingKey(string, language, try)
					print("[" .. try .. "] Key guess is : " .. keyguess)
				end
			else
				local len = keylengthguess(string, english)
				print("Length guess is : " .. len.keylength)
				local pseudoKey = guessingKey(string, english, len.keylength)
				print("Key guess is : " .. pseudoKey)
				print(decrypt(string, pseudoKey, language))
			end
		end

		-- Main Function
		local function main(args)
			if #args > 0 then
				if isInList("e", args) then
					cmdEncode(args)
				elseif isInList("d", args) then
					cmdDecode(args)
				elseif isInList("c", args) then
					cmdCrack(args)
				elseif isInList("-h", args) or isInList("--help", args) then
					printHelp()
				else
					print("No command found. Use --help for list and usages")
				end
			else
				printHelp()
			end
		end

		

		main(params)
	end,
}

return cmd
