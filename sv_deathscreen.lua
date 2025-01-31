-- Configurations
local CONFIG = {
    respawnRoles = { "superadmin", "admin" }, -- Roles allowed to bypass restrictions
    disableDeathSound = true,
}

-- Register Network Strings
for _, netName in ipairs({ "deathscreen_sendDeath", "deathscreen_removeDeath", "deathscreen_requestRespawn" }) do
    util.AddNetworkString(netName)
end

-- Prevent Default Respawn
hook.Add("PlayerDeathThink", "DeathScreen_BlockDefaultRespawn", function(ply)
    return false -- Prevents default respawn behavior
end)

-- Notify Client on Death
hook.Add("PlayerDeath", "DeathScreen_HandleDeath", function(victim)
    if IsValid(victim) and victim:IsPlayer() then
        net.Start("deathscreen_sendDeath")
        net.Send(victim)
    end
end)

-- Remove Death Screen on Respawn
hook.Add("PlayerSpawn", "DeathScreen_HandleSpawn", function(ply)
    if IsValid(ply) then
        net.Start("deathscreen_removeDeath")
        net.Send(ply)
    end
end)

-- Disable Default Death Sound
if CONFIG.disableDeathSound then
    hook.Add("PlayerDeathSound", "DeathScreen_DisableDeathSound", function()
        return true -- Prevents death sound
    end)
end

-- Check if Player Can Respawn
local function CanPlayerRespawn(ply)
    if not IsValid(ply) or ply:Alive() then return false end -- Ensure the player is valid and dead
    if ply:IsSuperAdmin() then return true end

    -- Check if player has permission based on user group
    return table.HasValue(CONFIG.respawnRoles, ply:GetUserGroup())
end

-- Handle Respawn Requests
net.Receive("deathscreen_requestRespawn", function(_, ply)
    if CanPlayerRespawn(ply) then
        ply:Spawn()
    else
        ply:ChatPrint("You do not have permission to respawn yet!")
    end
end)
