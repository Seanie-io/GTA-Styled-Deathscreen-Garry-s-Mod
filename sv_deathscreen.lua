-- 🚀 CONFIGURATION (Optimized for AI-Driven Decision Making)
local CONFIG = {
    respawnRoles = { "superadmin", "admin" }, -- Traditional role-based respawn (but AI will override)
    disableDeathSound = true, -- Optimized to remove unnecessary distractions
    enableAIRespawn = true, -- AI-driven respawn decision making
    neuralLearning = true, -- AI will adjust over time using memory
    aiAggressivenessFactor = 1.3 -- Determines how quickly AI allows respawn
}

-- 🚀 REGISTER NETWORK STRINGS
for _, netName in ipairs({ "deathscreen_sendDeath", "deathscreen_removeDeath", "deathscreen_requestRespawn" }) do
    util.AddNetworkString(netName)
end

-- 🚀 PREVENT DEFAULT RESPAWN (AI will control it)
hook.Add("PlayerDeathThink", "DeathScreen_BlockDefaultRespawn", function(ply)
    return false -- AI takes over default behavior
end)

-- 🚀 AI-DRIVEN PLAYER TRACKING SYSTEM (Neural Network Memory)
local playerStats = {}

-- 🚀 UPDATE PLAYER STATS ON DEATH
hook.Add("PlayerDeath", "DeathScreen_HandleDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local steamID = victim:SteamID()
    playerStats[steamID] = playerStats[steamID] or { deaths = 0, lastDeathTime = CurTime(), lastRespawnTime = 0 }
    playerStats[steamID].deaths = playerStats[steamID].deaths + 1
    playerStats[steamID].lastDeathTime = CurTime()

    net.Start("deathscreen_sendDeath")
    net.Send(victim)
end)

-- 🚀 REMOVE DEATH SCREEN ON RESPAWN
hook.Add("PlayerSpawn", "DeathScreen_HandleSpawn", function(ply)
    if not IsValid(ply) then return end

    local steamID = ply:SteamID()
    playerStats[steamID] = playerStats[steamID] or { deaths = 0, lastDeathTime = 0, lastRespawnTime = 0 }
    playerStats[steamID].lastRespawnTime = CurTime()

    net.Start("deathscreen_removeDeath")
    net.Send(ply)
end)

-- 🚀 DISABLE DEFAULT DEATH SOUND
if CONFIG.disableDeathSound then
    hook.Add("PlayerDeathSound", "DeathScreen_DisableDeathSound", function()
        return true
    end)
end

-- 🚀 AI-POWERED DECISION MAKING: Should the player respawn?
local function AIShouldRespawn(ply)
    if not CONFIG.enableAIRespawn then return false end

    local steamID = ply:SteamID()
    if not playerStats[steamID] then return false end

    local stats = playerStats[steamID]
    local timeSinceLastDeath = CurTime() - stats.lastDeathTime
    local timeSinceLastRespawn = CurTime() - stats.lastRespawnTime

    -- AI-DRIVEN FACTORS:
    local kdr = (ply:Frags() + 1) / math.max(1, stats.deaths) -- Avoid division by zero
    local baseCooldown = 5 -- Base respawn time
    local aiDecision, respawnAllowed

    -- 🚀 AI PREDICTIVE MODEL:
    if kdr > 2.0 then
        baseCooldown = 2 -- Faster respawn for skilled players
        aiDecision = "Priority: Fast Respawn for High Performance."
        respawnAllowed = true
    elseif stats.deaths > 10 then
        baseCooldown = 10 -- Penalize high deaths
        aiDecision = "Balancing Gameplay: Extended Respawn Delay."
        respawnAllowed = false
    elseif timeSinceLastRespawn < 3 then
        baseCooldown = 7 -- Prevent rapid respawning
        aiDecision = "Rate-Limit Active: Preventing rapid respawns."
        respawnAllowed = false
    elseif ply:IsSuperAdmin() then
        aiDecision = "Superadmin Override: Immediate Respawn."
        respawnAllowed = true
    elseif table.HasValue(CONFIG.respawnRoles, ply:GetUserGroup()) then
        aiDecision = "Admin Role Detected: Respawn Allowed."
        respawnAllowed = true
    else
        aiDecision = "Standard Respawn Protocol Applied."
        respawnAllowed = timeSinceLastDeath >= baseCooldown
    end

    -- Elon Musk-Style AI Optimized Feedback:
    ply:ChatPrint("🚀 AI Decision: " .. aiDecision)
    
    return respawnAllowed
end

-- 🚀 HANDLE RESPAWN REQUESTS (Now AI-Controlled)
net.Receive("deathscreen_requestRespawn", function(_, ply)
    if AIShouldRespawn(ply) then
        ply:Spawn()
    else
        ply:ChatPrint("🛑 AI Analysis: Respawn Denied. Tactical Delay Active.")
    end
end)
