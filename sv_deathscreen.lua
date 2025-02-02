util.AddNetworkString("deathscreen_sendDeath")
util.AddNetworkString("deathscreen_removeDeath")
util.AddNetworkString("deathscreen_requestRespawn")

local CONFIG = {
    respawnRoles = { "superadmin", "admin" },
    disableDeathSound = true,
    baseRespawnCooldown = 5
}

local playerStates = {}

local function InitializePlayerState(ply)
    playerStates[ply:SteamID()] = { isDead = false, deathTime = 0, canRespawn = false, deathStreak = 0 }
end

hook.Add("PlayerDisconnected", "DeathScreen_CleanupState", function(ply)
    playerStates[ply:SteamID()] = nil
end)

local function CanPlayerRespawn(ply)
    local state = playerStates[ply:SteamID()]
    return state and (ply:IsSuperAdmin() or table.HasValue(CONFIG.respawnRoles, ply:GetUserGroup()) or CurTime() - state.deathTime >= CONFIG.baseRespawnCooldown)
end

hook.Add("PlayerDeath", "DeathScreen_HandleDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local sid = victim:SteamID()
    local state = playerStates[sid] or {}
    local killerName = (IsValid(attacker) and attacker:IsPlayer()) and attacker:Nick() or "Unknown"
    local weaponName = (IsValid(inflictor) and inflictor:IsWeapon()) and inflictor:GetClass() or "Unknown"
    state.isDead = true
    state.deathTime = CurTime()
    state.deathStreak = (state.deathStreak or 0) + 1

    net.Start("deathscreen_sendDeath")
    net.WriteString(killerName)
    net.WriteString(weaponName)
    net.WriteInt(state.deathStreak, 8)
    net.Send(victim)
end)

net.Receive("deathscreen_requestRespawn", function(_, ply)
    if CanPlayerRespawn(ply) then
        ply:Spawn()
        playerStates[ply:SteamID()].deathStreak = 0
        net.Start("deathscreen_removeDeath")
        net.Send(ply)
    else
        ply:ChatPrint("⛔ You cannot respawn yet. Please wait.")
    end
end)

hook.Add("PlayerDeathThink", "DeathScreen_BlockDefaultRespawn", function(ply) return false end)

if CONFIG.disableDeathSound then
    hook.Add("PlayerDeathSound", "DeathScreen_DisableDeathSound", function() return true end)
end
