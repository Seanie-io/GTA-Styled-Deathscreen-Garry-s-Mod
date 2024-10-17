-- Network strings for communication between server and client
local nets = {
    "deathscreen_sendDeath",
    "deathscreen_removeDeath",
    "deathscreen_requestRespawn" -- New network string for respawn requests
}

for k,v in pairs(nets) do
    util.AddNetworkString(v)
end

-- Prevents the player from respawning instantly
hook.Add("PlayerDeathThink", "NoNormalRespawn", function(ply)
    return false -- Block normal respawn behavior
end)

-- When a player dies, trigger the death screen on the client
hook.Add("PlayerDeath", "DeathscreenHandleDeath", function(victim, inflictor, attacker)
    net.Start("deathscreen_sendDeath")
    net.Send(victim)
end)

-- When the player spawns, remove the death screen
hook.Add("PlayerSpawn", "DeathscreenRemove", function(ply)
    net.Start("deathscreen_removeDeath")
    net.Send(ply)
end)

-- Disable the default death sound for a clean experience
hook.Add("PlayerDeathSound", "DisableDeathSound", function()
    return true -- Disables the default death sound
end)

-- Handle respawn requests from the client
net.Receive("deathscreen_requestRespawn", function(len, ply)
    -- Check if the player is a superadmin or has the 'kill' command enabled
    if ply:IsSuperAdmin() or ply:Alive() == false then
        ply:Spawn() -- Force respawn the player
    end
end)
