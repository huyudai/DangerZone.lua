local function file_exists(file_name)
	local found = false
	for k, searcher in next, package.searchers do
		found = found or searcher(file_name)
	end
	return found
end
local ffi = require("ffi")
local vector = require"vector"
ffi.cdef([[
    typedef void*(__thiscall* get_client_entity_t)(void*, int);
]])

local function vmt_entry(instance, index, type)
    return ffi.cast(type, (ffi.cast("void***", instance)[0])[index])
end
local function vmt_thunk(index, typestring)
    local t = ffi.typeof(typestring)
    return function(instance, ...)
        assert(instance ~= nil)
        if instance then
            return vmt_entry(instance, index, t)(instance, ...)
        end
    end
end
local get_abs_angles = vmt_thunk(11, "float*(__thiscall*)(void*)")
local entitylist = ffi.cast(ffi.typeof("void***"), client.create_interface("client.dll", "VClientEntityList003"));
local get_client_entity = ffi.cast("get_client_entity_t", entitylist[0][3])

-- 获取ragebot的Enabled引用
local rage_enabled = ui.reference("RAGE", "Aimbot", "Enabled")
local multiselect_target_hitbox = ui.reference("rage", "aimbot", "Target hitbox")
local toggle_shieldbot = ui.new_checkbox("rage", "other", "Avoid shielded players")
local toggle_shieldbot_indicator = ui.new_checkbox("rage", "other", "Player flag indicator")
local color_shieldbot_indicator = ui.new_color_picker("rage", "other", "Player flag color", 255, 255, 0, 255)
local multiselect_shieldbot_hitboxes = ui.new_multiselect("rage", "Other", "Return hitboxes",
	"Head", "Chest",
	"Stomach", "Arms",
	"Legs", "Feet"
)
local slider_shieldbot_angle_scale = ui.new_slider("rage", "other", "Angle scale", 10, 150, 80, true, "dg")

-- 添加新选项：停止ragebot的角度阈值
local slider_stop_ragebot_angle = ui.new_slider("rage", "other", "Stop ragebot angle", 1, 90, 60, true, "°")

-- 添加正面盾处理方式选项
local combobox_front_shield_action = ui.new_combobox("rage", "other", "Front shield action", "Head only", "Disable ragebot", "Feet only")

-- 添加切换绑键
local hotkey_toggle_action = ui.new_hotkey("rage", "other", "Toggle front shield action")

-- 添加调试选项
local toggle_debug = ui.new_checkbox("rage", "other", "Debug shield angles")

-- 添加指示器选项
local toggle_indicator = ui.new_checkbox("rage", "other", "Show mode indicator")
local indicator_color = ui.new_color_picker("rage", "other", "Indicator color", 0, 255, 0, 255)

-- 添加指示器位置控件 - X轴和Y轴滑块
local screen_width, screen_height = client.screen_size()
local slider_indicator_x = ui.new_slider("rage", "other", "Indicator X", 0, screen_width, screen_width / 2, true, "px")
local slider_indicator_y = ui.new_slider("rage", "other", "Indicator Y", 0, screen_height, screen_height / 2 + 50, true, "px")

