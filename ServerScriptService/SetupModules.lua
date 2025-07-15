-- SetupModules.lua - Automatically creates and sets up all required ModuleScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create Modules folder if it doesn't exist
local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
if not modulesFolder then
    modulesFolder = Instance.new("Folder")
    modulesFolder.Name = "Modules"
    modulesFolder.Parent = ReplicatedStorage
    print("Created Modules folder")
end

-- Function to create a ModuleScript with source code
local function createModuleScript(name, source, parent)
    local existingModule = parent:FindFirstChild(name)
    if existingModule then
        existingModule:Destroy()
        print("Removed existing " .. name)
    end
    
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = name
    moduleScript.Source = source
    moduleScript.Parent = parent
    print("Created " .. name .. " ModuleScript")
end

-- TowerModule source code
local towerModuleSource = [[
-- TowerModule.lua - Handles tower creation and behavior
local TowerModule = {}

-- Tower type definitions
TowerModule.TowerTypes = {
    Basic = {
        Cost = 50,
        Damage = 25,
        Range = 25,
        AttackSpeed = 1.0,
        Color = Color3.fromRGB(139, 69, 19),
        Size = Vector3.new(4, 6, 4)
    },
    Rapid = {
        Cost = 100,
        Damage = 15,
        Range = 20,
        AttackSpeed = 0.3,
        Color = Color3.fromRGB(255, 255, 0),
        Size = Vector3.new(3, 5, 3)
    },
    Heavy = {
        Cost = 200,
        Damage = 100,
        Range = 30,
        AttackSpeed = 2.0,
        Color = Color3.fromRGB(128, 128, 128),
        Size = Vector3.new(6, 8, 6)
    },
    Splash = {
        Cost = 300,
        Damage = 75,
        Range = 25,
        AttackSpeed = 1.5,
        SplashRadius = 10,
        Color = Color3.fromRGB(255, 0, 0),
        Size = Vector3.new(5, 7, 5)
    }
}

function TowerModule:CreateTower(towerType, position)
    local towerData = self.TowerTypes[towerType]
    if not towerData then
        warn("Unknown tower type: " .. tostring(towerType))
        return nil
    end
    
    -- Create the tower model
    local tower = Instance.new("Model")
    tower.Name = towerType
    
    -- Create the base
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = towerData.Size
    base.Position = position
    base.Anchored = true
    base.Color = towerData.Color
    base.Parent = tower
    
    -- Create the barrel (for visual appeal)
    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(1, 1, towerData.Size.X * 0.8)
    barrel.Position = position + Vector3.new(0, towerData.Size.Y/2 + 0.5, 0)
    barrel.Anchored = true
    barrel.Color = Color3.fromRGB(64, 64, 64)
    barrel.Parent = tower
    
    -- Add tower stats as attributes
    tower:SetAttribute("TowerType", towerType)
    tower:SetAttribute("Damage", towerData.Damage)
    tower:SetAttribute("Range", towerData.Range)
    tower:SetAttribute("AttackSpeed", towerData.AttackSpeed)
    tower:SetAttribute("LastAttackTime", 0)
    
    if towerData.SplashRadius then
        tower:SetAttribute("SplashRadius", towerData.SplashRadius)
    end
    
    -- Create range indicator (initially invisible)
    local rangeIndicator = Instance.new("Part")
    rangeIndicator.Name = "RangeIndicator"
    rangeIndicator.Size = Vector3.new(towerData.Range * 2, 0.1, towerData.Range * 2)
    rangeIndicator.Position = position
    rangeIndicator.Anchored = true
    rangeIndicator.CanCollide = false
    rangeIndicator.Transparency = 0.8
    rangeIndicator.Color = Color3.fromRGB(0, 255, 0)
    rangeIndicator.Shape = Enum.PartType.Cylinder
    rangeIndicator.Orientation = Vector3.new(0, 0, 90)
    rangeIndicator.Visible = false
    rangeIndicator.Parent = tower
    
    return tower
end

function TowerModule:AttackTarget(tower, target)
    local currentTime = tick()
    local lastAttackTime = tower:GetAttribute("LastAttackTime")
    local attackSpeed = tower:GetAttribute("AttackSpeed")
    
    -- Check if enough time has passed since last attack
    if currentTime - lastAttackTime < attackSpeed then
        return
    end
    
    local towerPosition = tower.Base.Position
    local targetPosition = target.Position
    local distance = (targetPosition - towerPosition).Magnitude
    local range = tower:GetAttribute("Range")
    
    -- Check if target is in range
    if distance <= range then
        -- Update last attack time
        tower:SetAttribute("LastAttackTime", currentTime)
        
        -- Rotate barrel to face target
        local barrel = tower:FindFirstChild("Barrel")
        if barrel then
            local direction = (targetPosition - towerPosition).Unit
            barrel.CFrame = CFrame.lookAt(barrel.Position, barrel.Position + direction)
        end
        
        -- Create projectile
        self:CreateProjectile(tower, target)
        
        print(tower.Name .. " tower attacked enemy!")
    end
end

function TowerModule:CreateProjectile(tower, target)
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(0.5, 0.5, 2)
    projectile.Shape = Enum.PartType.Block
    projectile.Color = Color3.fromRGB(255, 255, 0)
    projectile.CanCollide = false
    projectile.Anchored = false
    
    local barrel = tower:FindFirstChild("Barrel")
    local startPosition = barrel and barrel.Position or tower.Base.Position
    projectile.Position = startPosition + Vector3.new(0, 1, 0)
    projectile.Parent = workspace
    
    -- Create BodyVelocity for movement
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    
    local direction = (target.Position - startPosition).Unit
    bodyVelocity.Velocity = direction * 100 -- Projectile speed
    bodyVelocity.Parent = projectile
    
    -- Store tower reference for damage calculation
    projectile:SetAttribute("SourceTower", tower:GetAttribute("TowerType"))
    projectile:SetAttribute("Damage", tower:GetAttribute("Damage"))
    projectile:SetAttribute("SplashRadius", tower:GetAttribute("SplashRadius") or 0)
    
    -- Handle projectile collision
    local connection
    connection = projectile.Touched:Connect(function(hit)
        local hitModel = hit.Parent
        if hitModel:FindFirstChild("Humanoid") and hitModel.Name:find("Enemy") then
            self:DamageEnemy(hitModel, projectile)
            connection:Disconnect()
            projectile:Destroy()
        end
    end)
    
    -- Destroy projectile after 3 seconds if it doesn't hit anything
    game:GetService("Debris"):AddItem(projectile, 3)
end

function TowerModule:DamageEnemy(enemy, projectile)
    local humanoid = enemy:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local damage = projectile:GetAttribute("Damage")
    local splashRadius = projectile:GetAttribute("SplashRadius")
    
    -- Apply damage to primary target
    humanoid.Health = humanoid.Health - damage
    
    -- Apply splash damage if applicable
    if splashRadius > 0 then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj ~= enemy and obj:FindFirstChild("Humanoid") and obj.Name:find("Enemy") then
                local distance = (obj.PrimaryPart.Position - enemy.PrimaryPart.Position).Magnitude
                if distance <= splashRadius then
                    local splashDamage = damage * 0.5 -- 50% splash damage
                    obj.Humanoid.Health = obj.Humanoid.Health - splashDamage
                end
            end
        end
        
        -- Create splash effect
        self:CreateSplashEffect(enemy.PrimaryPart.Position, splashRadius)
    end
    
    print("Enemy took " .. damage .. " damage!")
end

function TowerModule:CreateSplashEffect(position, radius)
    local effect = Instance.new("Explosion")
    effect.Position = position
    effect.BlastRadius = radius
    effect.BlastPressure = 0
    effect.Visible = true
    effect.Parent = workspace
end

return TowerModule
]]

