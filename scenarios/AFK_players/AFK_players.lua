local M = {}


-- TODO: add more settings
-- TODO: add commands


--#region Global data
local __mod_data
--#endregion


--#region Constants
local MIN_AFK_TIME_IN_TICKS = 60 * 10
local floor = math.floor
local ORANGE_COLOR = {254, 80, 0}
--#endregion


remote.add_interface("AFK_players", {
	getSource = function()
		local mod_name = script.mod_name
		print_to_rcon(mod_name) -- Returns "level" if it's a scenario, otherwise "AFK_players" as a mod.
		return mod_name
	end
})


--TODO: fix text for crashes
function M.on_player_joined_game(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	__mod_data.active_players[player_index] = player
end

function M.on_player_left_game(event)
	local player_index = event.player_index
	-- local player = game.get_player(player_index)
	-- if not (player and player.valid) then return end

	__mod_data.active_players[player_index]   = nil
	__mod_data.AFK_players_data[player_index] = nil
end


local __text_data = {
	surface = nil,
	color = ORANGE_COLOR,
	scale = 4,
	target = {entity = nil, offset = {0, -5.8}},
	text = {"AFK_players.AFK"},
	visible = true,
	alignment = "center",
	only_in_alt_mode = true
}
local __time_text = {"AFK_players.short_time", 0, 10} -- minutes, seconds
local __time_text_data = {
	surface = nil,
	color = ORANGE_COLOR,
	scale = 3,
	target = {entity = nil, offset = {0, -4}},
	text = __time_text,
	visible = true,
	alignment = "center",
	only_in_alt_mode = true
}
---@param player LuaPlayer
M.create_AFK_text = function(player)
	local player_index = player.index
	__mod_data.active_players[player_index] = nil
	if __mod_data.AFK_players_data[player_index] then return end

	local character = player.character
	local surface   = character.surface

	__time_text_data.target.entity  = character
	__text_data.target.entity       = character
	__time_text_data.surface = surface
	__text_data.surface      = surface

	local afk_time = player.afk_time
	local ticks_in_1_second = 60 * game.speed
	local ticks_in_1_minute = 60 * ticks_in_1_second
	local mins = floor(afk_time / ticks_in_1_minute)
	local seconds = floor((afk_time - (mins * ticks_in_1_minute)) / ticks_in_1_second)
	__time_text[2] = mins
	__time_text[3] = seconds

	local id1 = rendering.draw_text(__text_data).id
	local id2 = rendering.draw_text(__time_text_data).id
	__mod_data.AFK_players_data[player_index] = {
		player = player,
		ID1 = id1,
		ID2 = id2
	}
end

---@param player LuaPlayer
local function update_AFK_text(player)
	local player_index = player.index
	local character    = player.character
	local surface      = character.surface

	__time_text_data.target.entity = character
	__time_text_data.surface = surface

	local afk_time = player.afk_time
	local ticks_in_1_second = 60 * game.speed
	local ticks_in_1_minute = 60 * ticks_in_1_second
	local mins = floor(afk_time / ticks_in_1_minute)
	local seconds = floor((afk_time - (mins * ticks_in_1_minute)) / ticks_in_1_second)
	__time_text[2] = mins
	__time_text[3] = seconds

	local id = __mod_data.AFK_players_data[player_index].ID2
	rendering.get_object_by_id(id).text = __time_text
end


local function check_active_players()
	local create_AFK_text = M.create_AFK_text
	for player_index, player in pairs(__mod_data.active_players) do
		if player.valid == false then
			__mod_data.active_players[player_index] = nil
		else
			local character = player.character
			if character and character.valid and
				player.afk_time > MIN_AFK_TIME_IN_TICKS
			then
				create_AFK_text(player)
			end
		end
	end
end


local function check_AFK_players()
	local AFK_players_data = __mod_data.AFK_players_data
	local get_object_by_id = rendering.get_object_by_id
	for player_index, player_data in pairs(AFK_players_data) do
		local player = player_data.player
		if not (player.valid and player.afk_time >= MIN_AFK_TIME_IN_TICKS) then
			local rendered_object = get_object_by_id(player_data.ID1)
			if rendered_object and rendered_object.valid then
				rendered_object.destroy()
			end
			rendered_object = get_object_by_id(player_data.ID2)
			if rendered_object and rendered_object.valid then
				rendered_object.destroy()
			end
			__mod_data.active_players[player_index] = player
			AFK_players_data[player_index] = nil
		else
			local character = player.character
			if character and character.valid and get_object_by_id(player_data.ID2).valid then
				update_AFK_text(player)
			end
		end
	end
end


local function check_AFK_characters()
	local AFK_players_data = __mod_data.AFK_players_data
	local create_AFK_text = M.create_AFK_text
	local get_object_by_id = rendering.get_object_by_id
	for _, player_data in pairs(AFK_players_data) do
		local player = player_data.player
		if player.valid and player.character and player.character.valid then
			local rendered_object = get_object_by_id(player_data.ID1)
			if rendered_object == nil or not rendered_object.valid then
				create_AFK_text(player_data.player)
			end
		end
	end
end


--#region Pre-game stage

function M.link_data()
	__mod_data = storage.AFK_players_mod_data
end

function M.update_global_data()
	storage.AFK_players_mod_data = storage.AFK_players_mod_data or {}
	__mod_data = storage.AFK_players_mod_data

	__mod_data.active_players = {}

	local get_object_by_id = rendering.get_object_by_id
	if __mod_data.AFK_players_data then
		for _, player_data in pairs(__mod_data.AFK_players_data) do
			if type(player_data.ID1) == "userdata" then
				player_data.ID1 = player_data.ID1.id
				player_data.ID2 = player_data.ID2.id
			end

			local rendered_object = get_object_by_id(player_data.ID1)
			rendered_object.destroy()
			rendered_object = get_object_by_id(player_data.ID2)
			rendered_object.destroy()
		end
	end
	__mod_data.AFK_players_data = {}

	--Perhaps, I don't need it
	for player_index, player in pairs(game.connected_players) do
		__mod_data.active_players[player_index] = player
	end

	M.link_data()
end


M.on_init = M.update_global_data
M.on_configuration_changed = M.on_configuration_changed
M.on_load = M.link_data


--#endregion


M.on_nth_tick = {
	[60] = check_AFK_players,
	[60 * 5] = check_active_players,
	[60 * 6] = check_AFK_characters
}

M.events = {
	[defines.events.on_player_joined_game] = M.on_player_joined_game,
	[defines.events.on_player_left_game] = M.on_player_left_game
}


---@param player LuaPlayer
---@return table
local function get_afk_time(player)
	local afk_time = player.afk_time
	local ticks_in_1_second = 60 * game.speed
	local ticks_in_1_minute = 60 * ticks_in_1_second
	local mins = floor(afk_time / ticks_in_1_minute)
	local seconds = floor((afk_time - (mins * ticks_in_1_minute)) / ticks_in_1_second)

	return {"AFK_players.player_afk_time", player.name, mins, seconds}
end

commands.add_command("afk-time", {"AFK_players-commands.afk-time"}, function(cmd)
	local parameter = cmd.parameter
	local player_index = cmd.player_index
	if player_index == 0 then -- server
		if cmd.parameter == nil then
			local responses = {}
			for _, player in pairs(game.connected_players) do
				if player.afk_time >= MIN_AFK_TIME_IN_TICKS then
					responses[#responses+1] = get_afk_time(player)
					responses[#responses+1] = "\n"
					if #responses >= 19 * 2 then -- TODO: FIX
						localised_print({"AFK_players.too_many_afk_players"})
						break
					end
				end
			end

			if #responses == 0 then
				table.insert(responses)
				localised_print({"AFK_players.no_one_afk"})
				return
			end

			table.insert(responses, 1, "")
			localised_print(responses)

			return
		end

		if #parameter > 32 then
			localised_print({"gui-auth-server.username-too-long"})
			return
		end

		local target = game.get_player(parameter)
		if not (target and target.valid) then
			localised_print({"player-doesnt-exist", parameter})
			return
		end

		if target.afk_time < MIN_AFK_TIME_IN_TICKS then
			localised_print({"AFK_players.player_is_active", parameter})
			return
		end

		localised_print(get_afk_time(target))

		return
	end


	local caller = game.get_player(player_index)
	if not (caller and caller.valid) then return end

	if parameter == nil then
		local responses = {}
		for _, player in pairs(game.connected_players) do
			if player.afk_time >= MIN_AFK_TIME_IN_TICKS then
				if #responses > 8 * 2 then
					caller.print({"AFK_players.too_many_afk_players"}, {255, 255, 0})
					return
				end
				responses[#responses+1] = get_afk_time(player)
				responses[#responses+1] = "\n"
			end
		end

		if #responses == 0 then
			caller.print({"AFK_players.no_one_afk"})
			return
		end

		table.insert(responses, 1, "")
		caller.print(responses)

		return
	end

	if #parameter > 32 then
		caller.print({"gui-auth-server.username-too-long"}, {255, 0, 0})
		return
	end

	local target = game.get_player(parameter)
	if not (target and target.valid) then
		caller.print({"player-doesnt-exist", parameter}, {255, 0, 0})
		return
	end

	if target.afk_time < MIN_AFK_TIME_IN_TICKS then
		caller.print({"AFK_players.player_is_active", parameter})
		return
	end

	caller.print(get_afk_time(target))
end)


return M
