-- Configurations
local CONFIG = {
    fontSmall = "deathscreen_small",
    fontLarge = "deathscreen_large",
    respawnCooldown = 5, -- Seconds before respawn is allowed
    wastedText = "WASTED",
    respawnText = "Press [SPACE] to respawn",
    countdownText = "Respawn in %d seconds",
    fadeSpeed = 1.5, -- Speed of fade transitions
    fieldOfViewModifier = 0.85, -- FOV effect on death
}

-- Font Definitions
surface.CreateFont(CONFIG.fontSmall, { font = "Roboto", size = 24, weight = 1000 })
surface.CreateFont(CONFIG.fontLarge, { font = "Roboto", size = 90, weight = 1000 })

-- Local Variables
local state = {
    isDead = false,
    deathTime = 0,
    respawnAllowed = false,
    alpha = 0, -- For fade-in and fade-out effects
}

-- Helper Functions
local function GetDeathDuration()
    return CurTime() - state.deathTime
end

local function SetDeathState(isDead)
    state.isDead = isDead
    state.deathTime = isDead and CurTime() or 0
    state.respawnAllowed = false
    state.alpha = isDead and 0 or state.alpha -- Reset alpha when state changes
end

-- Server Communication Handlers
net.Receive("deathscreen_sendDeath", function()
    SetDeathState(true)
end)

net.Receive("deathscreen_removeDeath", function()
    SetDeathState(false)
end)

-- Screen Effects
hook.Add("RenderScreenspaceEffects", "DeathScreenEffects", function()
    if not state.isDead then return end

    local deathDuration = GetDeathDuration()
    local desaturation = math.Clamp(1 - deathDuration * 0.1, 0, 1)

    DrawColorModify({
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.02,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = desaturation,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0,
    })
end)

-- HUD Drawing
hook.Add("HUDPaint", "DeathScreenHUD", function()
    if not state.isDead then return end

    local alpha = math.Clamp(state.alpha, 0, 255)
    state.alpha = math.Approach(state.alpha, 255, CONFIG.fadeSpeed) -- Smooth fade-in

    -- Draw WASTED text
    draw.SimpleText(CONFIG.wastedText, CONFIG.fontLarge, ScrW() / 2, ScrH() / 2, Color(255, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Respawn Countdown
    local respawnTime = math.Clamp(CONFIG.respawnCooldown - GetDeathDuration(), 0, CONFIG.respawnCooldown)
    local respawnText = respawnTime > 0
        and string.format(CONFIG.countdownText, math.ceil(respawnTime))
        or CONFIG.respawnText

    draw.SimpleText(respawnText, CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Enable respawn after countdown
    if respawnTime <= 0 then
        state.respawnAllowed = true
    end
end)

-- Respawn Logic
hook.Add("Think", "DeathScreenRespawnHandler", function()
    if state.isDead and state.respawnAllowed and input.IsKeyDown(KEY_SPACE) then
        net.Start("deathscreen_requestRespawn")
        net.SendToServer()
        state.respawnAllowed = false -- Prevent spamming respawn
    end
end)

-- Camera Effects
hook.Add("CalcView", "DeathScreenView", function(ply, origin, angles, fov)
    if not state.isDead then return end

    return {
        origin = origin,
        angles = angles,
        fov = fov * CONFIG.fieldOfViewModifier,
    }
end)
