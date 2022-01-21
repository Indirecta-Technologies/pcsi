local cmd = {
	name = script.Name,
	desc = [[WIP]],
	usage = [[]], --TO REDO
	displayOutput = false,
	fn = function(pCsi, essentials, args)
    local board = {
      {0,0,0,0},
      {0,0,0,0},
      {0,0,0,0},
      {0,0,0,0},
    }
    
    local function show_board(board)
      local r, c
    
      essentials.Console.info("  UUUU")
      essentials.Console.info(" +----+")
      local buffer = ""
      for r=1,4 do
        buffer ..=("L:")
        for c=1,4 do
          if board[r][c] == 0 then
            buffer ..=('.')
          else
            buffer ..=(string.char(string.byte('a') - 1 + board[r][c]))
          end
        end
        buffer ..=("\n")
      end
      buffer ..=(" +----+")
      buffer ..=("  DDDD")
      buffer ..= "\n"
      essentials.Console.info(buffer)
    end
    
    local function add_blocks_at_random(number)
      local function add_block_at_random()
        local r = math.random(4)
        local c = math.random(4)
    
        while board[r][c] ~= 0 do
          r = math.random(4)
          c = math.random(4)
        end
    
        board[r][c] = 1
      end
    
      local c
    
      for c=1,number do
        add_block_at_random()
      end
    end
    
    local function can_make_a_move()
      local r, c
    
      -- Game over once a 'z' appears
      for r=1,4 do
        for c=1,4 do
          if board[r][c] == 26 then
            return false
          end
        end
      end
    
      -- Are there any free spaces?
      for r=1,4 do
        for c=1,4 do
          if board[r][c] == 0 then
            return true
          end
        end
      end
      
      -- Could non empty spaces be merged?
      for r=1,3 do
        for c=1,3 do
          if board[r][c] ~= 0 then
            if board[r][c] == board[r][c+1] or board[r][c] == board[r+1][c] then
              return true
            end
          end
        end
      end
    
      for c=1,3 do
        if board[4][c] ~= 0 then
          if board[4][c] == board[4][c+1] then
            return true
          end
        end
      end
    
      -- Well that would be a no then
      return false
    end
    
    local quit = false

    local function get_user_move()
      local here
    
      waiting_for_input = true
      
      essentials.Console.info("Enter a direction to move: U, D, L or R")

      local here = ""

      args = pCsi.io.read()
      essentials.Console.info(" "..args)
        args = string.split(args, " ")[1]
        if args == 'U' or args == 'u' then
             args = 'u'
            elseif args == 'D' or args == 'd' then
              args = 'd'
            elseif args == 'L' or args == 'l' then
              args = 'l'
            elseif args == 'R' or args == 'r' then
              args = 'r'
            elseif args == "quit" or args == "q" then
              waiting_for_input = false
              quit = true
              return
            else
              waiting_for_input = true
              essentials.Console.info("That was not a valid instruction")
            end
          here = args
    

    
      return here  
    end
    
    local function move_board(here)
      local function check(r, c, dr, dc)
        local moved = 0
    
        if board[r][c] == 0 then
          if board[r+dr][c+dc] ~= 0 then
            board[r][c] = board[r+dr][c+dc]
            board[r+dr][c+dc] = 0
            moved = moved + 1
          end
        elseif board[r][c] == board[r+dr][c+dc] then
          board[r][c] = board[r][c] + 1
          board[r+dr][c+dc] = 0
          moved = moved + 1
        end
        
        return moved
      end
    
      local function find(row_from,row_to,row_step,column_from,column_to,column_step,row_offset,column_offset)
        local r, c
    
        local x = 0
    
        for r=row_from,row_to,row_step do
          for c=column_from,column_to,column_step do
            x = x + check(r, c, row_offset, column_offset)
          end
        end
      
        return x > 0
      end
    
      if here == 'l' then
        return find(1,4,1,1,3,1,0,1) and here or 'x'
      elseif here == 'r' then
        return find(1,4,1,4,2,-1,0,-1) and here or 'x'
      elseif here == 'u' then
        return find(1,3,1,1,4,1,1,0) and here or 'x'
      else
        return find(4,2,-1,1,4,1,-1,0) and here or 'x'
      end
    end
    
    local function add_new_block(here)
      local function pick_one(t)
        local x = math.random(#t)
        return t[x]
      end
    
      local function add_to_column(c)
        local r
        local v = {}
    
        for r=1,4 do
          if board[r][c] == 0 then
            v[#v+1] = r
          end
        end
    
        board[pick_one(v)][c] = 1
      end
    
      local function add_to_row(r)
        local c
        local v = {}
    
        for c=1,4 do
          if board[r][c] == 0 then
            v[#v+1] = c
          end
        end
    
        board[r][pick_one(v)] = 1
      end
    
      if here == 'l' then
        add_to_column(4)
      elseif here == 'r' then
        add_to_column(1)
      elseif here == 'u' then
        add_to_row(4)
      else
        add_to_row(1)
      end
    end
    
    local function score_game(board)
      -- Better scoring values required
      local scores = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26}
    
      local r, c
      local score = 0
      local max = 0
    
      for r=1,4 do
        for c=1,4 do
          score = score + scores[board[r][c]]
          if max < board[r][c] then
            max = board[r][c]
          end
        end
      end
    
      print("Final score was " .. score .. " The highest letter was '" .. string.char(string.byte('a') + max - 1) .. "'")
    end
    
    math.randomseed( os.time() )
    add_blocks_at_random(2)
    
    while can_make_a_move() do
      show_board(board)
      here = get_user_move()
      if quit then break end
      if move_board(here) == 'x' then
        print("Unable to move in that direction (" .. here .. ")")
      else
        add_new_block(here)
      end
    end
    
    show_board(board)
    score_game(board)
	
	end,
}

return cmd

