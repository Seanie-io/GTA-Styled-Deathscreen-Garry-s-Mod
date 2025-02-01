-- CONFIGURATION
local CONFIG = {
    respawnRoles = { "superadmin", "admin" }, -- User roles allowed immediate respawns
    disableDeathSound = true, -- Disable annoying death sound
    baseRespawnCooldown = 5, -- Cooldown before respawn is allowed
}

-- Register network strings
util.AddNetworkString("deathscreen_sendDeath")
util.AddNetworkString("deathscreen_removeDeath")
util.AddNetworkString("deathscreen_requestRespawn")

-- PLAYER STATE TRACKER
-- Elon Musk would use a scalable table for tracking player states efficiently.
local playerStates = {}

-- Initialize player state
local function InitializePlayerState(ply)
    playerStates[ply:SteamID()] = {
        isDead = false,
        deathTime = 0,
        canRespawn = false,
    }
end

-- Cleanup player state when disconnected
hook.Add("PlayerDisconnected", "DeathScreen_CleanupState", function(ply)
    playerStates[ply:SteamID()] = nil
end)

-- Respawn permission logic
local function CanPlayerRespawn(ply)
    local steamID = ply:SteamID()
    local state = playerStates[steamID]
    
    -- Basic validation
    if not state or not IsValid(ply) or ply:Alive() then return false end

    -- Superadmin or admin bypass
    if ply:IsSuperAdmin() or table.HasValue(CONFIG.respawnRoles, ply:GetUserGroup()) then
        return true
    end

    -- Check respawn cooldown
    local timeSinceDeath = CurTime() - state.deathTime
    return timeSinceDeath >= CONFIG.baseRespawnCooldown
end

-- Block default respawn behavior
hook.Add("PlayerDeathThink", "DeathScreen_BlockDefaultRespawn", function(ply)
    return false -- Prevent default respawn handling
end)

-- Handle player death
hook.Add("PlayerDeath", "DeathScreen_HandleDeath", function(victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local steamID = victim:SteamID()
    playerStates[steamID] = playerStates[steamID] or {}
    local state = playerStates[steamID]

    -- Update state on death
    state.isDead = true
    state.deathTime = CurTime()
    state.canRespawn = false

    -- Notify the client
    net.Start("deathscreen_sendDeath")
    net.Send(victim)
end)

-- Handle player respawn requests
net.Receive("deathscreen_requestRespawn", function(_, ply)
    if CanPlayerRespawn(ply) then
        ply:Spawn() -- Respawn the player
        local steamID = ply:SteamID()
        playerStates[steamID].canRespawn = false -- Reset state after respawn

        -- Notify the client to remove the death screen
        net.Start("deathscreen_removeDeath")
        net.Send(ply)
    else
        ply:ChatPrint("⛔ You cannot respawn yet. Please wait.")
    end
end)

-- Handle player spawn
hook.Add("PlayerSpawn", "DeathScreen_HandleSpawn", function(ply)
    local steamID = ply:SteamID()
    playerStates[steamID] = playerStates[steamID] or {}

    -- Reset player state on spawn
    local state = playerStates[steamID]
    state.isDead = false
    state.canRespawn = false

    -- Notify client to remove death effects
    net.Start("deathscreen_removeDeath")
    net.Send(ply)
end)

-- Disable default death sound
if CONFIG.disableDeathSound then
    hook.Add("PlayerDeathSound", "DeathScreen_DisableDeathSound", function()
        return true -- Block the sound
    end)
end

-- Debugging and Logging
if IsValid(game.GetWorld()) then -- Only run on servers
    print("[DeathScreen] Initialized. Elon-approved logic is running.")
end
