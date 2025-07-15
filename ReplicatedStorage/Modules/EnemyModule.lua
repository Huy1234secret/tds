-- EnemyModule.lua - Handles enemy creation and behavior
local EnemyModule = {}
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Enemy type definitions
EnemyModule.EnemyTypes = {
    Basic = {
        Health = 100,
        Speed = 8,
        Reward = 10,
        Color = Color3.fromRGB(255, 0, 0),
        Size = Vector3.new(2, 4, 2)
    },
    Fast = {
        Health = 75,
        Speed = 15,
        Reward = 15,
        Color = Color3.fromRGB(0, 255, 0),
        Size = Vector3.new(1.5, 3, 1.5)
    },
    Heavy = {
        Health = 300,
        Speed = 4,
        Reward = 25,
        Color = Color3.fromRGB(128, 128, 128),
        Size = Vector3.new(3, 5, 3)
    },
    Flying = {
        Health = 150,
        Speed = 12,
        Reward = 20,
        Color = Color3.fromRGB(255, 255, 0),
        Size = Vector3.new(2, 2, 4),
        Flying = true
    }
}

function EnemyModule:SpawnEnemy(enemyType)
    local enemyData = self.EnemyTypes[enemyType]
    if not enemyData then
        warn("Unknown enemy type: " .. tostring(enemyType))
        return nil
    end
    
    -- Create the enemy model
    local enemy = Instance.new("Model")
    enemy.Name = "Enemy_" .. enemyType .. "_" .. math.random(1000, 9999)
    
    -- Create humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = enemyData.Health
    humanoid.Health = enemyData.Health
    humanoid.WalkSpeed = enemyData.Speed
    humanoid.Parent = enemy
    
    -- Create body parts
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(enemyData.Size.X * 0.8, enemyData.Size.Y * 0.4, enemyData.Size.Z * 0.8)
    head.Color = enemyData.Color
    head.Shape = Enum.PartType.Block
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent = enemy
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(enemyData.Size.X, enemyData.Size.Y * 0.6, enemyData.Size.Z)
    torso.Color = enemyData.Color
    torso.Shape = Enum.PartType.Block
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent = enemy
    
    -- Position parts
    local startWaypoint = workspace.EnemyPath:FindFirstChild("Waypoint1")
    if startWaypoint then
        local yOffset = enemyData.Flying and 10 or (enemyData.Size.Y / 2 + 1)
        torso.Position = startWaypoint.Position + Vector3.new(0, yOffset, 0)
        head.Position = torso.Position + Vector3.new(0, enemyData.Size.Y * 0.5, 0)
    end
    
    -- Make parts non-collidable with each other but collidable with projectiles
    head.CanCollide = false
    torso.CanCollide = false
    
    -- Set PrimaryPart
    enemy.PrimaryPart = torso
    
    -- Weld head to torso
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = torso
    weld.Part1 = head
    weld.Parent = torso
    
    -- Add enemy attributes
    enemy:SetAttribute("EnemyType", enemyType)
    enemy:SetAttribute("Reward", enemyData.Reward)
    enemy:SetAttribute("CurrentWaypoint", 1)
    enemy:SetAttribute("Flying", enemyData.Flying or false)
    
    -- Create health bar
    self:CreateHealthBar(enemy)
    
    -- Handle death
    humanoid.Died:Connect(function()
        self:OnEnemyDeath(enemy)
    end)
    
    return enemy
end

function EnemyModule:CreateHealthBar(enemy)
    local humanoid = enemy:FindFirstChild("Humanoid")
    local head = enemy:FindFirstChild("Head")
    if not humanoid or not head then return end
    
    -- Create BillboardGui for health bar
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 0.5, 0)
    billboard.Adornee = head
    billboard.Parent = head
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 1
    background.Parent = billboard
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = background
    
    -- Update health bar when health changes
    humanoid.HealthChanged:Connect(function()
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        
        -- Change color based on health
        if healthPercent > 0.6 then
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
        elseif healthPercent > 0.3 then
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
        else
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
        end
    end)
