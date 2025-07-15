-- GameManager.lua - Main server-side game logic
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Make sure setup is complete before proceeding
local setupComplete = false
repeat
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    
    if modules and remoteEvents then
        local towerModule = modules:FindFirstChild("TowerModule")
        local enemyModule = modules:FindFirstChild("EnemyModule")
        local waveModule = modules:FindFirstChild("WaveModule")
        local placeTowerEvent = remoteEvents:FindFirstChild("PlaceTower")
        local sellTowerEvent = remoteEvents:FindFirstChild("SellTower")
        
        if towerModule and enemyModule and waveModule and placeTowerEvent and sellTowerEvent then
            setupComplete = true
        end
    end
    
    if not setupComplete then
        print("Waiting for modules and events to be set up...")
        wait(1)
    end
until setupComplete

print("All required modules and events found! Starting GameManager...")

-- Wait for ReplicatedStorage objects
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceTowerEvent = RemoteEvents:WaitForChild("PlaceTower")
local SellTowerEvent = RemoteEvents:WaitForChild("SellTower")

local TowerModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerModule"))
local EnemyModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EnemyModule"))
local WaveModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WaveModule"))

local GameManager = {}
GameManager.ActiveTowers = {}
GameManager.ActiveEnemies = {}
GameManager.GameStarted = false
GameManager.CurrentWave = 0
GameManager.WaveInProgress = false
GameManager.BaseHealth = 20
GameManager.WaveTimer = 0
GameManager.WaveTimeLimit = 60 -- 60 seconds per wave initially

-- Initialize game
function GameManager:Init()
    print("Tower Defense Game Manager Initialized")
    self:SetupMap()
    self:SetupCollisionGroups()
    self:ConnectEvents()
    
    -- Start the game after a short delay
    wait(3)
    self:StartGame()
end

function GameManager:SetupCollisionGroups()
    local PhysicsService = game:GetService("PhysicsService")
    
    -- Create collision groups
    pcall(function()
        PhysicsService:CreateCollisionGroup("Enemies")
        PhysicsService:CreateCollisionGroup("Players")
    end)
    
    -- Set up collision rules
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable("Enemies", "Enemies", false)
        PhysicsService:CollisionGroupSetCollidable("Enemies", "Players", false)
    end)
    
    -- Set up player collision when they join
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            wait(1) -- Wait for character to fully load
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        PhysicsService:SetPartCollisionGroup(part, "Players")
                    end)
                end
            end
        end)
    end)
    
    print("Collision groups set up successfully")
end

