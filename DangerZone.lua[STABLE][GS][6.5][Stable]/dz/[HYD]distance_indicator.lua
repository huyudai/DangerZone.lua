-- 最近玩家距离指示器 - FT单位版本
local distance_enable = ui.new_checkbox("VISUALS", "Other ESP", "Distance Indicator")
local distance_max = ui.new_slider("VISUALS", "Other ESP", "Max Distance", 100, 2000, 500, true, "ft")
local pos_x = ui.new_slider("VISUALS", "Other ESP", "Indicator X", 0, 2000, 100, true, "px")
local pos_y = ui.new_slider("VISUALS", "Other ESP", "Indicator Y", 0, 2000, 500, true, "px")

-- 初始隐藏其他控件
ui.set_visible(distance_max, false)
ui.set_visible(pos_x, false)
ui.set_visible(pos_y, false)

-- 更新控件可见性
local function update_visibility()
    local enabled = ui.get(distance_enable)
    ui.set_visible(distance_max, enabled)
    ui.set_visible(pos_x, enabled)
    ui.set_visible(pos_y, enabled)
end

-- 注册复选框变化回调
ui.set_callback(distance_enable, update_visibility)

-- 获取本地玩家
local function get_local_player()
    return entity.get_local_player()
end

-- 计算距离
local function get_distance(pos1, pos2)
    if not pos1 or not pos2 then return 9999 end
    
    local dx = pos1[1] - pos2[1]
    local dy = pos1[2] - pos2[2]
    local dz = pos1[3] - pos2[3]
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- 获取最近的敌人
local function get_nearest_enemy()
    local local_player = get_local_player()
    if not local_player or not entity.is_alive(local_player) then 
        return nil, 9999 
    end
    
    local local_team = entity.get_prop(local_player, "m_iTeamNum")
    local local_pos = {entity.get_prop(local_player, "m_vecOrigin")}
    local nearest_distance = 9999
    local nearest_player = nil
    
    local players = entity.get_players(true) -- 只获取敌人
    
    for _, player in ipairs(players) do
        if entity.is_alive(player) then
            local player_pos = {entity.get_prop(player, "m_vecOrigin")}
            local distance = get_distance(local_pos, player_pos)
            
            if distance < nearest_distance then
                nearest_distance = distance
                nearest_player = player
            end
        end
    end
    
    return nearest_player, nearest_distance
end

-- 平滑动画值
local function lerp(current, target, speed)
    return current + (target - current) * speed
end

-- 绘制距离指示器
local smooth_distance = 0
local smooth_alpha = 0
local is_dragging = false
local drag_offset_x, drag_offset_y = 0, 0

local function draw_distance_indicator()
    if not ui.get(distance_enable) then 
        smooth_alpha = lerp(smooth_alpha, 0, globals.frametime() * 8)
        return 
    end
    
    local nearest_player, distance = get_nearest_enemy()
    if not nearest_player then 
        smooth_alpha = lerp(smooth_alpha, 0, globals.frametime() * 8)
        return 
    end
    
    -- 转换为英尺 (Source引擎单位就是英寸，1英尺=12英寸)
    local distance_feet = distance / 12
    local max_distance = ui.get(distance_max)
    
    -- 平滑动画
    smooth_distance = lerp(smooth_distance, distance_feet, globals.frametime() * 10)
    smooth_alpha = lerp(smooth_alpha, 255, globals.frametime() * 8)
    
    local screen_width, screen_height = client.screen_size()
    
    -- 获取位置设置
    local x = ui.get(pos_x)
    local y = ui.get(pos_y)
    
    -- 鼠标拖动功能
    local mouse_x, mouse_y = ui.mouse_position()
    local mouse_down = client.key_state(0x1) -- 左键
    
    -- 检查鼠标是否在指示器区域内
    local text = string.format("%.0fft", smooth_distance)
    local text_width = renderer.measure_text("", text)
    local indicator_width = text_width + 20
    local indicator_height = 25
    
    local in_area = mouse_x >= x and mouse_x <= x + indicator_width and 
                   mouse_y >= y and mouse_y <= y + indicator_height
    
    -- 处理拖动
    if in_area and mouse_down and not is_dragging then
        is_dragging = true
        drag_offset_x = mouse_x - x
        drag_offset_y = mouse_y - y
    elseif is_dragging and mouse_down then
        x = mouse_x - drag_offset_x
        y = mouse_y - drag_offset_y
        
        -- 限制在屏幕范围内
        x = math.max(0, math.min(x, screen_width - indicator_width))
        y = math.max(0, math.min(y, screen_height - indicator_height))
        
        ui.set(pos_x, x)
        ui.set(pos_y, y)
    elseif not mouse_down then
        is_dragging = false
    end
    
    -- 根据距离改变颜色（越近越红）
    local color_percent = math.min(1.0, smooth_distance / max_distance)
    local r = math.floor(255 * (1 - color_percent))
    local g = math.floor(255 * color_percent)
    local b = 50
    
    -- 绘制距离数字
    renderer.text(x + 10, y + 5, r, g, b, smooth_alpha, "", 0, text)
    
    -- 绘制距离条
    local bar_width = indicator_width - 20
    local bar_height = 3
    local fill_percent = math.min(1.0, smooth_distance / max_distance)
    local fill_width = bar_width * (1 - fill_percent)
    
    -- 条背景
    renderer.rectangle(x + 10, y + indicator_height - 8, bar_width, bar_height, 50, 50, 50, 200)
    
    -- 条前景
    renderer.rectangle(x + 10, y + indicator_height - 8, fill_width, bar_height, r, g, b, 255)
end

-- 注册绘制回调
client.set_event_callback("paint", draw_distance_indicator)