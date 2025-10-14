local barrel_aimbot = ui.new_checkbox("lua", "b", "Explosive Barrel Aimbot")
local aimbot_hotkey = ui.new_hotkey("lua", "b", "Barrel aimbot hotkey", true)
local aimbot_silent_aim = ui.new_checkbox("lua", "b", "Barrel silent aim")
local max_distance = ui.new_slider("lua", "b", "Max aimbot distance", 500, 5000, 2000, true, "", 1)
local aim_height_offset = ui.new_slider("lua", "b", "Aim height offset", 0, 100, 20, true, "u", 1)

-- 颜色控制
ui.new_label("lua", "b", "Visible barrel color")
local visible_barrel_color = ui.new_color_picker("lua", "b", "Visible barrel color1", 0, 255, 149, 255)
ui.new_label("lua", "b", "Locked barrel color")
local locked_barrel_color = ui.new_color_picker("lua", "b", "Locked barrel color1", 255, 100, 0, 255)
ui.new_label("lua", "b", "Hidden barrel color")
local hidden_barrel_color = ui.new_color_picker("lua", "b", "Hidden barrel color1", 128, 128, 128, 255)

local eye_position, camera_angles, visible, trace_line = client.eye_position, client.camera_angles, client.visible, client.trace_line
local text, world_to_screen = renderer.text, renderer.world_to_screen
local get_prop, get_all, get_local_player, is_dormant = entity.get_prop, entity.get_all, entity.get_local_player, entity.is_dormant
local deg, atan2, sqrt = math.deg, math.atan2, math.sqrt
local get = ui.get

local function vector_angles(x1, y1, z1, x2, y2, z2)
    local origin_x, origin_y, origin_z
    local target_x, target_y, target_z
    if x2 == nil then
        target_x, target_y, target_z = x1, y1, z1
        origin_x, origin_y, origin_z = eye_position()
        if origin_x == nil then
            return
        end
    else
        origin_x, origin_y, origin_z = x1, y1, z1
        target_x, target_y, target_z = x2, y2, z2
    end

    --calculate delta of vectors
    local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z

    if delta_x == 0 and delta_y == 0 then
        return (delta_z > 0 and 270 or 90), 0
    else
        --calculate yaw
        local yaw = deg(atan2(delta_y, delta_x))

        --calculate pitch
        local hyp = sqrt(delta_x*delta_x + delta_y*delta_y)
        local pitch = deg(atan2(-delta_z, hyp))

        return pitch, yaw
    end
end

local function get_dist(a_x, a_y, a_z, b_x, b_y, b_z)
    -- 添加安全检查，确保所有坐标都不是 nil
    if not a_x or not a_y or not a_z or not b_x or not b_y or not b_z then
        return 99999
    end
    return math.sqrt(math.pow(a_x - b_x, 2) + math.pow(a_y - b_y, 2) + math.pow(a_z - b_z, 2))
end

-- 改进的可见性检查函数
local function is_visible(ent)
    local me = get_local_player()
    if not me then return false end
    
    local ex, ey, ez = eye_position()
    if not ex then return false end
    
    local x, y, z = get_prop(ent, "m_vecOrigin")
    if not x then return false end
    
    -- 检查多个点以提高准确性
    local points_to_check = {
        {x, y, z}, -- 原点
        {x, y, z + 10}, -- 稍微上方
        {x, y, z + 20}, -- 再高一点
        {x, y, z + 30}  -- 顶部
    }
    
    for _, point in ipairs(points_to_check) do
        local px, py, pz = point[1], point[2], point[3]
        local frac = trace_line(me, ex, ey, ez, px, py, pz)
        if frac and frac > 0.9 then
            return true
        end
    end
    
    return false
end

local function get_closest_barrel()
    local target = nil
    local min_distance = get(max_distance) or 2000
    local me = get_local_player()
    if not me then return nil end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    -- 添加安全检查
    if not mx then return nil end
    
    for _, ent in pairs(get_all("CPhysicsProp")) do
        if not is_dormant(ent) then
            -- 使用参考脚本中的模型名称检查
            local model_name = client.get_model_name(get_prop(ent, "m_nModelIndex"))
            if model_name and model_name == "models/props/coop_cementplant/exloding_barrel/exploding_barrel.mdl" then
                local x, y, z = get_prop(ent, "m_vecOrigin")
                if x then
                    local distance = get_dist(mx, my, mz, x, y, z)
                    
                    if distance < min_distance then
                        -- 使用改进的可见性检查
                        if is_visible(ent) then
                            min_distance = distance
                            target = ent
                        end
                    end
                end
            end
        end
    end
    
    return target, min_distance
