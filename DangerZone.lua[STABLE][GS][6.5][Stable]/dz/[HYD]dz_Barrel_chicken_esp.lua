local get_prop, get_all = entity.get_prop, entity.get_all
local world_screen, draw_text = renderer.world_to_screen, renderer.text
local ui_get = ui.get

local ChickenEsp = ui.new_checkbox("LUA", "A", "Chicken ESP")
local ChickenClr = ui.new_color_picker("LUA", "A", "ChickenColor", 0, 242, 255)
local BarrelEsp  = ui.new_checkbox("LUA", "A", "Barrel ESP")
local BarrelClr  = ui.new_color_picker("LUA", "A", "BarrelColor", 0, 255, 149)

client.set_event_callback("paint", function()
    if ui_get(ChickenEsp) then
        for _, entity in pairs(get_all("CChicken")) do
            local X, Y, Z    = get_prop(entity, "m_vecOrigin")
            local WX, WY     = world_screen(X, Y, Z)
            local R, G, B, A = ui_get(ChickenClr)
            draw_text(WX, WY, R, G, B, A, "-", 999, "C")
        end
    end

    if ui_get(BarrelEsp) then
        for _, entity in pairs(get_all("CPhysicsProp")) do
            if client.get_model_name(get_prop(entity, "m_nModelIndex")) == "models/props/coop_cementplant/exloding_barrel/exploding_barrel.mdl" then
                local X2, Y2, Z2     = get_prop(entity, "m_vecOrigin")
                local WX2, WY2       = world_screen(X2, Y2, Z2)
                local R2, G2, B2, A2 = ui_get(BarrelClr)
                draw_text(WX2, WY2, R2, G2, B2, A2, "-", 999, "E")
            end
        end
    end
end)