--来自gamesense官网的dmup包 使用ai使其变成人能看懂的代码
-- 导入必要的库和函数
local eye_position = client.eye_position
local camera_angles = client.camera_angles
local trace_line = client.trace_line
local get_prop = entity.get_prop
local get_all_entities = entity.get_all
local get_local_player = entity.get_local_player
local get_player_resource = entity.get_player_resource
local get_classname = entity.get_classname
local get_origin = entity.get_origin
local get_player_weapon = entity.get_player_weapon
local hitbox_position = entity.hitbox_position
local is_enemy = entity.is_enemy
local math_deg = math.deg
local math_atan2 = math.atan2
local math_sqrt = math.sqrt
local bit_band = bit.band
local ui_get = ui.get
local ui_new_checkbox = ui.new_checkbox
local ui_new_hotkey = ui.new_hotkey
local table_insert = table.insert

-- 导入vector库
local vector = require("vector")

-- 创建UI元素
local punchbot_checkbox = ui_new_checkbox("Misc", "Miscellaneous", "Punchbot")
local punchbot_hotkey = ui_new_hotkey("Misc", "Miscellaneous", "Punchbot", true)
local punchbot_silent_aim = ui_new_checkbox("Misc", "Miscellaneous", "Punchbot Silent aim")
local punchbot_ignore_team = ui_new_checkbox("Misc", "Miscellaneous", "Punchbot Ignore Team Check")

-- 计算两点之间的角度
local function calculate_angles(from_x, from_y, from_z, to_x, to_y, to_z)
    local delta_x = to_x - from_x
    local delta_y = to_y - from_y
    local delta_z = to_z - from_z
    
    if delta_x == 0 and delta_y == 0 then
        return (delta_z > 0 and 270 or 90), 0
    else
        local yaw = math_deg(math_atan2(delta_y, delta_x))
        local hyp = math_sqrt(delta_x * delta_x + delta_y * delta_y)
        local pitch = math_deg(math_atan2(-delta_z, hyp))
        
        return pitch, yaw
    end
end

-- 获取最佳目标
local function get_best_target()
    local player_resource = get_player_resource()
    local valid_players = {}
    local local_player = get_local_player()
    
    -- 遍历所有玩家
    for player_index = 1, 64 do
        if get_classname(player_index) == "CCSPlayer" and 
           get_prop(player_resource, "m_bAlive", player_index) == 1 and 
           player_index ~= local_player then
            
            local ignore_team = ui_get(punchbot_ignore_team)
            
            -- 检查是否为敌人或者忽略队伍检查
            if not ignore_team and is_enemy(player_index) then
                table_insert(valid_players, player_index)
            elseif ignore_team then
                table_insert(valid_players, player_index)
            end
        end
    end
    
    if #valid_players == 0 then
        return nil
    end
    
    -- 找到最近的玩家
    local local_origin = vector(get_origin(local_player))
    local best_target = nil
    local closest_distance = 999999999
    
    for i = 1, #valid_players do
        local player_index = valid_players[i]
        local player_origin = vector(get_origin(player_index))
        local distance = local_origin:dist(player_origin)
        
        if distance < closest_distance then
            closest_distance = distance
            best_target = player_index
        end
    end
    
    -- 检查命中框可见性
    if best_target ~= nil and closest_distance ~= 999999999 then
        for hitbox_id = 0, 18 do
            local local_player_ent = get_local_player()
            local eye_pos = vector(eye_position())
            local hitbox_pos = vector(hitbox_position(best_target, hitbox_id))
            local distance_to_hitbox = eye_pos:dist(hitbox_pos)
            
            -- 进行射线追踪检查可见性
            local fraction, hit_entity = trace_line(
                local_player_ent, 
                eye_pos.x, eye_pos.y, eye_pos.z, 
                hitbox_pos.x, hitbox_pos.y, hitbox_pos.z
            )
            
            -- 如果命中的不是目标玩家，跳过这个命中框
            if hit_entity ~= best_target then
                distance_to_hitbox = 999999
            end
            
            -- 如果距离足够近，返回这个命中框位置
            if distance_to_hitbox < 80 then
                return hitbox_pos
            end
        end
    end
    
    return nil
end

-- 主逻辑
client.set_event_callback("setup_command", function(cmd)
    local local_player = get_local_player()
    
    -- 检查本地玩家是否有效
    if not local_player or get_prop(local_player, "m_lifeState") ~= 0 then
        return
    end
    
    -- 获取当前武器
    local weapon = get_player_weapon(local_player)
    if not weapon then
        return
    end
    
    -- 检查是否为匕首（武器索引69）
    local weapon_index = bit_band(get_prop(weapon, "m_iItemDefinitionIndex"), 65535)
    
    if ui_get(punchbot_checkbox) and weapon_index == 69 then
        local target_position = get_best_target()
        
        if target_position ~= nil then
            local eye_pos = vector(eye_position())
            local pitch, yaw = eye_pos:to(target_position):angles()
            
            if ui_get(punchbot_hotkey) then
                if ui_get(punchbot_silent_aim) then
                    -- 静默瞄准：直接设置命令角度
                    cmd.pitch = pitch
                    cmd.yaw = yaw
                    cmd.in_attack = 1
                else
                    -- 普通瞄准：设置相机角度
                    camera_angles(pitch, yaw)
                    cmd.in_attack = 1
                end
            end
        end
    end
end)

-- UI可见性控制
client.set_event_callback("paint", function()
    local punchbot_enabled = ui_get(punchbot_checkbox)
    ui.set_visible(punchbot_silent_aim, punchbot_enabled)
    ui.set_visible(punchbot_ignore_team, punchbot_enabled)
end)