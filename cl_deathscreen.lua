-- Configurations
local CONFIG = {
    fontSmall = "deathscreen_small",
    fontLarge = "deathscreen_large",
    respawnCooldown = 5, -- Seconds before respawn is allowed
    wastedText = "WASTED",
    respawnText = "Press [SPACE] to respawn",
    countdownText = "Respawn in %d seconds",
    fadeSpeed = 300, -- Speed of fade transitions (adjusted for FrameTime)
    fieldOfViewModifier = 0.85, -- FOV effect on death
    autoRespawnAI = true -- Enables AI-based respawn logic
}

-- Font Definitions
surface.CreateFont(CONFIG.fontSmall, { font = "Roboto", size = 24, weight = 1000 })
surface.CreateFont(CONFIG.fontLarge, { font = "Roboto", size = 90, weight = 1000 })

-- State Management
local state = {
    isDead = false,
    deathTime = 0,
    alpha = 0,
    canRespawn = false
}

-- Helper Functions
local function GetTimeSinceDeath()
    return CurTime() - state.deathTime
end

local function SetDeathState(isDead)
    state.isDead = isDead
    state.deathTime = isDead and CurTime() or 0
    state.alpha = 0
    state.canRespawn = false
end

-- AI-Based Respawn Decision
local function AIShouldRespawn()
    if not CONFIG.autoRespawnAI then return false end
    return math.random() > 0.3 -- 70% chance to auto-respawn
end

-- Network Message Handling
net.Receive("deathscreen_sendDeath", function()
    SetDeathState(true)
end)

net.Receive("deathscreen_removeDeath", function()
    SetDeathState(false)
end)

-- Screen Effects
hook.Add("RenderScreenspaceEffects", "DeathScreenEffects", function()
    if not state.isDead then return end

    local desaturation = math.Clamp(1 - GetTimeSinceDeath() * 0.1, 0, 1)

    DrawColorModify({
        ["$pp_colour_colour"] = desaturation
    })
end)

-- HUD Drawing
hook.Add("HUDPaint", "DeathScreenHUD", function()
    if not state.isDead then return end

    -- Smooth fade-in effect
    state.alpha = math.Approach(state.alpha, 255, CONFIG.fadeSpeed * FrameTime())

    -- Draw "WASTED" text
    draw.SimpleText(CONFIG.wastedText, CONFIG.fontLarge, ScrW() / 2, ScrH() / 2, Color(255, 0, 0, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Respawn Countdown
    local remainingTime = math.Clamp(CONFIG.respawnCooldown - GetTimeSinceDeath(), 0, CONFIG.respawnCooldown)
    if remainingTime == 0 then
        state.canRespawn = true
        draw.SimpleText(CONFIG.respawnText, CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format(CONFIG.countdownText, math.ceil(remainingTime)), CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Respawn Logic
hook.Add("Think", "DeathScreenRespawnHandler", function()
    if state.isDead and state.canRespawn then
        if input.IsKeyDown(KEY_SPACE) or AIShouldRespawn() then
            net.Start("deathscreen_requestRespawn")
            net.SendToServer()
            state.canRespawn = false -- Prevent multiple sends
        end
    end
end)

-- Camera Effects
hook.Add("CalcView", "DeathScreenView", function(ply, origin, angles, fov)
    if state.isDead then
        return {
            origin = origin,
            angles = angles,
            fov = fov * CONFIG.fieldOfViewModifier
        }
    end
end)
