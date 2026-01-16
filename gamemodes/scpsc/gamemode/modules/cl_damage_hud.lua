--[[-------------------------------------------------------------------------
Hit marker
---------------------------------------------------------------------------]]
local hitmarker = 0
function ShowHitMarker()
    if GetSettingsValue("hud_hitmarker") then
        hitmarker = 255
        if GetSettingsValue("hud_hitmarker_mute") then return end
        timer.Simple(0.05, function() surface.PlaySound("scp_lc/misc/hitmarker.ogg") end)
    end
end

--[[-------------------------------------------------------------------------
Damage indicator
---------------------------------------------------------------------------]]
local mat_full_dmg_ind = Material("slc/hud/full_dmg_ind.png", "smooth")
local mat_dmg_ind = Material("slc/hud/dmg_ind.png", "smooth")
local full_dmg_a = 0
local ind_list
local indicator_duration = 1.5
local indicator_max = 16
local ind_mid = 50
local ind_min = 0.5
local ind_max = 2
function ShowDamageIndicator(dmg, dx, dy)
    if not GetSettingsValue("hud_damage_indicator") then return end
    if not ind_list then ind_list = List() end
    if dx == 0 and dy == 0 then
        full_dmg_a = full_dmg_a + dmg / LocalPlayer():GetMaxHealth() * 255
    else
        full_dmg_a = full_dmg_a + dmg / LocalPlayer():GetMaxHealth() * 32
        local rt = RealTime()
        local len = math.sqrt(dx * dx + dy * dy)
        local x, y = dx / len, dy / len
        local tail = ind_list:Tail()
        if tail and tail.x == x and tail.y == y then
            tail.dietime = rt + math.Clamp(tail.dietime - rt + dmg / ind_mid * indicator_duration, indicator_duration * ind_min, indicator_duration * ind_max)
        else
            if ind_list:Size() >= indicator_max then ind_list:PopFront() end
            ind_list:PushBack({
                x = x,
                y = y,
                dietime = rt + indicator_duration * math.Clamp(dmg / ind_mid, ind_min, ind_max)
            })
        end
    end

    if full_dmg_a > 255 then full_dmg_a = 255 end
end

hook.Add("SLCPostDrawHUD", "SLCDamage", function()
    if hitmarker > 0 then
        local w, h = ScrW(), ScrH()
        local cx, cy = w / 2, h / 2
        local d = h * 0.01
        local l = h * 0.01
        local rot_mx = Matrix()
        rot_mx:Translate(Vector(cx, cy, 0))
        rot_mx:Rotate(Angle(0, 45, 0))
        rot_mx:Translate(Vector(-cx, -cy, 0))
        cam.PushModelMatrix(rot_mx)
        surface.SetDrawColor(255, 255, 255, hitmarker)
        surface.DrawRect(cx - d - l, cy - 1, l, 1)
        surface.DrawRect(cx + d, cy - 1, l, 1)
        surface.DrawRect(cx - 1, cy - d - l, 1, l)
        surface.DrawRect(cx - 1, cy + d, 1, l)
        surface.SetDrawColor(0, 0, 0, hitmarker)
        surface.DrawOutlinedRect(cx - d - l - 1, cy - 2, l + 2, 3)
        surface.DrawOutlinedRect(cx + d - 1, cy - 2, l + 2, 3)
        surface.DrawOutlinedRect(cx - 2, cy - d - l - 1, 3, l + 2)
        surface.DrawOutlinedRect(cx - 2, cy + d - 1, 3, l + 2)
        cam.PopModelMatrix()
        hitmarker = math.Approach(hitmarker, 0, RealFrameTime() * 900)
    end

    if full_dmg_a > 0 then
        surface.SetMaterial(mat_full_dmg_ind)
        surface.SetDrawColor(225, 0, 0, full_dmg_a)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        full_dmg_a = math.Approach(full_dmg_a, 0, RealFrameTime() * 100)
    end

    if ind_list and ind_list:Size() > 0 then
        local w, h = ScrW(), ScrH()
        local cx, cy = w / 2, h / 2
        local rt = RealTime()
        local eye_ang = LocalPlayer():EyeAngles().y
        if eye_ang < 0 then eye_ang = 360 + eye_ang end
        if ind_list:Head().dietime <= rt then ind_list:PopFront() end
        surface.SetMaterial(mat_dmg_ind)
        for item in ind_list:Iter() do
            local ang = math.atan2(item.y, item.x) - math.rad(eye_ang)
            local alpha = (item.dietime - rt) / indicator_duration
            surface.SetDrawColor(175, 0, 0, alpha * 255)
            local r = h * 0.33
            surface.DrawTexturedRectRotated(cx - math.sin(ang) * r, cy - math.cos(ang) * r, h * 0.2, h * 0.2, math.deg(ang) + 180)
            --surface.SetDrawColor( 255, 255, 255, 255 )
            --surface.DrawTexturedRectRotated( cx - math.sin( ang ) * r, cy - math.cos( ang ) * r, 16, 16, 0 )
        end
    end
end)

