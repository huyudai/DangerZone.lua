local hitsounds = {
    "-",
    "Default",
    "Kevlar damage",
    "Bag damage",
    "Zone select",
    "Bell",
    "Beep",
    "Flesh",
    "Concrete",
    "Glass (Hard)",
    "Glass (Soft)",
    "Metal (Hard)",
    "Metal (Soft)",
    "Shield",
    "Custom 1 (MP3)",
    "Custom 2 (MP3)"
}

local misssounds = {
    "-",
    "LUA error",
    "Error", 
    "Fail", 
    "Warning", 
    "Contract", 
    "Select",
    "Deny device",
    "Custom (MP3)"
}

local ui_enable         = ui.new_checkbox("LUA", "A", "Custom hitsound")
local ui_volume         = ui.new_slider("LUA", "A", "Volume", 0, 100, 100, true, "%")
local ui_hitsound_head  = ui.new_combobox("LUA", "A", "Head", hitsounds)
local ui_hitsound_body  = ui.new_combobox("LUA", "A", "Body", hitsounds)
local ui_miss_sound     = ui.new_combobox("LUA", "A", "Miss", misssounds)
local ui_play_shell     = ui.new_checkbox("LUA", "A", "Play shell drop sound")

local playvol = cvar.playvol

local vol = "1"
ui.set_callback(ui_volume, function()
    vol = tostring(ui.get(ui_volume)*0.01)
end)

--format:
--path (without extension)
--randomization/function (if there is more than one file)
--file type extension (.wav, .mp3)
local impacts = {
    ["Default"] = {
        file_path = "buttons\\arena_switch_press_02",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Kevlar damage"] = {
        file_path = "player\\kevlar",
        file_number = function() 
            return math.random(1,5)
        end,
        file_type = ".wav"
    },
    ["Bag damage"] = {
        file_path = "survival\\bag_damage_0",
        file_number = function()
            return math.random(1,4)
        end,
        file_type = ".wav"
    },
    ["Zone select"] = {
        file_path = "survival\\zone_chosen_by_other",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Bell"] = {
        file_path = "training\\bell_normal",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Beep"] = {
        file_path = "ui\\armsrace_kill_01",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Flesh"] = {
        file_path = "physics\\flesh\\flesh_impact_bullet",
        file_number = function()
            return math.random(1,5)
        end,
        file_type = ".wav"
    },
    ["Concrete"] = {
        file_path = "physics\\concrete\\concrete_block_impact_hard",
        file_number = function()
            return math.random(1,3)
        end,
        file_type = ".wav"
    },
    ["Glass (Hard)"] = {
        file_path = "physics\\glass\\glass_sheet_impact_hard",
        file_number = function()
            return math.random(1,3)
        end,
        file_type = ".wav"
    },
    ["Glass (Soft)"] = {
        file_path = "physics\\glass\\glass_sheet_impact_soft",
        file_number = function()
            return math.random(1,3)
        end,
        file_type = ".wav"
    },
    ["Metal (Hard)"] = {
        file_path = "physics\\metal\\metal_solid_impact_bullet",
        file_number = function()
            return math.random(1,4)
        end,
        file_type = ".wav"
    },
    ["Metal (Soft)"] = {
        file_path = "physics\\metal\\metal_solid_impact_soft",
        file_number = function()
            return math.random(1,3)
        end,
        file_type = ".wav"
    },
    ["Shield"] = {
        file_path = "physics\\shield\\bullet_hit_shield_0",
        file_number = function()
            return math.random(1,7)
        end,
        file_type = ".wav"
    },
    ["Custom 1 (MP3)"] = {
        file_path = "*hitsounds\\headshot1",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Custom 2 (MP3)"] = {
        file_path = "*hitsounds\\headshot2",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },

    --use this if you want to add more
    [""] = {
        file_path = "",
        file_number = function()
            return ""
        end,
        file_type = ""
    },
}

local misses = {
    ["LUA error"] = {
        file_path = "ui\\weapon_cant_buy",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Error"] = {
        file_path = "error",
        file_number = function() 
            return ""
        end,
        file_type = ".wav"
    },
    ["Fail"] = {
        file_path = "training\\puck_fail",
        file_number = function() 
            return ""
        end,
        file_type = ".wav"
    },
    ["Warning"] = {
        file_path = "resource\\warning",
        file_number = function() 
            return ""
        end,
        file_type = ".wav"
    },
    ["Contract"] = {
        file_path = "ui\\csgo_ui_contract_type",
        file_number = function()
            return math.random(1,10)
        end,
        file_type = ".wav"
    },
    ["Select"] = {
        file_path = "ui\\csgo_ui_store_select",
        file_number = function() 
            return ""
        end,
        file_type = ".wav"
    },
    ["Deny device"] = {
        file_path = "player\\suit_denydevice",
        file_number = function()
            return ""
        end,
        file_type = ".wav"
    },
    ["Custom (MP3)"] = {
        file_path = "*\\misssound",
        file_number = function()
            return ""
        end,
        file_type = ".mp3"
    },
    
    
    --use this if you want to add more
    [""] = {
        file_path = "",
        file_number = function()
            return ""
        end,
        file_type = ""
    },
}

local function playsound(command)
    if command ~= nil then
        playvol:invoke_callback(command.file_path..command.file_number()..command.file_type, vol)
    end
    if ui.get(ui_play_shell) then
        client.delay_call(0.2, function() playvol:invoke_callback("player\\pl_shell"..tostring(math.random(1,3))..".wav", vol) end)
    end
end

client.set_event_callback("aim_hit", function(e)
    if ui.get(ui_enable) then
        if e.hitgroup == 1 then
            playsound(impacts[ui.get(ui_hitsound_head)])
        else
            playsound(impacts[ui.get(ui_hitsound_body)])
        end
    end
end)

client.set_event_callback("aim_miss", function(e)
    if ui.get(ui_enable) then
        playsound(misses[ui.get(ui_miss_sound)])
    end
end)

local function setup()
    local state = ui.get(ui_enable)
    if state then
        ui.set(ui.reference("VISUALS", "Player ESP", "Hit marker sound"), false)
    end
    ui.set_visible(ui_volume, state)
    ui.set_visible(ui_hitsound_head, state)
    ui.set_visible(ui_hitsound_body, state)
    ui.set_visible(ui_miss_sound, state)
    ui.set_visible(ui_play_shell, state)
end
ui.set_callback(ui_enable, setup)
setup()