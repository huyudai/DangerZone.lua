local drone_aimbot = ui.new_checkbox("lua", "b", "Drone Killer")
local manual_aim_enabled = ui.new_checkbox("lua", "b", "Enable human-controlled drone aimbot")
local aimbot_manual_hotkey = ui.new_hotkey("lua", "b", "human-controlled drone aimbot hotkey", true)
local cargo_aim_enabled = ui.new_checkbox("lua", "b", "Enable items drone aimbot")
local aimbot_cargo_hotkey = ui.new_hotkey("lua", "b", "items drone aimbot hotkey", true)
local aimbot_silent_aim = ui.new_checkbox("lua", "b", "Drone silent aim")

-- 颜色控制
ui.new_label("lua", "b", "Human-controlled drone color")
local manual_drone_color = ui.new_color_picker("lua", "b", "Human-controlled drone color1", 255, 100, 100, 255)
ui.new_label("lua", "b", "Items drone color")
local cargo_drone_color = ui.new_color_picker("lua", "b", "Items drone color1", 100, 255, 100, 255)
ui.new_label("lua", "b", "Locked drone color")
local locked_drone_color = ui.new_color_picker("lua", "b", "Locked drone color1", 255, 0, 0, 255)
ui.new_label("lua", "b", "Hidden drone color")
local hidden_drone_color = ui.new_color_picker("lua", "b", "Hidden drone color1", 128, 128, 128, 255)

local eye_position, camera_angles, visible, trace_line = client.eye_position, client.camera_angles, client.visible, client.trace_line
local text, world_to_screen = renderer.text, renderer.world_to_screen
local get_prop, get_all, get_local_player, is_dormant = entity.get_prop, entity.get_all, entity.get_local_player, entity.is_dormant
local deg, atan2, sqrt = math.deg, math.atan2, math.sqrt
local get = ui.get

local function vector_angles(x1, y1, z1, x2, y2, z2)
    --https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/mathlib/mathlib_base.cpp#L535-L563
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

local function get_closest_drone(drone_type)
    local target = nil
    local min_distance = 8192
    local me = get_local_player()
    if not me then return nil end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    -- 添加安全检查
    if not mx then return nil end
    
    local ex, ey, ez = eye_position()
    -- 添加安全检查
    if not ex then return nil end
    
    for _, ent in pairs(get_all("CDrone")) do
        if not is_dormant(ent) then
            local x, y, z = get_prop(ent, "m_vecOrigin")
            if x then
                -- 检查无人机类型
                local pilot = get_prop(ent, "m_hCurrentPilot")
                local cargo = get_prop(ent, "m_hDeliveryCargo")
                
                local is_manual = pilot and pilot ~= -1
                local is_cargo = cargo and cargo ~= -1
                
                -- 根据类型筛选无人机
                local should_target = false
                if drone_type == "manual" and is_manual then
                    should_target = true
                elseif drone_type == "cargo" and is_cargo then
                    should_target = true
                end
                
                if should_target then
                    local distance = get_dist(mx, my, mz, x, y, z)
                    local frac = trace_line(me, ex, ey, ez, x, y, z)
                    -- 可见性检查：frac > 0.97 表示几乎完全可见
                    if distance < min_distance and frac > 0.97 then
                        min_distance = distance
                        target = ent
                    end
                end
            end
        end
    end
    return target, min_distance
end

local cur_target = nil
local cur_target_distance = 0
local cur_target_type = ""

client.set_event_callback("setup_command", function(cmd)
    if not get(drone_aimbot) then 
        cur_target = nil
        return 
    end
    
    local me = get_local_player()
    if not me then
        cur_target = nil
        return
    end
    
    local target, distance
    local drone_type = ""
    
    -- 检查人工控制无人机锁定
    if get(manual_aim_enabled) and get(aimbot_manual_hotkey) then
        target, distance = get_closest_drone("manual")
        drone_type = "HUMAN"
    -- 检查货物无人机锁定
    elseif get(cargo_aim_enabled) and get(aimbot_cargo_hotkey) then
        target, distance = get_closest_drone("cargo")
        drone_type = "ITEMS"
    else
        cur_target = nil
        return
    end
    
    if target then 
        local x, y, z = get_prop(target, "m_vecOrigin")
        -- 添加安全检查
        if x then
            local pitch, yaw = vector_angles(x, y, z)
            cur_target = target
            cur_target_distance = distance
            cur_target_type = drone_type
            
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
end)

client.set_event_callback("paint", function(ctx)
    if not get(drone_aimbot) then return end
    
    local me = get_local_player()
    if not me then return end
    
    local ex, ey, ez = eye_position()
    if not ex then return end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    if not mx then return end
    
    for _, ent in pairs(get_all("CDrone")) do
        if not is_dormant(ent) then
            local x, y, z = get_prop(ent, "m_vecOrigin")
            if x then
                local wx, wy = world_to_screen(x, y, z)
                if wx then 
                    -- 获取颜色设置
                    local manual_r, manual_g, manual_b, manual_a = ui.get(manual_drone_color)
                    local cargo_r, cargo_g, cargo_b, cargo_a = ui.get(cargo_drone_color)
                    local locked_r, locked_g, locked_b, locked_a = ui.get(locked_drone_color)
                    local hidden_r, hidden_g, hidden_b, hidden_a = ui.get(hidden_drone_color)
                    
                    local r, g, b, a = 255, 255, 255, 255
                    local drone_text = "DRONE"
                    
                    -- 检查无人机类型
                    local pilot = get_prop(ent, "m_hCurrentPilot")
                    local cargo = get_prop(ent, "m_hDeliveryCargo")
                    
                    local is_manual = pilot and pilot ~= -1
                    local is_cargo = cargo and cargo ~= -1
                    
                    -- 可见性检查
                    local frac = trace_line(me, ex, ey, ez, x, y, z)
                    local is_visible = frac > 0.97
                    
                    -- 根据无人机类型、锁定状态和可见性设置颜色和文本
                    if not is_visible then
                        r, g, b, a = hidden_r, hidden_g, hidden_b, hidden_a
                        drone_text = "DRONE"
                    elseif ent == cur_target then 
                        r, g, b, a = locked_r, locked_g, locked_b, locked_a
                        drone_text = cur_target_type .. " LOCK"
                    elseif is_manual then
                        r, g, b, a = manual_r, manual_g, manual_b, manual_a
                        drone_text = "HUMAN"
                    elseif is_cargo then
                        r, g, b, a = cargo_r, cargo_g, cargo_b, cargo_a
                        drone_text = "ITEMS"
                    end
                    
                    -- 绘制无人机标记
                    text(wx, wy, r, g, b, a, "c", 0, drone_text)
                    
                    -- 绘制距离信息
                    local distance = get_dist(mx, my, mz, x, y, z)
                    text(wx, wy + 15, r, g, b, a, "c", 0, math.floor(distance) .. "u")
                end
            end
        end
    end
end)

client.set_event_callback("paint", function()
    local enabled = get(drone_aimbot)
    ui.set_visible(manual_aim_enabled, enabled)
    ui.set_visible(cargo_aim_enabled, enabled)
    ui.set_visible(aimbot_manual_hotkey, enabled)
    ui.set_visible(aimbot_cargo_hotkey, enabled)
    ui.set_visible(aimbot_silent_aim, enabled)
    ui.set_visible(manual_drone_color, enabled)
    ui.set_visible(cargo_drone_color, enabled)
    ui.set_visible(locked_drone_color, enabled)
    ui.set_visible(hidden_drone_color, enabled)
end)
----this version update on 25/10/5