end

function EnemyModule:MoveEnemyAlongPath(enemy)
    local humanoid = enemy:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentWaypoint = 1
    local path = workspace:FindFirstChild("EnemyPath")
    if not path then return end
    
    local isFlying = enemy:GetAttribute("Flying")
    
    while enemy.Parent and humanoid.Health > 0 do
        local waypoint = path:FindFirstChild("Waypoint" .. currentWaypoint)
        if not waypoint then
            -- Reached the end, damage player
            self:OnEnemyReachEnd(enemy)
            break
        end
        
        -- Move to waypoint
        local targetPosition = waypoint.Position
        if isFlying then
            targetPosition = targetPosition + Vector3.new(0, 10, 0)
        else
            targetPosition = targetPosition + Vector3.new(0, enemy.PrimaryPart.Size.Y/2 + 1, 0)
        end
        
        -- Use TweenService for smooth movement
        local distance = (targetPosition - enemy.PrimaryPart.Position).Magnitude
        local speed = humanoid.WalkSpeed
        local duration = distance / speed
        
        local tween = TweenService:Create(
            enemy.PrimaryPart,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {Position = targetPosition}
        )
        
        tween:Play()
        tween.Completed:Wait()
        
        currentWaypoint = currentWaypoint + 1
        wait(0.1)
    end
end

function EnemyModule:OnEnemyDeath(enemy)
    local reward = enemy:GetAttribute("Reward")
    
    -- Give money to all players
    for _, player in pairs(game.Players:GetPlayers()) do
        local currentMoney = player:GetAttribute("Money") or 0
        player:SetAttribute("Money", currentMoney + reward)
    end
    
    -- Remove from active enemies list
    local GameManager = require(game.ServerScriptService:WaitForChild("GameManager"))
    GameManager:RemoveEnemy(enemy)
    
    -- Create death effect
    self:CreateDeathEffect(enemy.PrimaryPart.Position)
    
    print("Enemy defeated! Players earned " .. reward .. " money.")
    
    -- Clean up
    enemy:Destroy()
end

function EnemyModule:OnEnemyReachEnd(enemy)
    -- Damage all players
    for _, player in pairs(game.Players:GetPlayers()) do
        local currentLives = player:GetAttribute("Lives") or 20
        player:SetAttribute("Lives", math.max(0, currentLives - 1))
        
        if currentLives <= 1 then
            print(player.Name .. " has lost the game!")
        else
            print(player.Name .. " lost a life! Lives remaining: " .. (currentLives - 1))
        end
    end
    
    -- Remove from active enemies list
    local GameManager = require(game.ServerScriptService:WaitForChild("GameManager"))
    GameManager:RemoveEnemy(enemy)
    
    enemy:Destroy()
end

function EnemyModule:CreateDeathEffect(position)
    -- Create particle effect
    local effect = Instance.new("Explosion")
    effect.Position = position
    effect.BlastRadius = 5
    effect.BlastPressure = 0
    effect.Visible = true
    effect.Parent = workspace
    
    -- Create coins effect
    for i = 1, 3 do
        local coin = Instance.new("Part")
        coin.Name = "Coin"
        coin.Size = Vector3.new(0.5, 0.1, 0.5)
        coin.Shape = Enum.PartType.Cylinder
        coin.Color = Color3.fromRGB(255, 215, 0)
        coin.Position = position + Vector3.new(math.random(-2, 2), 2, math.random(-2, 2))
        coin.CanCollide = false
        coin.Parent = workspace
        
        -- Animate coin
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = Vector3.new(math.random(-10, 10), 20, math.random(-10, 10))
        bodyVelocity.Parent = coin
        
        game:GetService("Debris"):AddItem(coin, 2)
    end
end

return EnemyModule