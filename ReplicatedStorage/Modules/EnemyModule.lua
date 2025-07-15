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
    humanoid.PlatformStand = false
    humanoid.Parent = enemy
    
    -- Create body parts
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(enemyData.Size.X * 0.8, enemyData.Size.Y * 0.4, enemyData.Size.Z * 0.8)
    head.Color = enemyData.Color
    head.Shape = Enum.PartType.Block
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.CanCollide = false -- Don't collide with players/other enemies
    head.Parent = enemy
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(enemyData.Size.X, enemyData.Size.Y * 0.6, enemyData.Size.Z)
    torso.Color = enemyData.Color
    torso.Shape = Enum.PartType.Block
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.CanCollide = true -- Collide with terrain but collision groups will handle players
    torso.Parent = enemy
    
    -- Create legs for better walking appearance
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(enemyData.Size.X * 0.4, enemyData.Size.Y * 0.4, enemyData.Size.Z * 0.4)
    leftLeg.Color = enemyData.Color
    leftLeg.Shape = Enum.PartType.Block
    leftLeg.TopSurface = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.CanCollide = false
    leftLeg.Parent = enemy
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(enemyData.Size.X * 0.4, enemyData.Size.Y * 0.4, enemyData.Size.Z * 0.4)
    rightLeg.Color = enemyData.Color
    rightLeg.Shape = Enum.PartType.Block
    rightLeg.TopSurface = Enum.SurfaceType.Smooth
    rightLeg.BottomSurface = Enum.SurfaceType.Smooth
    rightLeg.CanCollide = false
    rightLeg.Parent = enemy
    
    -- Position parts
    local startWaypoint = workspace.EnemyPath:FindFirstChild("Waypoint1")
    if startWaypoint then
        local yOffset = enemyData.Flying and 10 or (enemyData.Size.Y / 2 + 1)
        torso.Position = startWaypoint.Position + Vector3.new(0, yOffset, 0)
        head.Position = torso.Position + Vector3.new(0, enemyData.Size.Y * 0.5, 0)
        leftLeg.Position = torso.Position + Vector3.new(-enemyData.Size.X * 0.25, -enemyData.Size.Y * 0.5, 0)
        rightLeg.Position = torso.Position + Vector3.new(enemyData.Size.X * 0.25, -enemyData.Size.Y * 0.5, 0)
    end
    
    -- Set PrimaryPart
    enemy.PrimaryPart = torso
    
    -- Create joints for walking animation
    local neck = Instance.new("Motor6D")
    neck.Name = "Neck"
    neck.Part0 = torso
    neck.Part1 = head
    neck.C0 = CFrame.new(0, enemyData.Size.Y * 0.3, 0)
    neck.C1 = CFrame.new(0, -enemyData.Size.Y * 0.2, 0)
    neck.Parent = torso
    
    local leftHip = Instance.new("Motor6D")
    leftHip.Name = "Left Hip"
    leftHip.Part0 = torso
    leftHip.Part1 = leftLeg
    leftHip.C0 = CFrame.new(-enemyData.Size.X * 0.25, -enemyData.Size.Y * 0.3, 0)
    leftHip.C1 = CFrame.new(0, enemyData.Size.Y * 0.2, 0)
    leftHip.Parent = torso
    
    local rightHip = Instance.new("Motor6D")
    rightHip.Name = "Right Hip"
    rightHip.Part0 = torso
    rightHip.Part1 = rightLeg
    rightHip.C0 = CFrame.new(enemyData.Size.X * 0.25, -enemyData.Size.Y * 0.3, 0)
    rightHip.C1 = CFrame.new(0, enemyData.Size.Y * 0.2, 0)
    rightHip.Parent = torso
    
    -- Set up collision groups to prevent enemy-player and enemy-enemy collision
    local PhysicsService = game:GetService("PhysicsService")
    
    -- Create collision groups if they don't exist
    pcall(function()
        PhysicsService:CreateCollisionGroup("Enemies")
        PhysicsService:CreateCollisionGroup("Players")
    end)
    
    -- Set collision group for enemy parts
    for _, part in pairs({torso, head, leftLeg, rightLeg}) do
        PhysicsService:SetPartCollisionGroup(part, "Enemies")
    end
    
    -- Make enemies not collide with each other
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable("Enemies", "Enemies", false)
        PhysicsService:CollisionGroupSetCollidable("Enemies", "Players", false)
    end)
    
    -- Add enemy attributes
    enemy:SetAttribute("EnemyType", enemyType)
    enemy:SetAttribute("Reward", enemyData.Reward)
    enemy:SetAttribute("CurrentWaypoint", 1)
    enemy:SetAttribute("Flying", enemyData.Flying or false)
    
    -- Create health bar and name UI
    self:CreateEnemyUI(enemy, enemyType)
    
    -- Handle death
    humanoid.Died:Connect(function()
        self:OnEnemyDeath(enemy)
    end)
    
    return enemy
end

