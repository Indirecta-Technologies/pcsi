local prog = nil
local cmd = {
	name = script.Name,
	desc = [[Executes the Forth programming language instructions and displays the output]],
	usage = [[$ forth ]],
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		local computer = require("computer")
		local term = require("term")
		local text = require("text")
		local component = require("component")
		local interpret
		
		-- Current Word List and additional information
		local WORDS = {
		  WORDS = {isLua = true}, 
		  ["."] = {isLua = true},
		  ["+"] = {isLua = true},
		  [":"] = {isLua = true},
		  EXIT = {isLua = true},
		  IGNORECAPS = {isLua = true},
		  HALTONERR = {isLua = true}, PAGE = {isLua = true},
		  IOXINIT = {isLua = true},
		}
		
		local STACK = {n = 0} -- Stack, n is number of items in the stack
		local VER = "0a" -- Version
		local HALTONERR = true -- H.O.E. Halt on error
		local IGNORECAPS = false -- When enabled capitalizes inputs automatically
		local IDW = false -- Is defining word, best way I could think of doing this
		local CWD = ""    -- Current Word Definition, SHOULD BE BLANK WHEN IDW IS FALSE
		local CWN = ""    -- Current Word Name, SHOULD BE BLANK WHEN IDW IS FALSE
			
		
		-- Clear the screen
		WORDS.PAGE[1] = function() pCsi.io.write("\x1b[31m") end
		
		-- Halt on error
		WORDS.HALTONERR[1] = function()
		  if STACK.n > 0 then
			if STACK[STACK.n] == 1 then
				HALTONERR = true
			else
				HALTONERR = false
			end
			STACK[STACK.n] = nil
			STACK.n = STACK.n - 1
		  else
			pCsi.io.write("\x1b[31mERROR: Stack Empty\n")
			return 1 -- An error happened
		  end
		end
		
		-- Ignore Caps 
		WORDS.IGNORECAPS[1] = function()
		  if STACK.n > 0 then
			if STACK[STACK.n] == 1 then
			  IGNORECAPS = true
			else
			  IGNORECAPS = false
			end
			STACK[STACK.n] = nil
			STACK.n = STACK.n - 1
		  else
			pCsi.io.write("\x1b[31mERROR: Stack Empty\n")
			return 1 -- An error happened
		  end
		end
		
		-- Display all current words
		WORDS.WORDS[1] = function()
		  for i, word in pairs(WORDS) do
			pCsi.io.write(i.." ")
		  end
		  return 0 
		end
		
		-- Output top item in stack to terminal
		WORDS["."][1] = function()
		  if not pcall(function()
			pCsi.io.write(STACK[STACK.n])
			STACK[STACK.n] = nil
			STACK.n = STACK.n - 1
			return 0 -- No error
		  end) then
			pCsi.io.write("\x1b[31mERROR: Stack Empty\n")
			return 1 -- An error happened
		  end
		end
		
		-- Addition
		WORDS["+"][1] = function()
		  if not pcall(function()
			STACK[STACK.n-1] = STACK[STACK.n] + STACK[STACK.n-1]
			STACK[STACK.n] = nil
			STACK.n = STACK.n-1
		  end) then
			pCsi.io.write("\x1b[31mERROR: Not enough items in stack\n")
			return 1
		  end
		end
		
		-- Begin Word Definition
		WORDS[":"][1] = function(NEXTWORD)
		  IDW = true
		  CWD = ""
		  CWN = NEXTWORD
		  return 2 -- Skip the next word
		end
		
		-- Exit interpreter
		WORDS.EXIT[1] = function()
		  os.exit(0)
		end
		
		-- Interpret The Input
		local function interpret(input)
		  local splitInput = text.tokenize(input)
		
		  for wordIndex, wordText in pairs(splitInput) do
		  if not SKIPNEXT and not IDW then
			if tonumber(wordText) then
			  -- Current "word" is just a number
			  STACK[STACK.n+1] = tonumber(wordText)
			  STACK.n = STACK.n + 1
			else
			  if IGNORECAPS then wordText = wordText:upper() end
			  if WORDS[wordText] then 
				-- The Word Exists
				if WORDS[wordText].isLua then 
				  -- Function is implemented in lua
				  local EXITCODE = WORDS[wordText][1](splitInput[wordIndex+1])
				  if EXITCODE == 1 and HALTONERR then
					pCsi.io.write("\n\x1b[31mExecution stopped, error above\n")
					break
				  elseif EXITCODE == 2 then
					SKIPNEXT = true
				  end
		
				else
				  -- Function is implemented in Forth
				  interpret(WORDS[wordText][1])
				end
			  else
				-- The Word Does Not Exist
				pCsi.io.write("\x1b[31mERROR: Word Does Not Exist\n")
			  end
		  
			end
		  elseif SKIPNEXT then; SKIPNEXT = false;
		  else
			if wordText == ";" then
			  WORDS[CWN] = {}; WORDS[CWN][1] = CWD; CWD = ""; CWN = ""; IDW = false;
			else; CWD = CWD..wordText.." "; end
		  end
		  end
		end
		
		-- Actual Running
		
		--pCsi.io.write("\x1b%[2J") --clear screen
		while true do
		  if not IDW then; pCsi.io.write("> "); else; pCsi.io.io.write("COMP> "); end
		  local input = pCsi.io.io.read()
		  interpret(input)
		end
	end,
}

return cmd

