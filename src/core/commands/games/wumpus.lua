local cmd = {
	name = script.Name,
	desc = [[Execute HTTP requests like GET, POST, and also PING, displays the output in requested content type]],
	usage = "$ http post httpbin.org/post application/json {hello: 'world'}\n      $ http ping google.com",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		math.randomseed(os.time())

		local dodecahedron_graph = {
			{ 2, 5, 20 },
			{ 1, 3, 18 },
			{ 2, 4, 16 },
			{ 3, 5, 14 },
			{ 1, 4, 6 },
			{ 5, 7, 13 },
			{ 6, 8, 20 },
			{ 7, 9, 12 },
			{ 8, 10, 19 },
			{ 9, 11, 17 },
			{ 10, 12, 15 },
			{ 8, 11, 13 },
			{ 6, 12, 14 },
			{ 4, 13, 15 },
			{ 11, 14, 16 },
			{ 3, 15, 17 },
			{ 10, 16, 18 },
			{ 2, 17, 19 },
			{ 9, 18, 20 },
			{ 1, 7, 19 },
		}

        local io = pCsi.io

		local function print_s(t)
			local s, v
			if type(t) == "table" then
				s = ""
				for _, v in pairs(t) do
					s = s .. v .. " "
				end
			elseif type(t) == "number" then
				s = tostring(t)
			end
			return s
		end

		local function rand_shuffle(old_list)
			local list = {}
			for i, v in ipairs(old_list) do
				list[i] = v
			end
			local n = #list
			while n > 1 do
				local k = math.random(n)
				if k ~= n then
					list[n], list[k] = list[k], list[n]
				end
				n = n - 1
			end
			return list
		end

		local function get_user_input_tokens()
			io.write("> ")
			local str = io.read()
            io.write(str)
			local t = {}
			for v in str:gmatch("%S+") do
				table.insert(t, v)
			end
			return t
		end

		local function new_game(room_graph)
			local game = {}
			game.rooms = room_graph
			local max_rooms = #room_graph
			local room_candidates = {}
			for i = 1, max_rooms do
				room_candidates[i] = i
			end
			room_candidates = rand_shuffle(room_candidates)
			game.player_room = room_candidates[1]
			game.wumpus_room = room_candidates[2]
			game.pit_room = { room_candidates[3], room_candidates[4] }
			game.bat_room = { room_candidates[5], room_candidates[6] }
			return game
		end

		local function is_in_room(room_type, number)
			if type(room_type) == "table" then
				local v
				for _, v in ipairs(room_type) do
					if number == v then
						return true
					end
				end
				return false
			end
			return room_type == number
		end

		local function describe_room(game, room_index)
			local v
			local room_exits = game.rooms[room_index]
			io.write("You are now in room " .. room_index .. "\n")
			for _, v in ipairs(room_exits) do
				if is_in_room(game.wumpus_room, v) then
					io.write("You can smell a wumpus.\n")
				elseif is_in_room(game.pit_room, v) then
					io.write("You can feel a draft.\n")
				elseif is_in_room(game.bat_room, v) then
					io.write("You can hear some bats.\n")
				end
			end
			io.write("You can exit to rooms ")
			local draw_comma = false
			for _, v in ipairs(room_exits) do
				if draw_comma then
					io.write(", ")
				else
					draw_comma = true
				end
				io.write(v)
			end
			io.write("\n")
		end

		local function room_has_exit(room, exit)
			local e = tonumber(exit)
			for _, v in ipairs(room) do
				if e == v then
					return true
				end
			end
			return false
		end

		local function new_room_for_wumpus(game)
			local room_exits = game.rooms[game.wumpus_room]
			local exit_candidates = {}
			local i, v
			for i, v in ipairs(room_exits) do
				exit_candidates[i] = v
			end
			exit_candidates = rand_shuffle(exit_candidates)
			if exit_candidates[1] == game.pit_room then
				return exit_candidates[2]
			end
			return exit_candidates[1]
		end

		local function new_room_for_player(game)
			local max_rooms = #game.rooms
			local room_candidates = {}
			for i = 1, max_rooms do
				if not is_in_room(game.bat_room, i) then
					table.insert(room_candidates, i)
				end
			end
			room_candidates = rand_shuffle(room_candidates)
			return room_candidates[1]
		end

		local function move_player_to_room(game, move_to)
			if is_in_room(game.bat_room, move_to) then
				move_to = new_room_for_player(game)
				io.write("That bats grabbed you and dropped you in room ")
				io.write(move_to)
				io.write("!\n")
			end
			game.player_room = move_to
			if is_in_room(game.wumpus_room, game.player_room) then
				io.write("You were attacked by the wumpus.\nGame over.\n")
				return false
			elseif is_in_room(game.pit_room, game.player_room) then
				io.write("You fell into a bottomless pit.\nGame over.\n")
				return false
			end
			describe_room(game, game.player_room)
			return true
		end

		local function game_move_command(game, userline)
			local move_to = tonumber(userline[2])
			if not room_has_exit(game.rooms[game.player_room], move_to) then
				io.write("You didn't move.\n")
				return true
			end
			return move_player_to_room(game, move_to)
		end

		local function game_shoot_command(game, userline)
			local shoot_to = tonumber(userline[2])
			if not room_has_exit(game.rooms[game.player_room], shoot_to) then
				io.write("You didn't shoot.\n")
			else
				if shoot_to == game.wumpus_room then
					io.write("You killed the wumpus!\nGame over.\n")
					return false
				else
					io.write("You shoot an arrow and miss.\n")
					game.wumpus_room = new_room_for_wumpus(game)
					if game.player_room == game.wumpus_room then
						io.write("You were attacked by the wumpus.\nGame over.\n")
						return false
					else
						io.write("The wumpus moved to a new room.\n")
					end
				end
			end
			return true
		end

		local function game_quit_command()
			return false
		end

		local function game_cheat_command(game)
			io.write("game.player_room = " .. print_s(game.player_room) .. "\n")
			io.write("game.wumpus_room = " .. print_s(game.wumpus_room) .. "\n")
			io.write("game.pit_room = " .. print_s(game.pit_room) .. "\n")
			io.write("game.bat_room = " .. print_s(game.bat_room) .. "\n")
			return true
		end

		local function game_help_command()
			io.write([==[Welcome to Hunt the Wumpus. 

The Wumpus lives in a cave of twenty rooms, with each room having three exits
connecting it to other rooms in the cavern. The game has the following hazards
for intrepid adventurers to wind their way through:

  Pits   -- The game is over if you fall into one of the bottomless pits.

  Bats   -- These bats are super strong, and will grab you and move you to
            another room in the cave. That could be dangerous, because they
            might drop you into a bottomless pit, or onto the Wumpus.
  
  Wumpus -- Don't walk into the room with the Wumpus, as he'll eat you.

The point of the game is to kill the Wumpus, and you'll have to do that by
figuring out which room he's in from the clues you're given, and then shooting
an arrow into that room. Use these commands to play:

  Move (or go) # -- to move to the next room
  Shoot #        -- to shoot an arrow into the next room
  Help           -- this message
  Quit           -- to leave the game
]==])
			return true
		end

		local game_state_command_table = {
			{ { "m", "move", "go" }, game_move_command },
			{ { "s", "shoot" }, game_shoot_command },
			{ { "cheat" }, game_cheat_command },
			{ { "exit", "quit" }, game_quit_command },
			{ { "help" }, game_help_command },
		}

		local function find_command(com_name)
			local c = com_name:lower()
			local v, w
			for _, v in ipairs(game_state_command_table) do
				for _, w in ipairs(v[1]) do
					if w == c then
						return v[2]
					end
				end
			end
		end

		local function state_game()
			local game = new_game(dodecahedron_graph)
			describe_room(game, game.player_room)
			local running = true
			while running do
				local userline = get_user_input_tokens()
				local comm = find_command(userline[1])
				if comm then
					running = comm(game, userline)
				else
					io.write("?\n")
				end
			end
			return "init"
		end

		local function state_menu()
			local newstate = false
			while not newstate do
				io.write("Start, Help, or Quit?\n")
				local userline = get_user_input_tokens()
				if userline[1] == "help" then
					game_help_command()
				elseif userline[1] == "quit" then
					newstate = "quit"
				elseif userline[1] == "start" then
					io.write("Starting a new game.\n\n")
					newstate = "game"
				else
					io.write("?\n")
				end
			end
			return newstate
		end

		local function state_init()
			io.write("\n== Hunt the Wumpus ==\n\n")
			io.write("Please pick an option:\n")
			return "menu"
		end

		local state_machine_table = {
			init = state_init,
			menu = state_menu,
			game = state_game,
		}

		local function run_main_state_machine()
			local state = "init"
			while type(state_machine_table[state]) == "function" do
				state = state_machine_table[state]()
			end
		end

		run_main_state_machine()
		io.write("\n")
	end,
}

return cmd