function GameManager:SetupMap()
    -- Create the path for enemies (longer, curved path)
    local path = workspace:FindFirstChild("EnemyPath")
    if not path then
        path = Instance.new("Folder")
        path.Name = "EnemyPath"
        path.Parent = workspace
        
        -- Define a more complex path with curves and turns
        local pathPoints = {
            Vector3.new(-80, 2, -40),  -- Start (left side)
            Vector3.new(-60, 2, -40),  -- Move right
            Vector3.new(-40, 2, -40),  -- Continue right
            Vector3.new(-20, 2, -30),  -- Turn up slightly
            Vector3.new(-10, 2, -20),  -- Continue turning
            Vector3.new(0, 2, -10),    -- Center area
            Vector3.new(10, 2, 0),     -- Turn down
            Vector3.new(20, 2, 10),    -- Continue down
            Vector3.new(30, 2, 20),    -- Turn right
            Vector3.new(40, 2, 30),    -- Continue right
            Vector3.new(50, 2, 25),    -- Slight turn up
            Vector3.new(60, 2, 15),    -- Turn up more
            Vector3.new(65, 2, 0),     -- Sharp turn
            Vector3.new(60, 2, -15),   -- Turn back left
            Vector3.new(50, 2, -25),   -- Continue left
            Vector3.new(35, 2, -35),   -- Turn down
            Vector3.new(20, 2, -45),   -- Continue down
            Vector3.new(0, 2, -50),    -- Center bottom
            Vector3.new(-20, 2, -45),  -- Turn left
            Vector3.new(-35, 2, -35),  -- Continue left
            Vector3.new(-45, 2, -20),  -- Turn up
            Vector3.new(-50, 2, 0),    -- Center left
            Vector3.new(-45, 2, 20),   -- Turn right
            Vector3.new(-30, 2, 35),   -- Continue right
            Vector3.new(-10, 2, 45),   -- Turn right more
            Vector3.new(10, 2, 50),    -- Continue right
            Vector3.new(30, 2, 45),    -- Slight turn
            Vector3.new(50, 2, 40),    -- Continue
            Vector3.new(70, 2, 35),    -- Final stretch
            Vector3.new(80, 2, 40)     -- End (right side)
        }
        
        -- Create waypoints
        for i, position in ipairs(pathPoints) do
            local waypoint = Instance.new("Part")
            waypoint.Name = "Waypoint" .. i
            waypoint.Size = Vector3.new(6, 1, 6)
            waypoint.Position = position
            waypoint.Anchored = true
            waypoint.CanCollide = false
            waypoint.BrickColor = BrickColor.new("Bright green")
            waypoint.Transparency = 0.5
            waypoint.Shape = Enum.PartType.Cylinder
            waypoint.Parent = path
            
            -- Add waypoint number label
            local gui = Instance.new("BillboardGui")
            gui.Size = UDim2.new(0, 50, 0, 50)
            gui.Parent = waypoint
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = tostring(i)
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 14
            label.Font = Enum.Font.SourceSansBold
            label.TextStrokeTransparency = 0
            label.Parent = gui
        end
        
        -- Create path visualization
        for i = 1, #pathPoints - 1 do
            local pathSegment = Instance.new("Part")
            pathSegment.Name = "PathSegment" .. i
            pathSegment.Size = Vector3.new(1, 0.5, (pathPoints[i+1] - pathPoints[i]).Magnitude)
            pathSegment.Position = (pathPoints[i] + pathPoints[i+1]) / 2
            pathSegment.CFrame = CFrame.lookAt(pathSegment.Position, pathPoints[i+1])
            pathSegment.Anchored = true
            pathSegment.CanCollide = false
            pathSegment.BrickColor = BrickColor.new("Bright yellow")
            pathSegment.Transparency = 0.8
            pathSegment.Parent = path
        end
    end
    
    -- Create tower placement area (more strategic placement around the curved path)
    local placementArea = workspace:FindFirstChild("TowerPlacement")
    if not placementArea then
        placementArea = Instance.new("Folder")
        placementArea.Name = "TowerPlacement"
        placementArea.Parent = workspace
        
        -- Strategic placement zones around the path
        local placementPoints = {
            -- Around start area
            Vector3.new(-85, 0.25, -50), Vector3.new(-75, 0.25, -50), Vector3.new(-65, 0.25, -50),
            Vector3.new(-85, 0.25, -30), Vector3.new(-75, 0.25, -30), Vector3.new(-65, 0.25, -30),
            
            -- Around first curve
            Vector3.new(-50, 0.25, -50), Vector3.new(-40, 0.25, -50), Vector3.new(-30, 0.25, -45),
            Vector3.new(-25, 0.25, -35), Vector3.new(-15, 0.25, -30), Vector3.new(-5, 0.25, -25),
            
            -- Center area clusters
            Vector3.new(-15, 0.25, -5), Vector3.new(-5, 0.25, -5), Vector3.new(5, 0.25, -5),
            Vector3.new(15, 0.25, -5), Vector3.new(25, 0.25, 5), Vector3.new(35, 0.25, 15),
            
            -- Around upper right curve
            Vector3.new(45, 0.25, 35), Vector3.new(55, 0.25, 35), Vector3.new(65, 0.25, 30),
            Vector3.new(70, 0.25, 20), Vector3.new(70, 0.25, 10), Vector3.new(70, 0.25, -10),
            
            -- Around return path
            Vector3.new(65, 0.25, -25), Vector3.new(55, 0.25, -30), Vector3.new(45, 0.25, -40),
            Vector3.new(35, 0.25, -45), Vector3.new(25, 0.25, -50), Vector3.new(15, 0.25, -55),
            
            -- Around bottom curve
            Vector3.new(5, 0.25, -60), Vector3.new(-5, 0.25, -60), Vector3.new(-15, 0.25, -55),
            Vector3.new(-25, 0.25, -50), Vector3.new(-40, 0.25, -45), Vector3.new(-50, 0.25, -35),
            
            -- Around left side
            Vector3.new(-55, 0.25, -25), Vector3.new(-55, 0.25, -10), Vector3.new(-55, 0.25, 5),
            Vector3.new(-50, 0.25, 15), Vector3.new(-45, 0.25, 25), Vector3.new(-35, 0.25, 40),
            
            -- Around final area
            Vector3.new(-25, 0.25, 50), Vector3.new(-15, 0.25, 55), Vector3.new(0, 0.25, 60),
            Vector3.new(15, 0.25, 60), Vector3.new(25, 0.25, 55), Vector3.new(40, 0.25, 50),
            Vector3.new(55, 0.25, 45), Vector3.new(65, 0.25, 40), Vector3.new(75, 0.25, 45),
            
            -- Additional strategic positions
            Vector3.new(-30, 0.25, 0), Vector3.new(-20, 0.25, 20), Vector3.new(0, 0.25, 30),
            Vector3.new(20, 0.25, -20), Vector3.new(40, 0.25, 0), Vector3.new(0, 0.25, -30)
        }
        
        for i, position in ipairs(placementPoints) do
            local zone = Instance.new("Part")
            zone.Name = "PlacementZone"
            zone.Size = Vector3.new(8, 0.5, 8)
            zone.Position = position
            zone.Anchored = true
            zone.CanCollide = false
            zone.BrickColor = BrickColor.new("Light blue")
            zone.Transparency = 0.7
            zone.Shape = Enum.PartType.Block
            zone.Parent = placementArea
            
            -- Add subtle highlight effect
            local highlight = Instance.new("SelectionBox")
            highlight.Adornee = zone
            highlight.Color3 = Color3.fromRGB(0, 150, 255)
            highlight.Transparency = 0.8
            highlight.Parent = zone
        end
    end
    
    -- Create base health indicator
    local baseHealth = workspace:FindFirstChild("BaseHealth")
    if not baseHealth then
        baseHealth = Instance.new("Part")
        baseHealth.Name = "BaseHealth"
        baseHealth.Size = Vector3.new(10, 8, 2)
        baseHealth.Position = Vector3.new(85, 4, 40) -- Near the end point
        baseHealth.Anchored = true
        baseHealth.CanCollide = false
        baseHealth.BrickColor = BrickColor.new("Bright red")
        baseHealth.Parent = workspace
        
        -- Add base health UI
        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Front
        gui.Parent = baseHealth
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Parent = gui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.4, 0)
        title.BackgroundTransparency = 1
        title.Text = "BASE"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 32
        title.Font = Enum.Font.SourceSansBold
        title.Parent = frame
        
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0.6, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.4, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "Health: 20"
        healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        healthLabel.TextSize = 24
        healthLabel.Font = Enum.Font.SourceSans
        healthLabel.Parent = frame
    end
    
    print("Enhanced map with curved path and strategic tower placement created!")
