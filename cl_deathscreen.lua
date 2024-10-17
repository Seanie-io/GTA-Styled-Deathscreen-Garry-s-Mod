-- Fonts for the death screen
surface.CreateFont("tutorial_24", {
    font = "Roboto",
    size = 24,
    weight = 1000,
})

surface.CreateFont("tutorial_90", {
    font = "Roboto",
    size = 90,
    weight = 1000,
})

-- Variables to track death state and visual effects
local isDead = false
local deathTime = 0
local respawnAllowed = false

-- Handle receiving the death notification from the server
net.Receive("deathscreen_sendDeath", function()
    isDead = true
    deathTime = CurTime() -- Get the current time when death happens
    respawnAllowed = false -- Disable respawning initially
end)

-- Remove the death screen on respawn
net.Receive("deathscreen_removeDeath", function()
    isDead = false
    respawnAllowed = false
end)

-- Apply screen color modifications for a dramatic death effect
hook.Add("RenderScreenspaceEffects", "DeathScreenColorMods", function()
    if isDead then
        local deathDuration = CurTime() - deathTime
        local colorMod = {}
        colorMod["$pp_colour_addr"] = 0
        colorMod["$pp_colour_addg"] = 0
        colorMod["$pp_colour_addb"] = 0
        colorMod["$pp_colour_brightness"] = -0.02 -- Slight darkening effect
        colorMod["$pp_colour_contrast"] = 1
        colorMod["$pp_colour_colour"] = math.Clamp(1 - deathDuration * 0.1, 0, 1) -- Slowly desaturate the screen
        colorMod["$pp_colour_mulr"] = 0
        colorMod["$pp_colour_mulg"] = 0
        colorMod["$pp_colour_mulb"] = 0
        DrawColorModify(colorMod)
    end
end)

-- Draw the GTA style "WASTED" text on screen
hook.Add("HUDPaint", "DrawDeathScreen", function()
    if isDead then
        -- Time passed since death
        local deathDuration = CurTime() - deathTime

        -- Draw WASTED text
        draw.SimpleText("WASTED", "tutorial_90", ScrW() / 2, ScrH() / 2, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Countdown message to allow respawn
        local respawnTime = math.Clamp(5 - deathDuration, 0, 5) -- Countdown from 5 seconds
        if respawnTime > 0 then
            draw.SimpleText("Respawn in " .. math.ceil(respawnTime) .. " seconds", "tutorial_24", ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Press [SPACE] to respawn", "tutorial_24", ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            respawnAllowed = true -- Allow respawn after countdown
        end
    end
end)

-- Check for spacebar press to respawn the player
hook.Add("Think", "DeathscreenRespawnHandler", function()
    if isDead and respawnAllowed and input.IsKeyDown(KEY_SPACE) then
        net.Start("deathscreen_requestRespawn") -- Send a request to the server to respawn the player
        net.SendToServer()
        respawnAllowed = false -- Prevent multiple respawns
    end
end)

-- Camera effect for a slow motion view after death
hook.Add("CalcView", "DeathscreenCalcView", function(ply, origin, angles, fov, znear, zfar)
    if isDead then
        local view = {}
        view.origin = origin
        view.angles = angles
        view.fov = fov * 0.85 -- Narrower field of view
        return view
    end
end)
