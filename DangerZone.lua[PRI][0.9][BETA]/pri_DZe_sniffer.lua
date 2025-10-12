local panorama = require("panorama library.lua")
local ui = {}
ui.group_name = "DangerZone Elite Sniffer"
ui.messagemode = menu.add_selection(ui.group_name, "SendWay", { "Only Console", "Partychat", "Teamchat" })
ui.messagemaster = menu.add_checkbox(ui.group_name, "Master Switch", true)
ui.respawnmaster = menu.add_checkbox(ui.group_name, "Respawn sniffer", true)
ui.exitmaster = menu.add_checkbox(ui.group_name, "Respawn sniffer", true)
ui.respawnmaster = menu.add_checkbox(ui.group_name, "Exit sniffer", true)
ui.paradropmaster = menu.add_checkbox(ui.group_name, "ParaDrop sniffer", true)
ui.dronedispatchmaster = menu.add_checkbox(ui.group_name, "Purchase Sniffer", true)
local function findthisguy(thisguy, tab)
    if tab == nil then return end
    for i, guy in ipairs(tab) do
        if guy == thisguy then
            return true
        end
    end
    return false
end

local playerlist = {}
local ingamestatus = false
local cachelist = {}

local deadlist = {}
local player_respawn_times = {}
local tabletitemindex = {
    [-1] = "None",
    [0] = "Knief",
    [1] = "Piston",
    [2] = "Smg",
    [3] = "Rifle",
    [4] = "Scout",
    [6] = "Armor",
    [7] = "Ammo box",
    [10] = "Smoke pack",
    [11] = "Jammer",
    [12] = "Healthshot",
    [13] = "DroneDetect Chip",
    [14] = "EndZone Chip",
    [15] = "Rich Chip",
    [16] = "Grenade pack",
    [17] = "Deagle",
    [18] = "DroneControl Chip",
    [19] = "Exojump set",
    [21] = "Shield"
}
local teammatename = ""
local teammatenoshow = true
local pLocal = nil
local localindex = 0
local localteamid = 0
local lastcssplayernumber = 0
local teammateisin = false
local purchaseguy = nil
local purchasedex = false

local function ingame()
    local money = entity_list.get_entities_by_name("CItemCash")
    return money ~= nil and #money ~= 0
end

local function partyapisay(message)
    print(message)
    if ui.messagemode:get() == 2 then
        panorama.loadstring(
            "PartyListAPI.SessionCommand('Game::Chat', 'run all xuid ' + MyPersonaAPI.GetXuid() + ' chat " ..
            message .. "');")
    elseif ui.messagemode:get() == 3 then
        engine.execute_cmd(('say "%s"'):format(message))
    end
end