do -- config shit
	local update_ui = function()
		ui.set_visible(multiselect_shieldbot_hitboxes, ui.get(toggle_shieldbot))
		ui.set_visible(slider_shieldbot_angle_scale, ui.get(toggle_shieldbot))
		ui.set_visible(toggle_shieldbot_indicator, ui.get(toggle_shieldbot))
		ui.set_visible(slider_stop_ragebot_angle, ui.get(toggle_shieldbot))
		ui.set_visible(combobox_front_shield_action, ui.get(toggle_shieldbot))
		ui.set_visible(hotkey_toggle_action, ui.get(toggle_shieldbot))
		ui.set_visible(toggle_debug, ui.get(toggle_shieldbot))
		ui.set_visible(toggle_indicator, ui.get(toggle_shieldbot))
		ui.set_visible(indicator_color, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
		ui.set_visible(slider_indicator_x, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
		ui.set_visible(slider_indicator_y, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
		local list = ui.get(multiselect_shieldbot_hitboxes)
		if #list == 0 then
			ui.set(multiselect_shieldbot_hitboxes, { "Head" })
		end
	end
	client.set_event_callback("post_config_load", update_ui)
	ui.set_callback(multiselect_shieldbot_hitboxes, update_ui)
	ui.set_callback(toggle_shieldbot, update_ui)
	ui.set_callback(toggle_indicator, function()
		ui.set_visible(indicator_color, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
		ui.set_visible(slider_indicator_x, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
		ui.set_visible(slider_indicator_y, ui.get(toggle_shieldbot) and ui.get(toggle_indicator))
	end)
	update_ui()
end

-- 切换正面盾处理方式的函数
local function toggle_front_shield_action()
	local current_action = ui.get(combobox_front_shield_action)
	if current_action == "Head only" then
		ui.set(combobox_front_shield_action, "Disable ragebot")
	elseif current_action == "Disable ragebot" then
		ui.set(combobox_front_shield_action, "Feet only")
	else
		ui.set(combobox_front_shield_action, "Head only")
	end
end

-- 处理绑键切换
local hotkey_prev_state = false
client.set_event_callback("paint", function()
	if ui.get(toggle_shieldbot) then
		local hotkey_state = ui.get(hotkey_toggle_action)
		if hotkey_state and not hotkey_prev_state then
			toggle_front_shield_action()
		end
		hotkey_prev_state = hotkey_state
	end
end)

local fire_time, shieldbot_target = 0
local timeout = 2

client.set_event_callback("aim_fire", function(e)
	shieldbot_target = e.target
	fire_time = globals.curtime()
end)

client.set_event_callback("player_death", function(e)
	if shieldbot_target and e.userid == entity.get_steam64(shieldbot_target) then
		shieldbot_target = nil
	end
end)

-- 检查玩家是否举着盾牌
local function is_shield_deployed(player_index)
    local active_weapon = entity.get_prop(player_index, "m_hActiveWeapon")
    if not active_weapon then return false end
    
    -- 检查当前武器是否是盾牌
    if entity.get_classname(active_weapon) == "CWeaponShield" then
        return true
    end
    
    -- 检查玩家是否正在使用盾牌（通过观察者角度）
    local view_model = entity.get_prop(player_index, "m_hViewModel[0]")
    if view_model then
        local view_model_weapon = entity.get_prop(view_model, "m_hWeapon")
        if view_model_weapon and entity.get_classname(view_model_weapon) == "CWeaponShield" then
            return true
        end
    end
    
    return false
end

-- 存储玩家状态
local feet_flag_players = {}
local front_shield_players = {}

-- 计算角度差（返回0-180度的值）
local function calculate_angle_difference(angle1, angle2)
    local diff = math.abs(angle1 - angle2) % 360
    if diff > 180 then
        diff = 360 - diff
    end
    return diff
end

-- 更新玩家状态
local function update_player_states()
    feet_flag_players = {}
    front_shield_players = {}
    
    if not ui.get(toggle_shieldbot) then
        return
    end
    
    local local_player = entity.get_local_player()
    if not local_player then
        return
    end
    
    for player = 1, globals.maxplayers() do
        if entity.is_alive(player) and entity.is_enemy(player) then
            -- 检查玩家是否有盾牌
            local shield
            for i = 0, 63 do
                local weapon = entity.get_prop(player, "m_hMyWeapons", i)
                if weapon and entity.get_classname(weapon) == "CWeaponShield" then
                    shield = weapon
                    break
                end
            end
            
            if shield then
                -- 计算角度条件
                local local_position = vector(entity.get_origin(local_player))
                local x, y, z = entity.get_origin(player)
                if x then
                    local position = vector(x, y, z)
                    local _, angle_to_local = position:to(local_position):angles()
                    local shield_angle = get_abs_angles(get_client_entity(entitylist, shield))[1]
                    
                    -- 计算盾牌角度与玩家到本地玩家角度之间的差值
                    local angle_diff = calculate_angle_difference(shield_angle, angle_to_local)
                    
                    -- 检查玩家是否举着盾牌
                    local shield_deployed = is_shield_deployed(player)
                    
                    -- 获取停止ragebot的角度阈值
                    local stop_angle = ui.get(slider_stop_ragebot_angle)
                    
                    -- 当玩家举着盾牌且盾牌正对我们（角度差小）时，标记为正面盾
                    if shield_deployed and angle_diff <= stop_angle then
                        front_shield_players[player] = true
                    -- 如果玩家未举盾牌但在特定角度内，显示FEET标志
                    elseif not shield_deployed then
                        local mult = ui.get(slider_shieldbot_angle_scale)
                        local shield_angles = { 180 - mult, 180 + mult }
                        local angle_to = (shield_angle - angle_to_local) % 360
                        
                        if angle_to >= shield_angles[1] and angle_to <= shield_angles[2] then
                            feet_flag_players[player] = true
                        end
                    end
                end
            end
        end
    end
end

-- 注册ESP标志函数
local function should_show_feet_flag(player)
    return feet_flag_players[player] == true and ui.get(toggle_shieldbot_indicator)
end

-- 注册ESP标志
client.register_esp_flag('FEET', 255, 255, 0, should_show_feet_flag)

-- 正面盾标志函数
local function should_show_front_shield_flag(player)
    return front_shield_players[player] == true
end

-- 注册正面盾标志 - 改为ACTIVE
client.register_esp_flag('ACTIVE', 255, 0, 0, should_show_front_shield_flag)

-- 存储原始状态
local original_rage_state = true
local is_rage_disabled = false

-- 绘制指示器
local function draw_indicator()
    if not ui.get(toggle_shieldbot) or not ui.get(toggle_indicator) then
        return
    end
    
    local x = ui.get(slider_indicator_x)
    local y = ui.get(slider_indicator_y)
    local current_action = ui.get(combobox_front_shield_action)
    local r, g, b, a = ui.get(indicator_color)
    
    -- 移除"Shield: "前缀
    local text = current_action
    
    -- 如果有正面盾玩家且不是Feet only模式，添加ACTIVE指示
    local has_front_shield = false
    for player_idx, _ in pairs(front_shield_players) do
        has_front_shield = true
        break
    end
    
    if has_front_shield and current_action ~= "Feet only" then
        text = text .. " [ACTIVE]"
    end
    
    -- 绘制模式文本
    renderer.text(x, y, r, g, b, a, "", 0, text)
    
    -- 检查是否有背身大盾玩家（未举起盾牌但在特定角度内）
    local has_back_shield = false
    for player_idx, _ in pairs(feet_flag_players) do
        has_back_shield = true
        break
    end
    
    -- 如果有背身大盾玩家，绘制脚部指示
    if has_back_shield then
        renderer.text(x, y + 15, 255, 255, 0, a, "", 0, "FEET")
    end
end

client.set_event_callback("paint", function()
    -- 更新玩家状态
    update_player_states()
    
    -- 绘制指示器
    draw_indicator()
    
	local curtime = globals.curtime()
	if curtime - fire_time > timeout then
		fire_time = 0
	end
	local local_player = entity.get_local_player()
	if ui.get(toggle_shieldbot) and local_player then
		local local_position = vector(entity.get_origin(local_player))
		local shield
		local player = shieldbot_target
		if fire_time < curtime or not shieldbot_target or not entity.is_alive(shieldbot_target) then
			for i = 1, globals.maxplayers() do
				local esp_data = entity.get_esp_data(i)
				if esp_data and bit.band(esp_data.flags, 2048) ~= 0 then
					player = i
				end
			end
		end
		
		-- 检查是否需要处理正面盾
		local has_front_shield = false
		for player_idx, _ in pairs(front_shield_players) do
			has_front_shield = true
			break
		end
		
		-- 根据选项处理正面盾
		local front_shield_action = ui.get(combobox_front_shield_action)
		if has_front_shield then
			if front_shield_action == "Disable ragebot" and not is_rage_disabled then
				-- 禁用ragebot
				original_rage_state = ui.get(rage_enabled)
				ui.set(rage_enabled, false)
				is_rage_disabled = true
			elseif front_shield_action == "Head only" then
				-- 只锁头，确保ragebot启用
				if is_rage_disabled then
					ui.set(rage_enabled, original_rage_state)
					is_rage_disabled = false
				end
				-- 设置目标命中部位为头部
				ui.set(multiselect_target_hitbox, { "Head" })
			elseif front_shield_action == "Feet only" then
				-- 只锁脚，确保ragebot启用
				if is_rage_disabled then
					ui.set(rage_enabled, original_rage_state)
					is_rage_disabled = false
				end
				-- 设置目标命中部位为脚部
				ui.set(multiselect_target_hitbox, { "Feet" })
			end
		else
			-- 没有正面盾时恢复原始状态
			if is_rage_disabled then
				ui.set(rage_enabled, original_rage_state)
				is_rage_disabled = false
			end
		end
		
		-- 调试绘制：为所有有盾牌的敌人绘制角度线
		if ui.get(toggle_debug) then
			for i = 1, globals.maxplayers() do
				if entity.is_alive(i) and entity.is_enemy(i) then
					local shield_found = false
					for j = 0, 63 do
						local k = entity.get_prop(i, "m_hMyWeapons", j)
						if k and entity.get_classname(k) == "CWeaponShield" then
							shield_found = k
							break
						end
					end
					
					if shield_found then
						local x, y, z = entity.get_origin(i)
						if x then
							local position = vector(x, y, z)
							local _, angle_to_local = position:to(local_position):angles()
							local shield_angle = get_abs_angles(get_client_entity(entitylist, shield_found))[1]
							
							-- 计算角度差
							local angle_diff = calculate_angle_difference(shield_angle, angle_to_local)
							local stop_angle = ui.get(slider_stop_ragebot_angle)
							local shield_deployed = is_shield_deployed(i)
							
							-- 绘制盾牌方向线
							local angle_rad = math.rad(shield_angle)
							local end_x = x + math.cos(angle_rad) * 50
							local end_y = y + math.sin(angle_rad) * 50
							
							local x1, y1 = renderer.world_to_screen(x, y, z)
							local x2, y2 = renderer.world_to_screen(end_x, end_y, z)
							
							if x1 and x2 then
								-- 根据是否正面盾选择颜色
								local r, g, b = 0, 255, 0  -- 默认绿色
								if shield_deployed and angle_diff <= stop_angle then
									r, g, b = 255, 0, 0  -- 红色表示正面盾
								end
								
								renderer.line(x1, y1, x2, y2, r, g, b, 255)
								
								-- 绘制角度差文本
								local text_x, text_y = renderer.world_to_screen(x, y, z + 10)
								if text_x then
									renderer.text(text_x, text_y, 255, 255, 255, 255, "c", 0, string.format("Diff: %.1f", angle_diff))
								end
							end
						end
					end
				end
			end
		end
		
		-- 处理侧面盾（未举起）的情况
		if player and not front_shield_players[player] then
			for i = 0, 63 do
				local k = entity.get_prop(player, "m_hMyWeapons", i)
				if k and entity.get_classname(k) == "CWeaponShield" then
					shield = k
					break
				end
			end
			if shield then
				local x, y, z = entity.get_origin(player)
				local position = vector(x,y,z)
				local _, angle_to_local = position:to(local_position):angles()
				local shield_angle = get_abs_angles(get_client_entity(entitylist, shield))[1]
				
				-- 计算角度差
				local angle_diff = calculate_angle_difference(shield_angle, angle_to_local)
				
				-- 获取停止ragebot的角度阈值
				local stop_angle = ui.get(slider_stop_ragebot_angle)
				
				-- 检查玩家是否举着盾牌
				local shield_deployed = is_shield_deployed(player)
				
				-- 原来的打脚逻辑（只对非正面盾玩家生效）
				local mult = (ui.get(slider_shieldbot_angle_scale))
				local shield_angles = { 180 - mult, 180 + mult }
				local angle_to = (shield_angle - angle_to_local) % 360
				
				if not shield_deployed and (angle_to >= shield_angles[1] and angle_to <= shield_angles[2]) then
					-- 只有当玩家装备盾牌但未举起且在角度内时才打脚
					ui.set(multiselect_target_hitbox, { "Feet" })
				else
					ui.set(multiselect_target_hitbox, ui.get(multiselect_shieldbot_hitboxes))
				end
			else
				ui.set(multiselect_target_hitbox, ui.get(multiselect_shieldbot_hitboxes))
			end
		end
	else
		-- 如果功能关闭，确保ragebot状态恢复
		if is_rage_disabled then
			ui.set(rage_enabled, original_rage_state)
			is_rage_disabled = false
		end
	end
end)

-- 确保在脚本卸载时恢复ragebot状态
client.set_event_callback("shutdown", function()
    if is_rage_disabled then
        ui.set(rage_enabled, original_rage_state)
    end
end)