end

local cur_target = nil
local cur_target_distance = 0

client.set_event_callback("setup_command", function(cmd)
    if not get(barrel_aimbot) then 
        cur_target = nil
        return 
    end
    
    local me = get_local_player()
    if not me then
        cur_target = nil
        return
    end
    
    if get(aimbot_hotkey) then
        local target, distance = get_closest_barrel()
        
        if target then 
            local x, y, z = get_prop(target, "m_vecOrigin")
            -- 添加安全检查
            if x then
                -- 应用高度偏移，使瞄准点稍微向上
                local height_offset = get(aim_height_offset) or 20
                local offset_z = z + height_offset
                
                local pitch, yaw = vector_angles(x, y, offset_z)
                cur_target = target
                cur_target_distance = distance
                
                if get(aimbot_silent_aim) then 
                    cmd.pitch = pitch
                    cmd.yaw = yaw
                else
                    camera_angles(pitch, yaw)
                end
            else
                cur_target = nil
            end
        else
            cur_target = nil
        end
    else
        cur_target = nil
    end
end)

client.set_event_callback("paint", function(ctx)
    if not get(barrel_aimbot) then return end
    
    local me = get_local_player()
    if not me then return end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    if not mx then return end
    
    for _, ent in pairs(get_all("CPhysicsProp")) do
        if not is_dormant(ent) then
            -- 使用AW中的模型名称检查
            local model_name = client.get_model_name(get_prop(ent, "m_nModelIndex"))
            if model_name and model_name == "models/props/coop_cementplant/exloding_barrel/exploding_barrel.mdl" then
                local x, y, z = get_prop(ent, "m_vecOrigin")
                if x then
                    local wx, wy = world_to_screen(x, y, z)
                    if wx then 
                        -- 获取颜色设置
                        local visible_r, visible_g, visible_b, visible_a = ui.get(visible_barrel_color)
                        local locked_r, locked_g, locked_b, locked_a = ui.get(locked_barrel_color)
                        local hidden_r, hidden_g, hidden_b, hidden_a = ui.get(hidden_barrel_color)
                        
                        local r, g, b, a = visible_r, visible_g, visible_b, visible_a
                        local barrel_text = "BARREL"
                        
                        -- 使用改进的可见性检查
                        local is_visible_result = is_visible(ent)
                        
                        -- 根据锁定状态和可见性设置颜色和文本
                        if not is_visible_result then
                            r, g, b, a = hidden_r, hidden_g, hidden_b, hidden_a
                            barrel_text = "BARREL"
                        elseif ent == cur_target then 
                            r, g, b, a = locked_r, locked_g, locked_b, locked_a
                            barrel_text = "LOCKED"
                        end
                        
                        -- 绘制爆炸桶标记
                        text(wx, wy, r, g, b, a, "c", 0, barrel_text)
                        
                        -- 绘制距离信息
                        local distance = get_dist(mx, my, mz, x, y, z)
                        text(wx, wy + 15, r, g, b, a, "c", 0, math.floor(distance) .. "u")
                        
                        -- 如果被锁定，显示瞄准偏移高度
                        if ent == cur_target then
                            local height_offset = get(aim_height_offset) or 20
                            text(wx, wy + 30, locked_r, locked_g, locked_b, locked_a, "c", 0, "+" .. height_offset .. "u")
                        end
                    end
                end
            end
        end
    end
end)

client.set_event_callback("paint", function()
    local enabled = get(barrel_aimbot)
    ui.set_visible(aimbot_hotkey, enabled)
    ui.set_visible(aimbot_silent_aim, enabled)
    ui.set_visible(max_distance, enabled)
    ui.set_visible(aim_height_offset, enabled)
    ui.set_visible(visible_barrel_color, enabled)
    ui.set_visible(locked_barrel_color, enabled)
    ui.set_visible(hidden_barrel_color, enabled)
end)