end

function GameManager:ConnectEvents()
    PlaceTowerEvent.OnServerEvent:Connect(function(player, towerType, position)
        self:PlaceTower(player, towerType, position)
    end)
    
    SellTowerEvent.OnServerEvent:Connect(function(player, tower)
        self:SellTower(player, tower)
    end)
end

function GameManager:PlaceTower(player, towerType, position)
    local playerData = self:GetPlayerData(player)
    local towerCost = TowerModule.TowerTypes[towerType].Cost
    
    if playerData.Money >= towerCost then
        local tower = TowerModule:CreateTower(towerType, position)
        if tower then
            tower.Parent = workspace
            playerData.Money = playerData.Money - towerCost
            table.insert(self.ActiveTowers, tower)
            self:UpdatePlayerMoney(player, playerData.Money)
            print(player.Name .. " placed a " .. towerType .. " tower")
        end
    else
        print(player.Name .. " doesn't have enough money for " .. towerType)
    end
end

function GameManager:SellTower(player, tower)
    for i, activeTower in ipairs(self.ActiveTowers) do
        if activeTower == tower then
            local playerData = self:GetPlayerData(player)
            local sellValue = math.floor(TowerModule.TowerTypes[tower.Name].Cost * 0.7)
            playerData.Money = playerData.Money + sellValue
            self:UpdatePlayerMoney(player, playerData.Money)
            
            table.remove(self.ActiveTowers, i)
            tower:Destroy()
            print(player.Name .. " sold a tower for " .. sellValue)
            break
        end
    end
end