function EnemyModule:CreateEnemyUI(enemy, enemyType)
    local humanoid = enemy:FindFirstChild("Humanoid")
    local head = enemy:FindFirstChild("Head")
    if not humanoid or not head then return end
    
    -- Create BillboardGui for enemy UI
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(3, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Adornee = head
    billboard.Parent = head
    
    -- Enemy name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "EnemyName"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = enemyType .. " Enemy"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = billboard
    
    -- Health bar background
    local healthBackground = Instance.new("Frame")
    healthBackground.Name = "HealthBackground"
    healthBackground.Size = UDim2.new(1, 0, 0.3, 0)
    healthBackground.Position = UDim2.new(0, 0, 0.4, 0)
    healthBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBackground.BorderColor3 = Color3.fromRGB(255, 255, 255)
    healthBackground.BorderSizePixel = 1
    healthBackground.Parent = billboard
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBackground
    
    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.Position = UDim2.new(0, 0, 0, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = humanoid.Health .. "/" .. humanoid.MaxHealth
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 12
    healthText.Font = Enum.Font.SourceSans
    healthText.TextStrokeTransparency = 0
    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthText.Parent = healthBackground
    
    -- Enemy type icon (optional visual enhancement)
    local typeIcon = Instance.new("TextLabel")
    typeIcon.Name = "TypeIcon"
    typeIcon.Size = UDim2.new(1, 0, 0.3, 0)
    typeIcon.Position = UDim2.new(0, 0, 0.7, 0)
    typeIcon.BackgroundTransparency = 1
    typeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    typeIcon.TextSize = 16
    typeIcon.Font = Enum.Font.SourceSansBold
    typeIcon.TextStrokeTransparency = 0
    typeIcon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    typeIcon.Parent = billboard
    
    -- Set type-specific icons
    if enemyType == "Basic" then
        typeIcon.Text = "⚔️"
    elseif enemyType == "Fast" then
        typeIcon.Text = "💨"
    elseif enemyType == "Heavy" then
        typeIcon.Text = "🛡️"
    elseif enemyType == "Flying" then
        typeIcon.Text = "✈️"
    end
    
    -- Update health bar when health changes
    humanoid.HealthChanged:Connect(function()
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        healthText.Text = math.ceil(humanoid.Health) .. "/" .. humanoid.MaxHealth
        
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
    
    -- Set up walking animation
    if not isFlying then
        self:StartWalkingAnimation(enemy)
    end
    
    while enemy.Parent and humanoid.Health > 0 do
        local waypoint = path:FindFirstChild("Waypoint" .. currentWaypoint)
        if not waypoint then
            -- Reached the end, damage player
            self:OnEnemyReachEnd(enemy)
            break
        end
        
        -- Calculate target position
        local targetPosition = waypoint.Position
        if isFlying then
            targetPosition = targetPosition + Vector3.new(0, 10, 0)
        else
            targetPosition = targetPosition + Vector3.new(0, enemy.PrimaryPart.Size.Y/2 + 1, 0)
        end
        
        -- Use Humanoid:MoveTo for natural walking movement
        if not isFlying then
            humanoid:MoveTo(targetPosition)
            
            -- Wait for the humanoid to reach the target or timeout
            local moveConnection
            local arrived = false
            
            moveConnection = humanoid.MoveToFinished:Connect(function(reached)
                arrived = true
                if moveConnection then
                    moveConnection:Disconnect()
                end
            end)
            
            -- Timeout after reasonable time to prevent infinite waiting
            local startTime = tick()
            local timeout = 10 -- 10 seconds timeout
            
            while not arrived and (tick() - startTime) < timeout and enemy.Parent and humanoid.Health > 0 do
                wait(0.1)
                
                -- Check if we're close enough to the target
                local distance = (enemy.PrimaryPart.Position - targetPosition).Magnitude
                if distance < 3 then
                    arrived = true
                end
            end
            
            if moveConnection then
                moveConnection:Disconnect()
            end
        else
            -- For flying enemies, use smoother tween movement
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
        end
        
        currentWaypoint = currentWaypoint + 1
        wait(0.1)
    end
    
    -- Stop walking animation when movement ends
    if not isFlying then
        self:StopWalkingAnimation(enemy)
    end
end

function EnemyModule:StartWalkingAnimation(enemy)
    local leftHip = enemy.Torso:FindFirstChild("Left Hip")
    local rightHip = enemy.Torso:FindFirstChild("Right Hip")
    
    if leftHip and rightHip then
        -- Create simple walking animation
        spawn(function()
            local animationSpeed = 2
            local time = 0
            
            enemy:SetAttribute("Walking", true)
            
            while enemy.Parent and enemy:GetAttribute("Walking") do
                time = time + 0.1 * animationSpeed
                
                -- Simple leg swinging animation
                local leftAngle = math.sin(time) * 0.5
                local rightAngle = -math.sin(time) * 0.5
                
                leftHip.C0 = CFrame.new(-enemy.PrimaryPart.Size.X * 0.25, -enemy.PrimaryPart.Size.Y * 0.3, 0) * CFrame.Angles(leftAngle, 0, 0)
                rightHip.C0 = CFrame.new(enemy.PrimaryPart.Size.X * 0.25, -enemy.PrimaryPart.Size.Y * 0.3, 0) * CFrame.Angles(rightAngle, 0, 0)
                
                wait(0.1)
            end
        end)
    end
end

function EnemyModule:StopWalkingAnimation(enemy)
    enemy:SetAttribute("Walking", false)
    
    -- Reset leg positions
    local leftHip = enemy.Torso:FindFirstChild("Left Hip")
    local rightHip = enemy.Torso:FindFirstChild("Right Hip")
    
    if leftHip and rightHip then
        leftHip.C0 = CFrame.new(-enemy.PrimaryPart.Size.X * 0.25, -enemy.PrimaryPart.Size.Y * 0.3, 0)
        rightHip.C0 = CFrame.new(enemy.PrimaryPart.Size.X * 0.25, -enemy.PrimaryPart.Size.Y * 0.3, 0)
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