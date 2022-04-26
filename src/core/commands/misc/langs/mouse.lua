local prog = nil
local cmd = {
	name = script.Name,
	desc = [[Executes the Mouse programming language instructions and displays the output]],
	usage = [[$ mouse ]],
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		local min, max, sub, char, len = math.min, math.max, utf8.sub, utf8.char, utf8.len
		local block = char(0x2588)
		
		local line = ""
		
		-- vm
		
		local CONST = {
		  [true] = 1,
		  [false] = 0
		}
		
		local STACK_SIZE = 1024
		local MEMORY = {n = 0}
		local E_STACK = {n = 0}
		local D_STACK = {n = 0}
		local CHAR, POS = '', 0
		local source, offset, tracing = 0, 0, 0
		
		local function err(n)
		  D_STACK.n = 0
		end
		
		local function push(value)
		  if D_STACK.n < STACK_SIZE then
			D_STACK.n = D_STACK.n + 1
			D_STACK[D_STACK.n] = value
		  else
			err(2)
		  end
		end
		
		local function pop()
		  if D_STACK.n >= 0 then
			D_STACK.n = D_STACK.n - 1
			return D_STACK[D_STACK.n + 1]
		  else
			err(3)
		  end
		end
		
		local function getChar()
		  if POS < #line then
			POS = POS + 1
			CHAR = sub(line, POS, POS)
		  else
			err(1)
		  end
		end
		
		local function round(n)
			return math.floor(n + 0.5)
		  end
	
		local functions = {
		  ['2x'] = function()
			push(pop()^2)
		end,
		  ['4th'] = function()push(pop()^4)end,
		  ['4thrt'] = function()push(math.sqrt(math.sqrt(pop())))end,
		  ['10x'] = function()push(pop()^10)end,
		  ['abs'] = function()push(math.abs(pop()))end,
		}
		
		local opcodes = {
		  ['_'] = function()push(-pop())end,
		  ['+'] = function()push(pop()+pop())end,
		  ['-'] = function()a=pop()push(pop()-a)end,
		  ['*'] = function()push(pop()*pop())end,
		  ['/'] = function()
			a = pop()
		  if a ~= 0 then
			push(pop() / a)
		  else
			err(4)
		  end end,
		  ['\\'] = function()a = pop()
		  if a ~= 0 then
			push(pop() % a)
		  else
			err(5)
		  end end,
		  ['?'] = function()end,
		  ['!'] = function()end,
		  ['"'] = function()
			repeat
			getChar()
			if CHAR == '!' then
			  output = output .. '\n'
			elseif CHAR ~= '"' then
			  output = output .. char(CHAR)
			end
		  until CHAR == '"'
		end,
		  [':'] = function()a = pop() MEMORY[round(a)] = pop end,
		  ['.'] = function()push(MEMORY[round(pop())])end,
		  ['<'] = function()a = pop push(CONST[pop() < a])end,
		  ['='] = function()push(CONST[pop() < pop()])end,
		  ['>'] = function()a = pop push(CONST[pop() > a])end,
		  ['['] = function()end,
		  ['|'] = function()skip("[","]")end,
		  ['('] = function()push(loop)end,
		  [')'] = function()POS=E_STACK[E_STACK.n].POS end,
		  ['^'] = function()if pop() <= 0 then pop() skip("(",")") end end,
		  ['#'] = function()end,
		  ['@'] = function()end,
		  ['%'] = function()end,
		  [';'] = function()pop()end,
		  ['\''] = function()getChar() push(tonumber(CHAR))end,
		  ['{'] = function()tracing = 1 end,
		  ['}'] = function()tracing = 0 end,
		  ['&'] = function()end
		  
		}
				
		local function interpret()
		  offset, POS = 0, 0
		  local chn = 0
		  while POS < #line do
			getChar()
			if tonumber(CHAR) then
			local temp = line:sub(POS):match('(%d*%.?%d+)')
			  POS = POS + #temp
			  push(tonumber(temp))
			else
			  chn = CHAR:byte()
			  if chn >= 65 and chn <= 90 then
				push(chn - 65)
			  elseif chn >= 97 and chn <= 122 then
				push(chn - 97 + offset)
			  else
				if opcodes[CHAR] then
				  opcodes[CHAR]()
				end
			  end
			end
		  end
		end
		
		interpret()
		print(pop(D_STACK))
	end,
}

return cmd
