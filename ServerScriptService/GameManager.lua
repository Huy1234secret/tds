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

-- Initialize game
function GameManager:Init()
    print("Tower Defense Game Manager Initialized")
    self:SetupMap()
    self:ConnectEvents()
    
    -- Start the game after a short delay
    wait(3)
    self:StartGame()
end

function GameManager:SetupMap()
    -- Create the path for enemies
    local path = workspace:FindFirstChild("EnemyPath")
    if not path then
        path = Instance.new("Folder")
        path.Name = "EnemyPath"
        path.Parent = workspace
        
        -- Create waypoints for the path
        for i = 1, 10 do
            local waypoint = Instance.new("Part")
            waypoint.Name = "Waypoint" .. i
            waypoint.Size = Vector3.new(4, 1, 4)
            waypoint.Position = Vector3.new(i * 10, 2, 0)
            waypoint.Anchored = true
            waypoint.CanCollide = false
            waypoint.BrickColor = BrickColor.new("Bright green")
            waypoint.Transparency = 0.5
            waypoint.Parent = path
        end
    end
    
    -- Create tower placement area
    local placementArea = workspace:FindFirstChild("TowerPlacement")
    if not placementArea then
        placementArea = Instance.new("Folder")
        placementArea.Name = "TowerPlacement"
        placementArea.Parent = workspace
        
        -- Create placement zones
        for x = -20, 20, 10 do
            for z = -20, 20, 10 do
                if math.abs(z) > 5 then -- Don't place on the path
                    local zone = Instance.new("Part")
                    zone.Name = "PlacementZone"
                    zone.Size = Vector3.new(8, 0.5, 8)
                    zone.Position = Vector3.new(x, 0.25, z)
                    zone.Anchored = true
                    zone.CanCollide = false
                    zone.BrickColor = BrickColor.new("Light blue")
                    zone.Transparency = 0.7
                    zone.Parent = placementArea
                end
            end
        end
    end
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
    
    print("Starting Wave " .. self.CurrentWave)
    
    local waveData = WaveModule:GetWaveData(self.CurrentWave)
    
    spawn(function()
        for i = 1, waveData.EnemyCount do
            local enemy = EnemyModule:SpawnEnemy(waveData.EnemyType)
            if enemy then
                table.insert(self.ActiveEnemies, enemy)
                enemy.Parent = workspace
                
                -- Start enemy movement
                spawn(function()
                    EnemyModule:MoveEnemyAlongPath(enemy)
                end)
            end
            wait(waveData.SpawnDelay)
        end
        
        -- Wait for all enemies to be defeated or reach the end
        while #self.ActiveEnemies > 0 do
            wait(1)
        end
        
        self.WaveInProgress = false
        print("Wave " .. self.CurrentWave .. " completed!")
        
        -- Give players money for completing the wave
        for _, player in pairs(Players:GetPlayers()) do
            local playerData = self:GetPlayerData(player)
            playerData.Money = playerData.Money + (10 + self.CurrentWave * 5)
            self:UpdatePlayerMoney(player, playerData.Money)
        end
    end)
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