function GameManager:GetPlayerData(player)
    if not player:GetAttribute("Money") then
        player:SetAttribute("Money", 100) -- Starting money
        player:SetAttribute("Lives", 20) -- Starting lives
        print(player.Name .. " started with $100 and 20 lives")
    end
    
    return {
        Money = player:GetAttribute("Money"),
        Lives = player:GetAttribute("Lives")
    }
end

function GameManager:UpdatePlayerMoney(player, newAmount)
    player:SetAttribute("Money", newAmount)
end

function GameManager:StartGame()
    self.GameStarted = true
    print("Game Started!")
    
    -- Start wave spawning
    spawn(function()
        while self.GameStarted do
            if not self.WaveInProgress then
                self:StartNextWave()
            end
            wait(1)
        end
    end)
    
    -- Start tower update loop
    spawn(function()
        while self.GameStarted do
            self:UpdateTowers()
            wait(0.1)
        end
    end)
end

function GameManager:StartNextWave()
    self.CurrentWave = self.CurrentWave + 1
    self.WaveInProgress = true
    
    local waveData = WaveModule:GetWaveData(self.CurrentWave)
    
    -- Use wave-specific time limit or calculate for higher waves
    self.WaveTimeLimit = waveData.TimeLimit or math.max(30, 60 - (self.CurrentWave * 2))
    self.WaveTimer = self.WaveTimeLimit
    
    print("🌊 Starting Wave " .. self.CurrentWave .. " | Time Limit: " .. self.WaveTimeLimit .. "s | Base Health: " .. self.BaseHealth)
    
    -- Update wave UI for all players
    self:UpdateWaveUI()
    
    -- Start wave timer
    local timerConnection
    timerConnection = RunService.Heartbeat:Connect(function()
        self.WaveTimer = self.WaveTimer - (1/30) -- Approximately 30 FPS
        self:UpdateWaveUI()
        
        if self.WaveTimer <= 0 then
            timerConnection:Disconnect()
            self:OnWaveTimeExpired()
        end
    end)
    
    spawn(function()
        for i = 1, waveData.EnemyCount do
            if not self.WaveInProgress then break end -- Stop spawning if wave ended
            
            local enemy = EnemyModule:SpawnEnemy(waveData.EnemyType)
            if enemy then
                table.insert(self.ActiveEnemies, enemy)
                enemy.Parent = workspace
                
                -- Start enemy movement
                spawn(function()
                    EnemyModule:MoveEnemyAlongPath(enemy, self)
                end)
            end
            wait(waveData.SpawnDelay)
        end
        
        -- Wait for all enemies to be defeated, reach the end, or time to expire
        while #self.ActiveEnemies > 0 and self.WaveInProgress and self.WaveTimer > 0 do
            wait(0.5)
        end
        
        if timerConnection then
            timerConnection:Disconnect()
        end
        
        if self.WaveInProgress then
            self:CompleteWave()
        end
    end)
end

function GameManager:CompleteWave()
    self.WaveInProgress = false
    print("✅ Wave " .. self.CurrentWave .. " completed!")
    
    -- Give players money for completing the wave
    local waveBonus = 15 + (self.CurrentWave * 8)
    local timeBonus = math.floor(self.WaveTimer * 0.5) -- Bonus for finishing early
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = self:GetPlayerData(player)
        local totalBonus = waveBonus + timeBonus
        playerData.Money = playerData.Money + totalBonus
        self:UpdatePlayerMoney(player, playerData.Money)
        
        print("💰 " .. player.Name .. " earned $" .. totalBonus .. " (Wave: $" .. waveBonus .. " + Time: $" .. timeBonus .. ")")
    end
    
    -- Prepare for next wave after a short break
    wait(3)
    self:UpdateWaveUI()
end

function GameManager:OnWaveTimeExpired()
    if not self.WaveInProgress then return end
    
    print("⏰ Wave " .. self.CurrentWave .. " time expired!")
    
    -- Destroy remaining enemies
    for _, enemy in pairs(self.ActiveEnemies) do
        if enemy and enemy.Parent then
            enemy:Destroy()
        end
    end
    self.ActiveEnemies = {}
    
    -- Penalize base health for not completing wave in time
    self:DamageBase(2)
    
    self:CompleteWave()
end