-- EnemyModule source code
local enemyModuleSource = [[
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
]]

-- WaveModule source code
local waveModuleSource = [[
-- WaveModule.lua - Handles wave generation and progression
local WaveModule = {}

-- Wave definitions
WaveModule.Waves = {
    [1] = {
        EnemyType = "Basic",
        EnemyCount = 5,
        SpawnDelay = 1.5
    },
    [2] = {
        EnemyType = "Basic",
        EnemyCount = 8,
        SpawnDelay = 1.2
    },
    [3] = {
        EnemyType = "Fast",
        EnemyCount = 6,
        SpawnDelay = 1.0
    },
    [4] = {
        EnemyType = "Basic",
        EnemyCount = 10,
        SpawnDelay = 1.0
    },
    [5] = {
        EnemyType = "Heavy",
        EnemyCount = 3,
        SpawnDelay = 2.0
    },
    [6] = {
        EnemyType = "Fast",
        EnemyCount = 10,
        SpawnDelay = 0.8
    },
    [7] = {
        EnemyType = "Flying",
        EnemyCount = 7,
        SpawnDelay = 1.5
    },
    [8] = {
        EnemyType = "Heavy",
        EnemyCount = 5,
        SpawnDelay = 1.8
    },
    [9] = {
        EnemyType = "Basic",
        EnemyCount = 15,
        SpawnDelay = 0.7
    },
    [10] = {
        EnemyType = "Heavy",
        EnemyCount = 8,
        SpawnDelay = 1.5
    }
}

function WaveModule:GetWaveData(waveNumber)
    -- Use predefined waves for the first 10 waves
    if waveNumber <= 10 then
        return self.Waves[waveNumber]
    end
    
    -- For waves beyond 10, generate procedural waves
    local enemyTypes = {"Basic", "Fast", "Heavy", "Flying"}
    local selectedType = enemyTypes[math.random(1, #enemyTypes)]
    
    return {
        EnemyType = selectedType,
        EnemyCount = math.min(5 + waveNumber, 20),
        SpawnDelay = math.max(0.5, 2 - (waveNumber * 0.05))
    }
end

return WaveModule
]]

-- Create all module scripts
createModuleScript("TowerModule", towerModuleSource, modulesFolder)
createModuleScript("EnemyModule", enemyModuleSource, modulesFolder)
createModuleScript("WaveModule", waveModuleSource, modulesFolder)

print("All ModuleScripts created successfully!")
print("You can now run the GameManager script.")

return true