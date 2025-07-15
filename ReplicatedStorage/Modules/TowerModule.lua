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
    rangeIndicator.Transparency = 1 -- Fully transparent (invisible)
    rangeIndicator.Color = Color3.fromRGB(0, 255, 0)
    rangeIndicator.Shape = Enum.PartType.Cylinder
    rangeIndicator.Orientation = Vector3.new(0, 0, 90)
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