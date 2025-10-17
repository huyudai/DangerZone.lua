---从AIMWARE迁移到Gamesense上 此版本未经长期测试 不稳定
local ref = ui.new_checkbox("VISUALS", "Other ESP", "Show Danger Zone Final Circle")

client.set_event_callback("paint", function()
    if not ui.get(ref) then return end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end

    local controllers = entity.get_all("CDangerZoneController")
    if not controllers or #controllers == 0 then return end

    local end_pos = {x = 0, y = 0, z = 0}
    local found = false

    for i = 1, #controllers do
        local dz = controllers[i]
        if dz and entity.get_prop(dz, "m_bDangerZoneControllerEnabled") == 1 then
            end_pos.x = entity.get_prop(dz, "m_vecEndGameCircleStart", 0) or 0
            end_pos.y = entity.get_prop(dz, "m_vecEndGameCircleStart", 1) or 0
            end_pos.z = entity.get_prop(dz, "m_vecEndGameCircleStart", 2) or 0
            found = true
            break
        end
    end

    if not found then return end

    local lp_pos = {
        x = entity.get_prop(lp, "m_vecOrigin", 0) or 0,
        y = entity.get_prop(lp, "m_vecOrigin", 1) or 0,
        z = entity.get_prop(lp, "m_vecOrigin", 2) or 0
    }

    local dx = end_pos.x - lp_pos.x
    local dy = end_pos.y - lp_pos.y
    local dzv = end_pos.z - lp_pos.z
    local dist = math.sqrt(dx * dx + dy * dy + dzv * dzv)

    -- HUD 显示
    local sw, sh = client.screen_size()
    renderer.text(sw / 2, sh - 80, 255, 255, 255, 255, "c", 0,
        string.format("🧭 End Zone Distance: %.0f", dist))

    -- 圈中心红十字
    local sx, sy = renderer.world_to_screen(end_pos.x, end_pos.y, end_pos.z)
    if sx and sy then
        renderer.line(sx - 10, sy, sx + 10, sy, 255, 0, 0, 255)
        renderer.line(sx, sy - 10, sx, sy + 10, 255, 0, 0, 255)
    end
end)
