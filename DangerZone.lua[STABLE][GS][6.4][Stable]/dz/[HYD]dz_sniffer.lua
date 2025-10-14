-- DangerZone Sniffer for GameSense (复刻 Aimware Lua)
-- 支持：控制台/队伍/公聊 输出，复活/退出/空投/购买监听，队伍检测，购买物品名映射
-- Author: adapted by ChatGPT

-- ===================== UI =====================
local ui_new_checkbox = ui.new_checkbox
local ui_new_combobox  = ui.new_combobox
local ui_new_button    = ui.new_button
local ui_get           = ui.get

local master_enable       = ui_new_checkbox("Lua", "B", "Enable DZ Sniffer")
local messagemaster       = ui_new_checkbox("Lua", "B", "[DZ] Print Message")
local respawnmaster       = ui_new_checkbox("Lua", "B", "[DZ] Respawn Sniffer")
local exitmaster          = ui_new_checkbox("Lua", "B", "[DZ] Disconnect Sniffer")
local paradropmaster      = ui_new_checkbox("Lua", "B", "[DZ] Airdrop Sniffer")
local dronedispatchmaster = ui_new_checkbox("Lua", "B", "[DZ] Buy Sniffer")
local ranks_mode          = ui_new_combobox("Lua", "B", "[DZ] PrintMode", "Console Only", "Allchat", "Teamchat")

-- ===================== 武器映射（AW Lua 风格） =====================
local tabletitemindex = {
    [-1] = "空",
    [0]  = "刀",
    [1]  = "手枪",
    [2]  = "冲锋枪",
    [3]  = "步枪",
    [4]  = "鸟狙",
    [5]  = "未定义(5)",
    [6]  = "护甲",
    [7]  = "子弹盒",
    [8]  = "未定义(8)",
    [9]  = "未定义(9)",
    [10] = "烟闪套装",
    [11] = "屏蔽器",
    [12] = "医疗针",
    [13] = "无人机检测芯片",
    [14] = "安全区检测芯片",
    [15] = "富贵芯片",
    [16] = "手雷套装",
    [17] = "沙鹰",
    [18] = "无人机控制芯片",
    [19] = "EXO弹跳套装",
    [20] = "未定义(20)",
    [21] = "大盾",
}

-- ===================== 状态变量 =====================
local playerlist = {}
local cachelist  = {}
local deadlist   = {}
local reslist    = {}
local player_respawn_times = {}
local last_player_count = 0
local teammate_name     = ""
local teammate_no_show  = true
local teammate_is_in    = false
local purchase_pending  = {}

-- ===================== 发送消息函数 =====================
local function sendmsg(message)
    if not ui_get(master_enable) then return end
    if not ui_get(messagemaster) then return end

    -- 控制台输出
    print("[DZ] " .. message)

    -- 聊天输出
    local mode = ui_get(ranks_mode)
    if mode == "Teamchat" then
        client.exec("say_team " .. message)
    elseif mode == "Allchat" then
        client.exec("say " .. message)
    end
end

-- ===================== Helper: 游戏内判断 =====================
local function ingame()
    local players = entity.get_players(true)
    return players and #players > 1
end

-- ===================== 无人机购买监听 =====================
local function push_purchase_pending(userid)
    if not userid then return end
    for _, v in ipairs(purchase_pending) do
        if v.userid == userid then
            v.ticks = 60
            v.tries = 0
            return
        end
    end
    table.insert(purchase_pending, { userid = userid, ticks = 60, tries = 0 })
end

client.set_event_callback("drone_dispatched", function(e)
    if not ui_get(master_enable) or not ui_get(dronedispatchmaster) then return end
    if not e then return end
    local uid = e.userid or e.userid64 or e.user or e["userid"]
    if uid then
        push_purchase_pending(uid)
    end
end)