--[[-------------------------------------------------------------------------
Damage numbers (floating damage text when dealing damage)
---------------------------------------------------------------------------]]
local dmg_numbers = {}
local dmg_number_duration = 1.5
local dmg_number_max = 16
local dmg_number_rise_speed = 50
function ShowDamageNumber(dmg, pos)
    if not GetSettingsValue("hud_damage_numbers") then return end
    if #dmg_numbers >= dmg_number_max then table.remove(dmg_numbers, 1) end
    -- Add slight random offset to prevent overlap
    local offset = Vector(math.random(-15, 15), math.random(-15, 15), math.random(0, 10))
    table.insert(dmg_numbers, {
        dmg = math.ceil(dmg),
        pos = pos + offset,
        start_time = RealTime(),
        die_time = RealTime() + dmg_number_duration,
    })
end

hook.Add("SLCPostDrawHUD", "SLCDamageNumbers", function()
    if #dmg_numbers == 0 then return end
    if not GetSettingsValue("hud_damage_numbers") then return end
    local rt = RealTime()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    -- Remove expired entries
    while #dmg_numbers > 0 and dmg_numbers[1].die_time <= rt do
        table.remove(dmg_numbers, 1)
    end

    for _, data in ipairs(dmg_numbers) do
        local elapsed = rt - data.start_time
        local alpha = math.Clamp((data.die_time - rt) / dmg_number_duration, 0, 1)
        -- Calculate floating position (rises over time)
        local rise_offset = Vector(0, 0, elapsed * dmg_number_rise_speed)
        local world_pos = data.pos + rise_offset
        -- Convert to screen coordinates
        local scr = world_pos:ToScreen()
        if not scr.visible then continue end
        -- Scale based on distance
        local dist = world_pos:Distance(ply:EyePos())
        local scale = math.Clamp(1 - (dist / 2000), 0.5, 1.5)
        -- Draw damage number with outline
        local text = tostring(data.dmg)
        local font = "SCPHUDMedium"
        local text_alpha = alpha * 255
        -- Background/outline for readability
        surface.SetFont(font)
        local tw, th = surface.GetTextSize(text)
        tw = tw * scale
        th = th * scale
        -- Draw shadow/outline
        draw.SimpleTextOutlined(text, font, scr.x, scr.y, Color(255, 100, 100, text_alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, text_alpha * 0.8))
    end
end)

hook.Add("SLCRegisterSettings", "SLCSCPDamageHUDSettings", function()
    RegisterSettingsEntry("hud_hitmarker", "switch", true, nil, "hud_config")
    RegisterSettingsEntry("hud_hitmarker_mute", "switch", false, nil, "hud_config")
    RegisterSettingsEntry("hud_damage_indicator", "switch", true, nil, "hud_config")
    RegisterSettingsEntry("hud_damage_numbers", "switch", true, nil, "hud_config")
end)
