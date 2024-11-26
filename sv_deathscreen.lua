-- Configurations
local CONFIG = {
    respawnRoles = { "superadmin", "admin" }, -- Roles allowed to bypass restrictions
    disableDeathSound = true,
}

-- Register Network Strings
local netStrings = {
    "deathscreen_sendDeath",
    "deathscreen_removeDeath",
    "deathscreen_requestRespawn",
}

for _, netName in ipairs(netStrings) do
    util.AddNetworkString(netName)
end

-- Prevent Default Respawn
hook.Add("PlayerDeathThink", "DeathScreen_BlockDefaultRespawn", function(ply)
    return false
end)

-- Notify Client on Death
hook.Add("PlayerDeath", "DeathScreen_HandleDeath", function(victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    net.Start("deathscreen_sendDeath")
    net.Send(victim)
end)

-- Remove Death Screen on Respawn
hook.Add("PlayerSpawn", "DeathScreen_HandleSpawn", function(ply)
    if not IsValid(ply) then return end

    net.Start("deathscreen_removeDeath")
    net.Send(ply)
end)

-- Disable Default Death Sound
if CONFIG.disableDeathSound then
    hook.Add("PlayerDeathSound", "DeathScreen_DisableDeathSound", function()
        return true
    end)
end

-- Handle Respawn Requests
local function CanPlayerRespawn(ply)
    if ply:IsSuperAdmin() then return true end
    if not ply:Alive() then return true end -- Player must be dead
    for _, role in ipairs(CONFIG.respawnRoles) do
        if ply:IsUserGroup(role) then
            return true
        end
    end
    return false
end

net.Receive("deathscreen_requestRespawn", function(_, ply)
    if CanPlayerRespawn(ply) then
        ply:Spawn()
    else
        ply:ChatPrint("You do not have permission to respawn yet!")
    end
end)