client.set_event_callback("paint", function()
    if not ui_get(master_enable) or not ui_get(dronedispatchmaster) then return end
    if #purchase_pending == 0 then return end

    for i = #purchase_pending, 1, -1 do
        local info = purchase_pending[i]
        if not info or not info.userid then
            table.remove(purchase_pending, i)
        else
            info.ticks = (info.ticks or 0) - 1
            info.tries = (info.tries or 0) + 1
            local entindex = client.userid_to_entindex(info.userid)
            if entindex and entindex ~= 0 then
                local weapon_ent = entity.get_player_weapon(entindex)
                if not weapon_ent then
                    local hActive = entity.get_prop(entindex, "m_hActiveWeapon")
                    if hActive then
                        local maybe_index = tonumber(hActive)
                        if maybe_index and maybe_index > 0 then
                            weapon_ent = maybe_index
                        end
                    end
                end

                if weapon_ent and weapon_ent ~= 0 then
                    local idx = entity.get_prop(weapon_ent, "m_nLastPurchaseIndex")
                             or entity.get_prop(weapon_ent, "m_nPurchaseIndex")
                             or entity.get_prop(weapon_ent, "m_iLastPurchaseIndex")
                             or entity.get_prop(weapon_ent, "m_nLastBoughtIndex")
                             or entity.get_prop(weapon_ent, "m_nTabletPurchaseIndex")
                             or nil

                    if idx ~= nil then
                        local nidx = tonumber(idx)
                        if nidx and nidx ~= -1 then
                            local pname = entity.get_player_name(entindex) or ("userid:" .. tostring(info.userid))
                            local itemname = tabletitemindex[nidx] or ("未知物品 (id:" .. tostring(nidx) .. ")")
                            sendmsg(pname .. " 通过无人机购买了 " .. itemname)
                            table.remove(purchase_pending, i)
                            goto continue_outer
                        end
                    end
                end
            end

            if info.ticks <= 0 then
                sendmsg("userid:" .. tostring(info.userid) .. " 购买事件超时")
                table.remove(purchase_pending, i)
            end
        end
        ::continue_outer::
    end
end)

-- ===================== 死亡/复活/空投/退出监听 =====================
client.set_event_callback("player_death", function(e)
    if not ui_get(master_enable) then return end
    local uid = e.userid or e.userid64 or e.user or e["userid"]
    if not uid then return end
    local ent = client.userid_to_entindex(uid)
    local name = ent and entity.get_player_name(ent) or ("userid:" .. tostring(uid))
    deadlist[name] = true
    reslist[name] = true
    if ingame() then
        if player_respawn_times[name] then
            player_respawn_times[name] = player_respawn_times[name] + 10
        else
            player_respawn_times[name] = 20
        end
    end
    sendmsg(name .. " 死亡")
end)

client.set_event_callback("player_spawn", function(e)
    if not ui_get(master_enable) or not ui_get(respawnmaster) then return end
    local uid = e.userid or e.userid64 or e.user or e["userid"]
    if not uid then return end
    local ent = client.userid_to_entindex(uid)
    if not ent or ent == 0 then return end
    local name = entity.get_player_name(ent) or ("userid:" .. tostring(uid))

    if deadlist[name] then
        local addstr = player_respawn_times[name] and (" 下一次时间:" .. math.floor(player_respawn_times[name])) or ""
        sendmsg("复活开始选点: " .. name .. addstr)
        deadlist[name] = false
    elseif reslist[name] then
        local w = entity.get_player_weapon(ent)
        local wclassname = w and (entity.get_classname(w) or "") or ""
        if wclassname ~= "" and not (wclassname:lower():find("fists")) then
            sendmsg(name .. " 已经跳伞！")
            reslist[name] = false
        end
    end
end)

client.set_event_callback("survival_paradrop_spawn", function() if ui_get(paradropmaster) then sendmsg("生成了空投！") end end)
client.set_event_callback("survival_paradrop_break", function() if ui_get(paradropmaster) then sendmsg("空投被摧毁！") end end)
client.set_event_callback("player_disconnect", function(e) if ui_get(exitmaster) then sendmsg("玩家退出: " .. tostring(e.name or e.userid)) end end)

client.set_event_callback("begin_new_match", function() 
    cachelist = {} deadlist = {} reslist = {} last_player_count = 0 player_respawn_times = {}
    teammate_name = "" teammate_no_show = true teammate_is_in = false purchase_pending = {}
end)
client.set_event_callback("client_disconnect", function()
    cachelist = {} deadlist = {} reslist = {} last_player_count = 0 player_respawn_times = {}
    teammate_name = "" teammate_no_show = true teammate_is_in = false purchase_pending = {}
end)

-- ===================== 队伍检测按钮 =====================
local function check_teams()
    local players = entity.get_players(true)
    if not players or #players == 0 then sendmsg("没有检测到玩家") return end
    sendmsg("--------------------------------------")
    local buckets = {}
    for _, pid in ipairs(players) do
        local pname = entity.get_player_name(pid) or ("id:" .. tostring(pid))
        local team = entity.get_prop(pid, "m_nSurvivalTeam") or entity.get_prop(pid, "m_iTeamNum") or -1
        local k = "team" .. team
        buckets[k] = buckets[k] or {}
        table.insert(buckets[k], { idx=pid, name=pname, alive=entity.is_alive(pid) })
    end
    for k,v in pairs(buckets) do
        if #v==1 then sendmsg(string.gsub(v[1].name,'%s','').." = 单排")
        else for _,info in ipairs(v) do sendmsg(k..": "..string.gsub(info.name,'%s','').." (alive:"..tostring(info.alive)..")") end
        end
    end
    sendmsg("总共:"..#players.."名玩家")
    sendmsg("-----------------END------------------")
end

ui_new_button("Lua","B","Check DangerZone Team", check_teams)
