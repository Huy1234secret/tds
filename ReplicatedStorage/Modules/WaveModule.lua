-- WaveModule.lua - Handles wave generation and progression
local WaveModule = {}

-- Wave definitions with time limits
WaveModule.Waves = {
    [1] = {
        EnemyType = "Basic",
        EnemyCount = 5,
        SpawnDelay = 1.5,
        TimeLimit = 60
    },
    [2] = {
        EnemyType = "Basic",
        EnemyCount = 8,
        SpawnDelay = 1.2,
        TimeLimit = 58
    },
    [3] = {
        EnemyType = "Fast",
        EnemyCount = 6,
        SpawnDelay = 1.0,
        TimeLimit = 56
    },
    [4] = {
        EnemyType = "Basic",
        EnemyCount = 10,
        SpawnDelay = 1.0,
        TimeLimit = 54
    },
    [5] = {
        EnemyType = "Heavy",
        EnemyCount = 3,
        SpawnDelay = 2.0,
        TimeLimit = 52
    },
    [6] = {
        EnemyType = "Fast",
        EnemyCount = 10,
        SpawnDelay = 0.8,
        TimeLimit = 50
    },
    [7] = {
        EnemyType = "Flying",
        EnemyCount = 7,
        SpawnDelay = 1.5,
        TimeLimit = 48
    },
    [8] = {
        EnemyType = "Heavy",
        EnemyCount = 5,
        SpawnDelay = 1.8,
        TimeLimit = 46
    },
    [9] = {
        EnemyType = "Basic",
        EnemyCount = 15,
        SpawnDelay = 0.7,
        TimeLimit = 44
    },
    [10] = {
        EnemyType = "Heavy",
        EnemyCount = 8,
        SpawnDelay = 1.5,
        TimeLimit = 42
    }
}

-- Advanced wave patterns for higher waves
WaveModule.AdvancedPatterns = {
    {
        -- Mixed wave pattern
        Enemies = {
            {Type = "Basic", Count = 5},
            {Type = "Fast", Count = 3},
            {Type = "Heavy", Count = 1}
        },
        SpawnDelay = 1.0
    },
    {
        -- Flying squadron
        Enemies = {
            {Type = "Flying", Count = 8},
            {Type = "Basic", Count = 2}
        },
        SpawnDelay = 0.8
    },
    {
        -- Heavy assault
        Enemies = {
            {Type = "Heavy", Count = 6},
            {Type = "Fast", Count = 5}
        },
        SpawnDelay = 1.2
    },
    {
        -- Speed rush
        Enemies = {
            {Type = "Fast", Count = 12},
            {Type = "Flying", Count = 4}
        },
        SpawnDelay = 0.5
    }
}

function WaveModule:GetWaveData(waveNumber)
    -- Use predefined waves for the first 10 waves
    if waveNumber <= 10 then
        return self.Waves[waveNumber]
    end
    
    -- For waves beyond 10, use advanced patterns with scaling
    local patternIndex = ((waveNumber - 11) % #self.AdvancedPatterns) + 1
    local pattern = self.AdvancedPatterns[patternIndex]
    
    -- Scale difficulty based on wave number
    local scaleFactor = 1 + (waveNumber - 10) * 0.2
    
    return {
        Pattern = pattern,
        ScaleFactor = scaleFactor,
        IsAdvanced = true
    }
end

function WaveModule:SpawnAdvancedWave(waveData, gameManager)
    local pattern = waveData.Pattern
    local scaleFactor = waveData.ScaleFactor
    
    -- Spawn each enemy type in the pattern
    for _, enemyGroup in ipairs(pattern.Enemies) do
        local scaledCount = math.ceil(enemyGroup.Count * scaleFactor)
        
        for i = 1, scaledCount do
            local enemy = require(game.ReplicatedStorage.Modules.EnemyModule):SpawnEnemy(enemyGroup.Type)
            if enemy then
                -- Scale enemy health based on wave number
                local humanoid = enemy:FindFirstChild("Humanoid")
                if humanoid then
                    local baseHealth = humanoid.MaxHealth
                    local scaledHealth = math.ceil(baseHealth * scaleFactor)
                    humanoid.MaxHealth = scaledHealth
                    humanoid.Health = scaledHealth
                end
                
                table.insert(gameManager.ActiveEnemies, enemy)
                enemy.Parent = workspace
                
                -- Start enemy movement
                spawn(function()
                    require(game.ReplicatedStorage.Modules.EnemyModule):MoveEnemyAlongPath(enemy)
                end)
            end
            wait(pattern.SpawnDelay)
        end
    end
end

function WaveModule:GetWavePreview(waveNumber)
    local waveData = self:GetWaveData(waveNumber)
    
    if waveData.IsAdvanced then
        local preview = "Wave " .. waveNumber .. " (Advanced): "
        for i, enemyGroup in ipairs(waveData.Pattern.Enemies) do
            local scaledCount = math.ceil(enemyGroup.Count * waveData.ScaleFactor)
            preview = preview .. scaledCount .. " " .. enemyGroup.Type
            if i < #waveData.Pattern.Enemies then
                preview = preview .. ", "
            end
        end
        return preview
    else
        return "Wave " .. waveNumber .. ": " .. waveData.EnemyCount .. " " .. waveData.EnemyType .. " enemies"
    end
end

function WaveModule:GetWaveReward(waveNumber)
    -- Base reward increases with wave number
    local baseReward = 20 + (waveNumber * 10)
    
    -- Bonus for milestone waves
    if waveNumber % 5 == 0 then
        baseReward = baseReward * 1.5
    end
    
    if waveNumber % 10 == 0 then
        baseReward = baseReward * 2
    end
    
    return math.floor(baseReward)
end

return WaveModule