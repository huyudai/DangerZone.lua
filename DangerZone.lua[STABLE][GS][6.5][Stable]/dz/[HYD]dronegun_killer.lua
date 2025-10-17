local dg_drone_aimbot = ui.new_checkbox("lua", "b", "Dronegun Killer")
local dg_aimbot_enabled = ui.new_checkbox("lua", "b", "Enable dronegun aimbot")
local dg_aimbot_hotkey = ui.new_hotkey("lua", "b", "Drone gun aimbot hotkey", true)
local dg_aimbot_silent_aim = ui.new_checkbox("lua", "b", "Dronegun silent aim")

-- 自定义高度偏移控件
local dg_aim_height_offset = ui.new_slider("lua", "b", "Dronegun Aim height offset", 0, 100, 30, true, "u", 1)

-- 显示控制开关
local dg_show_distance = ui.new_checkbox("lua", "b", "Show distance")
local dg_show_visibility = ui.new_checkbox("lua", "b", "Show visibility values")

-- 颜色控制
ui.new_label("lua", "b", "Drone gun color")
local dg_drone_color = ui.new_color_picker("lua", "b", "Dronegun color", 100, 255, 100, 255)
ui.new_label("lua", "b", "Locked dronegun color")
local dg_locked_drone_color = ui.new_color_picker("lua", "b", "Locked dronegun color", 255, 0, 0, 255)
ui.new_label("lua", "b", "Hidden dronegun color")
local dg_hidden_drone_color = ui.new_color_picker("lua", "b", "Hidden dronegun color", 128, 128, 128, 255)

local eye_position, camera_angles, visible, trace_line = client.eye_position, client.camera_angles, client.visible, client.trace_line
local text, world_to_screen = renderer.text, renderer.world_to_screen
local get_prop, get_all, get_local_player, is_dormant = entity.get_prop, entity.get_all, entity.get_local_player, entity.is_dormant
local deg, atan2, sqrt, floor = math.deg, math.atan2, math.sqrt, math.floor
local get = ui.get

-- 游戏单位到英尺的转换函数
local function units_to_feet(units)
    return floor(units * 0.0625) -- 1单位 = 0.0625英尺
end

-- 英尺到游戏单位的转换函数
local function feet_to_units(feet)
    return feet * 16 -- 1英尺 = 16单位
end

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

    local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z

    if delta_x == 0 and delta_y == 0 then
        return (delta_z > 0 and 270 or 90), 0
    else
        local yaw = deg(atan2(delta_y, delta_x))
        local hyp = sqrt(delta_x*delta_x + delta_y*delta_y)
        local pitch = deg(atan2(-delta_z, hyp))

        return pitch, yaw
    end
end

local function get_dist(a_x, a_y, a_z, b_x, b_y, b_z)
    if not a_x or not a_y or not a_z or not b_x or not b_y or not b_z then
        return 99999
    end
    return math.sqrt(math.pow(a_x - b_x, 2) + math.pow(a_y - b_y, 2) + math.pow(a_z - b_z, 2))
end

local function get_closest_drone_gun()
    local target = nil
    local min_distance = 8192
    local me = get_local_player()
    if not me then return nil end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    if not mx then return nil end
    
    local ex, ey, ez = eye_position()
    if not ex then return nil end
    
    -- 获取自定义高度偏移值
    local offset_z = get(dg_aim_height_offset)
    
    for _, ent in pairs(get_all("CDronegun")) do
        if not is_dormant(ent) then
            local x, y, z = get_prop(ent, "m_vecOrigin")
            if x then
                -- 使用自定义高度偏移量，瞄准无人机枪的上部
                local target_z = z + offset_z
                
                local distance = get_dist(mx, my, mz, x, y, z)
                
                -- 根据距离调整可见性检查阈值
                -- 32英尺 = 32 * 16 = 512单位
                -- 近距离使用更宽松的可见性检查，远距离使用严格检查
                local visibility_threshold = distance < 512 and 0.8 or 0.97
                
                local frac = trace_line(me, ex, ey, ez, x, y, target_z)
                local is_visible = frac > visibility_threshold
                
                if distance < min_distance and is_visible then
                    min_distance = distance
                    target = {entity = ent, x = x, y = y, z = target_z}
                end
            end
        end
    end
    return target, min_distance
end

local cur_target = nil
local cur_target_distance = 0

