-- CONFIGURATION (-Level Optimization)
local CONFIG = {
    fontSmall = "deathscreen_small",
    fontLarge = "deathscreen_large",
    baseRespawnCooldown = 5, -- AI will dynamically modify this
    fadeSpeed = 300, -- Hyper-optimized rendering
    fieldOfViewModifier = 0.85,
    enableAI = true, -- AI-driven decision-making enabled
    enableNeuralLearning = true, -- Neural network-inspired self-learning
    aiAggressivenessFactor = 1.5, -- 
    enableAIAdvisory = true -- AI will provide coaching and tactical feedback
}

-- FONT DEFINITIONS (SpaceX-Optimized UI)
surface.CreateFont(CONFIG.fontSmall, { font = "Arial", size = 24, weight = 1000 })
surface.CreateFont(CONFIG.fontLarge, { font = "Arial", size = 90, weight = 1000 })

-- STATE MANAGEMENT (Neural Net Memory)
local state = {
    isDead = false,
    deathTime = 0,
    alpha = 0,
    canRespawn = false,
    adjustedCooldown = CONFIG.baseRespawnCooldown,
    aiDecisionMessage = "Processing...",
    lastDeathLocation = nil, -- AI uses this for pattern recognition
    aiRespawnPredictions = {}, -- AI learning dataset
    aiPerformanceFeedback = nil -- AI coaching message
}

-- AI-POWERED PLAYER PERFORMANCE TRACKING
local playerStats = {
    kills = 0,
    deaths = 0,
    teammatesAlive = 0,
    enemiesRemaining = 0,
    lastRespawnTime = 0,
    averageLifeSpan = 0
}

-- 🔥  AI: Advanced Decision-Making Algorithm
local function AIAnalyzeRespawn()
    if not CONFIG.enableAI then return CONFIG.baseRespawnCooldown end

    -- Calculate player's Kill-to-Death Ratio (KDR)
    local kdr = playerStats.kills / math.max(1, playerStats.deaths) -- Prevent division by zero
    local timeSinceLastRespawn = CurTime() - playerStats.lastRespawnTime
    local decisionMessage, performanceFeedback
    local cooldown = CONFIG.baseRespawnCooldown

    -- 🧠 AI LEARNING: Store respawn time patterns
    table.insert(state.aiRespawnPredictions, timeSinceLastRespawn)

    -- AI PREDICTIVE DECISION-MAKING
    if kdr > 2.0 then
        cooldown = math.max(2, CONFIG.baseRespawnCooldown - 2)
        decisionMessage = "Priority: Fast Respawn for High Performance."
        performanceFeedback = "Your efficiency is exceptional. Keep dominating."
    elseif playerStats.teammatesAlive < 2 and playerStats.enemiesRemaining > 5 then
        cooldown = CONFIG.baseRespawnCooldown + 3
        decisionMessage = "Tactical Delay: Waiting for optimal conditions."
        performanceFeedback = "Patience. Your team is vulnerable. AI is optimizing strategy."
    elseif playerStats.deaths > 10 then
        cooldown = CONFIG.baseRespawnCooldown + 5
        decisionMessage = "Balancing Gameplay: Extended Respawn Delay."
        performanceFeedback = "AI suggests improving survival tactics. Review your playstyle."
    else
        decisionMessage = "Standard Optimized Respawn Protocol."
        performanceFeedback = "Maintain your current performance. AI is tracking efficiency."
    end

    -- 🔄 AI FEEDBACK LOOP (Neural Net Simulation)
    if CONFIG.enableNeuralLearning then
        local avgRespawnTime = 0
        for _, t in ipairs(state.aiRespawnPredictions) do
            avgRespawnTime = avgRespawnTime + t
        end
        avgRespawnTime = avgRespawnTime / math.max(1, #state.aiRespawnPredictions)

        if avgRespawnTime < 3 then
            cooldown = cooldown + 2
        elseif avgRespawnTime > 8 then
            cooldown = cooldown - 1
        end
    end

    state.aiDecisionMessage = decisionMessage
    state.aiPerformanceFeedback = performanceFeedback
    return cooldown
end

-- NETWORK MESSAGE HANDLING
net.Receive("deathscreen_sendDeath", function()
    state.isDead = true
    state.deathTime = CurTime()
    state.adjustedCooldown = AIAnalyzeRespawn()
    playerStats.lastRespawnTime = CurTime()
end)

net.Receive("deathscreen_removeDeath", function()
    state.isDead = false
end)

-- HUD DRAWING
hook.Add("HUDPaint", "DeathScreenHUD", function()
    if not state.isDead then return end
    state.alpha = math.Approach(state.alpha, 255, CONFIG.fadeSpeed * FrameTime())

    -- WASTED TEXT
    draw.SimpleText("WASTED", CONFIG.fontLarge, ScrW() / 2, ScrH() / 2, Color(255, 0, 0, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- AI RESPWAN COUNTDOWN
    local remainingTime = math.Clamp(state.adjustedCooldown - (CurTime() - state.deathTime), 0, state.adjustedCooldown)
    if remainingTime == 0 then
        state.canRespawn = true
        draw.SimpleText("Press [SPACE] to respawn", CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format("Respawn in %d seconds", math.ceil(remainingTime)), CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 100, Color(255, 255, 255, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- AI PERFORMANCE FEEDBACK
    if CONFIG.enableAIAdvisory then
        draw.SimpleText(state.aiPerformanceFeedback, CONFIG.fontSmall, ScrW() / 2, ScrH() / 2 + 140, Color(200, 200, 200, state.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- 🚀  AUTONOMOUS RESPAWN LOGIC
hook.Add("Think", "DeathScreenRespawnHandler", function()
    if state.isDead and state.canRespawn and input.IsKeyDown(KEY_SPACE) then
        net.Start("deathscreen_requestRespawn")
        net.SendToServer()
        state.canRespawn = false
    end
end)