function GameManager:DamageBase(damage)
    damage = damage or 1
    self.BaseHealth = math.max(0, self.BaseHealth - damage)
    
    print("💥 Base took " .. damage .. " damage! Base Health: " .. self.BaseHealth)
    
    -- Update base health display
    local baseHealth = workspace:FindFirstChild("BaseHealth")
    if baseHealth then
        local gui = baseHealth:FindFirstChild("SurfaceGui")
        if gui then
            local frame = gui:FindFirstChild("Frame")
            if frame then
                local healthLabel = frame:FindFirstChild("HealthLabel")
                if healthLabel then
                    healthLabel.Text = "Health: " .. self.BaseHealth
                    
                    -- Change color based on health
                    if self.BaseHealth <= 5 then
                        frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Critical
                    elseif self.BaseHealth <= 10 then
                        frame.BackgroundColor3 = Color3.fromRGB(200, 100, 0) -- Warning
                    else
                        frame.BackgroundColor3 = Color3.fromRGB(139, 0, 0) -- Normal
                    end
                end
            end
        end
    end
    
    -- Check for game over
    if self.BaseHealth <= 0 then
        self:GameOver()
    end
end

function GameManager:GameOver()
    self.GameStarted = false
    self.WaveInProgress = false
    
    print("💀 GAME OVER! Base destroyed after " .. self.CurrentWave .. " waves!")
    
    -- Notify all players
    for _, player in pairs(Players:GetPlayers()) do
        -- Create game over GUI
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local gameOverGui = Instance.new("ScreenGui")
            gameOverGui.Name = "GameOverGui"
            gameOverGui.Parent = playerGui
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 400, 0, 200)
            frame.Position = UDim2.new(0.5, -200, 0.5, -100)
            frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            frame.BorderSizePixel = 2
            frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
            frame.Parent = gameOverGui
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0.5, 0)
            title.BackgroundTransparency = 1
            title.Text = "GAME OVER"
            title.TextColor3 = Color3.fromRGB(255, 0, 0)
            title.TextSize = 32
            title.Font = Enum.Font.SourceSansBold
            title.Parent = frame
            
            local details = Instance.new("TextLabel")
            details.Size = UDim2.new(1, 0, 0.5, 0)
            details.Position = UDim2.new(0, 0, 0.5, 0)
            details.BackgroundTransparency = 1
            details.Text = "Survived " .. self.CurrentWave .. " waves"
            details.TextColor3 = Color3.fromRGB(255, 255, 255)
            details.TextSize = 18
            details.Font = Enum.Font.SourceSans
            details.Parent = frame
        end
    end
end

function GameManager:UpdateWaveUI()
    for _, player in pairs(Players:GetPlayers()) do
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local towerDefenseUI = playerGui:FindFirstChild("TowerDefenseUI")
            if towerDefenseUI then
                local hud = towerDefenseUI:FindFirstChild("HUD")
                if hud then
                    local waveLabel = hud:FindFirstChild("WaveLabel")
                    if waveLabel then
                        if self.WaveInProgress then
                            waveLabel.Text = "Wave: " .. self.CurrentWave .. " | Time: " .. math.ceil(self.WaveTimer) .. "s"
                            
                            -- Color code based on time remaining
                            if self.WaveTimer <= 10 then
                                waveLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red
                            elseif self.WaveTimer <= 20 then
                                waveLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
                            else
                                waveLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
                            end
                        else
                            waveLabel.Text = "Next Wave: " .. (self.CurrentWave + 1) .. " | Base: " .. self.BaseHealth
                            waveLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        end
                    end
                end
            end
        end
    end
end

function GameManager:UpdateTowers()
    for _, tower in ipairs(self.ActiveTowers) do
        local target = self:FindNearestEnemy(tower.Position)
        if target then
            TowerModule:AttackTarget(tower, target)
        end
    end
end

function GameManager:FindNearestEnemy(position)
    local nearestEnemy = nil
    local nearestDistance = math.huge
    
    for _, enemy in ipairs(self.ActiveEnemies) do
        if enemy and enemy.Parent then
            local distance = (enemy.Position - position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestEnemy = enemy
            end
        end
    end
    
    return nearestEnemy
end

function GameManager:RemoveEnemy(enemy)
    for i, activeEnemy in ipairs(self.ActiveEnemies) do
        if activeEnemy == enemy then
            table.remove(self.ActiveEnemies, i)
            break
        end
    end
end

-- Initialize the game manager
GameManager:Init()

return GameManager