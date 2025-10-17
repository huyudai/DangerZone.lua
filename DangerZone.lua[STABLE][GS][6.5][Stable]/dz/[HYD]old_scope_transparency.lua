local enable = ui.new_checkbox("LUA", "B", "Return old scope transparency")
local local_player_transparency = ui.reference("Visuals","Colored models","Local player transparency")

local function run_command()
    local lp = entity.get_local_player()
    local m_bIsScoped = entity.get_prop(lp, "m_bIsScoped")
	local weapon = entity.get_player_weapon(entity.get_local_player())
	
	if m_bIsScoped == 1 then
		ui.set(local_player_transparency,{"scoped","grenade"})
	elseif m_bIsScoped == 0 then
		ui.set(local_player_transparency,{})
	end
	
	if entity.get_classname(weapon) == "CHEGrenade" or entity.get_classname(weapon) == "CIncendiaryGrenade" or entity.get_classname(weapon) == "CSmokeGrenade" or entity.get_classname(weapon) == "CMolotovGrenade" then
		ui.set(local_player_transparency,{"scoped","grenade"})
	end
end

local function callback_handling()
local handle = ui.get(enable) and client.set_event_callback or client.unset_event_callback
handle("run_command",run_command)
end
ui.set_callback(enable,callback_handling)