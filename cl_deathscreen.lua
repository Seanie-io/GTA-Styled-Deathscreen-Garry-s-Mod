-- Configurations
local CONFIG = {
    fontSmall = "deathscreen_small",
    fontLarge = "deathscreen_large",
    respawnCooldown = 5, 
    wastedTexts = {
        "You were killed by %s.",
        "%s took you down.",
        "%s ended your run.",
        "Defeated by %s and their %s."
    },
    respawnText = "Press [SPACE] to respawn",
    countdownText = "Respawn in %d seconds",
    fadeSpeed = 300, 
    fieldOfViewModifier = 0.85, 
    autoRespawnAI = true,
    deathStreakMessages = {
        [3] = "You've died 3 times in a row! Try dodging?",
        [5] = "Five deaths... Need a break?",
        [7] = "Maybe you're just unlucky?"
    }
}

-- Font Definitions
surface.CreateFont(CONFIG.fontSmall, { font = "Roboto", size = 24, weight = 1000 })
surface.CreateFont(CONFIG.fontLarge, { font = "Roboto", size = 90, weight = 1000 })

-- State Management
local state = {
    isDead = false,
    deathTime = 0,
    alpha = 0,
    canRespawn = false,
    killer = "",
    weapon = "",
    deathStreak = 0
}

local function GetTimeSinceDeath()
    return CurTime() - state.deathTime
end

local function SetDeathState(isDead, killer, weapon, streak)
    state.isDead = isDead
    state.deathTime = isDead and CurTime() or 0
    state.alpha = 0
    state.canRespawn = false
    state.killer = killer or ""
    state.weapon = weapon or ""
    state.deathStreak = streak or 0
end

local function AIShouldRespawn()
    if not CONFIG.autoRespawnAI then return false end
    return math.random() > 0.3
end

-- Network Messages
net.Receive("deathscreen_sendDeath", function()
    local killer = net.ReadString()
    local weapon = net.ReadString()
    local streak = net.ReadInt(8)
    SetDeathState(true, killer, weapon, streak)
end)

net.Receive("deathscreen_removeDeath", function()
    SetDeathState(false)
end)

-- Screen Effects
hook.Add("RenderScreenspaceEffects", "DeathScreenEffects", function()
    if not state.isDead then return end
    local desaturation = math.Clamp(1 - GetTimeSinceDeath() * 0.1, 0, 1)
    DrawColorModify({ ["$pp_colour_colour"] = desaturation })
end)

-- HUD Drawing
hook.Add("HUDPaint", "DeathScreenHUD", function()
    if not state.isDead then return end
    state.alpha = math.Approach(state.alpha, 255, CONFIG.fadeSpeed * FrameTime())

    local message = string.format(table.Random(CONFIG.wastedTexts), state.killer, state.weapon)
    draw.SimpleText(message, CONFIG.fontLarge, ScrW() / 2, ScrH() / 2, Color(255, 0, 0, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if CONFIG.deathStreakMessages[state.deathStreak] then
        draw.SimpleText(CONFIG.deathStreakMessages[state.deathStreak], CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 50, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local remainingTime = math.Clamp(CONFIG.respawnCooldown - GetTimeSinceDeath(), 0, CONFIG.respawnCooldown)
    if remainingTime == 0 then
        state.canRespawn = true
        draw.SimpleText(CONFIG.respawnText, CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format(CONFIG.countdownText, math.ceil(remainingTime)), CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("Think", "DeathScreenRespawnHandler", function()
    if state.isDead and state.canRespawn then
        if input.IsKeyDown(KEY_SPACE) or AIShouldRespawn() then
            net.Start("deathscreen_requestRespawn")
            net.SendToServer()
            state.canRespawn = false
        end
    end
end)

hook.Add("CalcView", "DeathScreenView", function(ply, origin, angles, fov)
    if state.isDead then
        return { origin = origin, angles = angles, fov = fov * CONFIG.fieldOfViewModifier }
    end
end)