client.set_event_callback("setup_command", function(cmd)
    if not get(dg_drone_aimbot) or not get(dg_aimbot_enabled) or not get(dg_aimbot_hotkey) then 
        cur_target = nil
        return 
    end
    
    local me = get_local_player()
    if not me then
        cur_target = nil
        return
    end
    
    local target, distance = get_closest_drone_gun()
    
    if target then 
        local pitch, yaw = vector_angles(target.x, target.y, target.z)
        cur_target = target.entity
        cur_target_distance = distance
        
        if get(dg_aimbot_silent_aim) then 
            cmd.pitch = pitch
            cmd.yaw = yaw
        else
            camera_angles(pitch, yaw)
        end
    else
        cur_target = nil
    end
end)

client.set_event_callback("paint", function(ctx)
    if not get(dg_drone_aimbot) then return end
    
    local me = get_local_player()
    if not me then return end
    
    local ex, ey, ez = eye_position()
    if not ex then return end
    
    local mx, my, mz = get_prop(me, "m_vecAbsOrigin")
    if not mx then return end
    
    -- 获取自定义高度偏移值
    local offset_z = get(dg_aim_height_offset)
    
    for _, ent in pairs(get_all("CDronegun")) do
        if not is_dormant(ent) then
            local x, y, z = get_prop(ent, "m_vecOrigin")
            if x then
                -- 使用自定义高度偏移量用于显示
                local display_z = z + offset_z
                
                local wx, wy = world_to_screen(x, y, display_z)
                if wx then 
                    -- 获取颜色设置
                    local drone_r, drone_g, drone_b, drone_a = ui.get(dg_drone_color)
                    local locked_r, locked_g, locked_b, locked_a = ui.get(dg_locked_drone_color)
                    local hidden_r, hidden_g, hidden_b, hidden_a = ui.get(dg_hidden_drone_color)
                    
                    local r, g, b, a = drone_r, drone_g, drone_b, drone_a
                    local drone_text = "DRONEGUN"
                    
                    -- 根据距离调整可见性检查阈值
                    local distance = get_dist(mx, my, mz, x, y, z)
                    local visibility_threshold = distance < 512 and 0.8 or 0.97
                    
                    local frac = trace_line(me, ex, ey, ez, x, y, display_z)
                    local is_visible = frac > visibility_threshold
                    
                    -- 根据锁定状态和可见性设置颜色和文本
                    if ent == cur_target then 
                        r, g, b, a = locked_r, locked_g, locked_b, locked_a
                        drone_text = "LOCKED"
                    elseif not is_visible then
                        r, g, b, a = hidden_r, hidden_g, hidden_b, hidden_a
                        drone_text = "DRONEGUN"
                    end
                    
                    -- 绘制无人机枪标记
                    text(wx, wy, r, g, b, a, "c", 0, drone_text)
                    
                    -- 构建信息行
                    local info_line = ""
                    
                    -- 添加距离信息（如果启用）
                    if get(dg_show_distance) then
                        local distance_ft = units_to_feet(distance)
                        info_line = distance_ft .. "FT"
                    end
                    
                    -- 添加可见性数值（如果启用）
                    if get(dg_show_visibility) then
                        if info_line ~= "" then
                            info_line = info_line .. " "
                        end
                        info_line = info_line .. string.format("%.2f", frac)
                    end
                    
                    -- 绘制信息行
                    if info_line ~= "" then
                        text(wx, wy + 15, r, g, b, a, "c", 0, info_line)
                    end
                    
                    -- 只在锁定目标时显示偏移值
                    if ent == cur_target then
                        text(wx, wy + 30, r, g, b, a, "c", 0, "Offset: " .. offset_z)
                    end
                end
            end
        end
    end
end)

client.set_event_callback("paint", function()
    local enabled = get(dg_drone_aimbot)
    ui.set_visible(dg_aimbot_enabled, enabled)
    ui.set_visible(dg_aimbot_hotkey, enabled)
    ui.set_visible(dg_aimbot_silent_aim, enabled)
    ui.set_visible(dg_aim_height_offset, enabled)
    ui.set_visible(dg_show_distance, enabled)
    ui.set_visible(dg_show_visibility, enabled)
    ui.set_visible(dg_drone_color, enabled)
    ui.set_visible(dg_locked_drone_color, enabled)
    ui.set_visible(dg_hidden_drone_color, enabled)
end)