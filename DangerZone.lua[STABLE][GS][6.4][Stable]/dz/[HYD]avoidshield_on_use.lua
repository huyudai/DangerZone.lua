local uix = require 'gamesense/uix'
local pairs, client_update_player_list, plist_set, plist_get, enabled = pairs, client.update_player_list, plist.set, plist.get

local ignore_shield = function()
    local enemies = entity.get_players(true)

    client_update_player_list()

    for _, idx in pairs(enemies) do
        local weapon = entity.get_player_weapon(idx)
        local holding_shield = (bit.band(entity.get_prop(weapon, 'm_iItemDefinitionIndex'), 0xFFFF) == 37) -- check if enemy is holding shield
        plist_set(idx, 'Add to whitelist', holding_shield)
    end
end

local draw_ind = function(player)
    return plist_get(player, 'Add to whitelist') == true
end

do
    enabled = uix.new_checkbox('Rage', 'Other', 'Ignore target(s) with shield')
    enabled:on('net_update_end', ignore_shield)
    client.register_esp_flag('IGNORED', 255, 60, 60, draw_ind)
end