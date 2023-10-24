---@type table<string, module>
local modules = {}
if script.active_mods["AFK_players"] then
	modules.AFK_players = require("__AFK_players__/scenarios/AFK_players/AFK_players")
else
	modules.AFK_players = require("AFK_players")
end

local event_handler
if script.active_mods["zk-lib"] then
	-- Same as Factorio "event_handler", but slightly better performance
	event_handler = require("__zk-lib__/static-libs/lualibs/event_handler_vZO.lua")
else
	event_handler = require("event_handler")
end

event_handler.add_libraries(modules)


-- Auto adds remote access for rcon and for other mods/scenarios via zk-lib
if script.active_mods["zk-lib"] then
	local is_ok, remote_interface_util = pcall(require, "__zk-lib__/static-libs/lualibs/control_stage/remote-interface-util")
	if is_ok and remote_interface_util.expose_global_data then
		remote_interface_util.expose_global_data()
	end
	local is_ok, rcon_util = pcall(require, "__zk-lib__/static-libs/lualibs/control_stage/rcon-util")
	if is_ok and rcon_util.expose_global_data then
		rcon_util.expose_global_data()
	end
end


-- This is a part of "gvv", "Lua API global Variable Viewer" mod. https://mods.factorio.com/mod/gvv
-- It makes possible gvv mod to read sandboxed variables in the map or other mod if following code is inserted at the end of empty line of "control.lua" of each.
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