local function main_exec()
    pLocal = entity_list.get_local_player()
    if pLocal == nil then return end
    localindex = pLocal:get_index()
    localteamid = pLocal:get_prop("m_nSurvivalTeam")
    if localteamid == -1 then localteamid = -2 end
    if not ui.messagemaster:get() then return end
    local players = entity_list.get_players(false)
    ingamestatus = ingame()

    if not ui.exitmaster:get() then cachelist = {} end
    if players ~= nil then
        -- local moneylist = {}
        local needupdatecssplayer = false
        if lastcssplayernumber ~= #players then
            needupdatecssplayer = true
            playerlist = {}
        end
        if needupdatecssplayer then teammateisin = false end
        for _, player in ipairs(players) do
            local playerIndex = player:get_index()
            local playername = player:get_name()

            if player:get_name() ~= "GOTV" then
                if ingamestatus and ui.respawnmaster:get() then
                    if player:is_alive() and deadlist[playername] then
                        local addstr = ""
                        if player_respawn_times[playername] then
                            addstr = "Next_Time:" ..
                                math.floor(player_respawn_times[playername])
                        end
                        partyapisay("Respawn" ..
                            string.gsub(': ' .. playername, '%s', '') .. addstr)
                        deadlist[playername] = nil
                    end
                end
                local playerteamid = player:get_prop("m_nSurvivalTeam")
                if localindex ~= playerIndex and ui.exitmaster:get() and needupdatecssplayer then
                    if playerteamid == localteamid then
                        teammatename = player:get_name()
                        teammateisin = true
                    else
                        table.insert(playerlist, player:get_name())
                    end
                end
            end
        end
        if (#cachelist ~= #playerlist or #cachelist == 0) and ui.exitmaster:get() and #playerlist ~= 0 then
            if teammateisin and teammatenoshow then
                teammatenoshow = false
                partyapisay("Your_teammate_is" .. ":" .. string.gsub(teammatename, '%s', ''))
            end

            if not teammateisin and not teammatenoshow then
                partyapisay("Teammate_Exit" .. ":" .. string.gsub(teammatename, '%s', ''))
                teammatenoshow = true
            end
            for _, enemy in ipairs(cachelist) do
                if not findthisguy(enemy, playerlist) and enemy ~= teammatename then
                    if ingamestatus then
                        partyapisay("Defeat_Exit" .. ":" .. string.gsub(enemy, '%s', ''))
                    else
                        partyapisay("Warmup_Escaped" .. ":" .. string.gsub(enemy, '%s', ''))
                    end
                end
            end
            cachelist = playerlist
        end
        lastcssplayernumber = #players

        if purchasedex then
            local player = entity_list.get_player_from_userid(purchaseguy)
            local playername = string.gsub(player:get_name(), '%s', '')
            if player:get_active_weapon():get_name() == "tablet" then
                local purchaseIndex = (player:get_active_weapon()):get_prop("m_nLastPurchaseIndex")
                if purchaseIndex ~= -1 then
                    partyapisay(playername .. "_purchased_" .. tabletitemindex[purchaseIndex])
                end
            end
            purchasedex = false
        end
    end
end


local function on_event(e)
    local eventName = e.name
    if (eventName == "client_disconnect") or (eventName == "begin_new_match") then
        cachelist = {}
        deadlist = {}
        lastcssplayernumber = 0
        player_respawn_times = {}
        teammatename = ""
        teammatenoshow = true
        teammateisin = false
    end
    if ui.paradropmaster:get() then
        if eventName == "survival_paradrop_spawn" then
            partyapisay("ParaDrop_has_created!")
        elseif eventName == "survival_paradrop_break" then
            partyapisay("ParaDrop_has_destoryed!")
        end
    end
    if ui.dronedispatchmaster:get() and eventName == "drone_dispatched" then
        purchaseguy = e.userid
        purchasedex = true
    end
    if eventName == "player_death" and ingamestatus then
        deadlist[(entity_list.get_player_from_userid(e.userid)):get_name()] = true
        if entity_list.get_player_from_userid(e.userid):is_player() then
            local teamid = (entity_list.get_player_from_userid(e.userid)):get_prop("m_nSurvivalTeam")
            if teamid == -1 or teamid == nil then return end
            local playername = (entity_list.get_player_from_userid(e.userid)):get_name()
            if player_respawn_times[playername] then
                player_respawn_times[playername] = player_respawn_times[playername] + 10
            else
                player_respawn_times[playername] = 20
            end
        end
    end
end
callbacks.add(e_callbacks.EVENT, on_event)
callbacks.add(e_callbacks.SETUP_COMMAND, main_exec)

menu.add_button(ui.group_name, "Check DZ Team", function()
    if cvars.game_type:get_int() ~= 6 then
        partyapisay("Not_DangerZone_Mode!")
        return
    end
    local playerdata = {}
    local abuseteam = {}
    local nonsingleteamout = {}
    local players = entity_list.get_players(false)
    if players ~= nil then
        for _, player in ipairs(players) do
            local playerName = player:get_name()
            local playerIndex = player:get_index()
            if playerName ~= "GOTV" then
                local playerTeam = player:get_prop("m_nSurvivalTeam")
                local teamstr = "team" .. playerTeam
                if player_resource.get_prop("m_bHasCommunicationAbuseMute", playerIndex) == 1 and teamstr ~= "team-1" then
                    abuseteam[teamstr] = true
                end
                if playerdata[teamstr] == nil then
                    playerdata[teamstr] = {}
                end
                table.insert(playerdata[teamstr],
                    { playerIndex, playerName, playerTeam, player:is_alive() })
            end
        end

        partyapisay("--------------------------------------")
        for i, player in ipairs(players) do
            local teamstr = "team" .. player:get_prop("m_nSurvivalTeam")
            local communicationMute = player_resource.get_prop("m_bHasCommunicationAbuseMute", player:get_index())
            local playerName = player:get_name()
            if teamstr == "team-1" and playerName ~= "GOTV" then
                if communicationMute == 1 then
                    partyapisay(string.gsub(playerName, '%s', '') .. "=Cheater_Solo")
                else
                    partyapisay(string.gsub(playerName, '%s', '') .. "=Solo")
                end
            else
                local playerTeamData = playerdata[teamstr]
                if playerTeamData ~= nil then
                    if #playerTeamData ~= 1 then
                        for j, data in ipairs(playerTeamData) do
                            if data[1] ~= player:get_index() then
                                local teammateString = abuseteam[teamstr] and "CheaterTeammate:" or "Teammate:"
                                nonsingleteamout[teamstr] = teamstr ..
                                    ":" ..
                                    string.gsub(player:get_name(), '%s', '') ..
                                    "_" .. teammateString .. string.gsub(data[2], '%s', '')
                            end
                        end
                    else
                        if communicationMute == 1 then
                            nonsingleteamout[teamstr] = string.gsub(player:get_name(), '%s', '') ..
                                "=Might_Cheater_Solo"
                        else
                            nonsingleteamout[teamstr] = string.gsub(player:get_name(), '%s', '') .. "=Might_Solo"
                        end
                    end
                end
            end
        end
        for i = 0, 12 do
            local teamstr = "team" .. i
            if nonsingleteamout[teamstr] then
                partyapisay(nonsingleteamout[teamstr])
            end
        end
        partyapisay("Total:_" .. #players .. "_players")
        partyapisay("-----------------END------------------")
    end
end)
