-- TowerPlacementClient.lua - Client-side tower placement and UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for ReplicatedStorage objects
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceTowerEvent = RemoteEvents:WaitForChild("PlaceTower")
local SellTowerEvent = RemoteEvents:WaitForChild("SellTower")

local TowerModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerModule"))

local TowerPlacementClient = {}
TowerPlacementClient.SelectedTowerType = nil
TowerPlacementClient.PlacementMode = false
TowerPlacementClient.PreviewTower = nil
TowerPlacementClient.SelectedTower = nil

function TowerPlacementClient:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("Tower Placement Client Initialized")
end

function TowerPlacementClient:CreateUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Main UI Frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TowerDefenseUI"
    screenGui.Parent = playerGui
    
    -- Tower selection panel
    local towerPanel = Instance.new("Frame")
    towerPanel.Name = "TowerPanel"
    towerPanel.Size = UDim2.new(0, 200, 0, 400)
    towerPanel.Position = UDim2.new(0, 10, 0.5, -200)
    towerPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    towerPanel.BorderColor3 = Color3.fromRGB(255, 255, 255)
    towerPanel.BorderSizePixel = 2
    towerPanel.Parent = screenGui
    
    -- Tower panel title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Tower Shop"
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.Parent = towerPanel
    
    -- Create tower buttons
    local towerTypes = {"Basic", "Rapid", "Heavy", "Splash"}
    for i, towerType in ipairs(towerTypes) do
        self:CreateTowerButton(towerPanel, towerType, i)
    end
    
    -- Game HUD
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "HUD"
    hudFrame.Size = UDim2.new(0, 300, 0, 100)
    hudFrame.Position = UDim2.new(1, -310, 0, 10)
    hudFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    hudFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    hudFrame.BorderSizePixel = 2
    hudFrame.Parent = screenGui
    
    -- Money display
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyLabel"
    moneyLabel.Size = UDim2.new(1, 0, 0.33, 0)
    moneyLabel.Position = UDim2.new(0, 0, 0, 0)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    moneyLabel.Text = "Money: $100"
    moneyLabel.TextSize = 18
    moneyLabel.Font = Enum.Font.SourceSansBold
    moneyLabel.Parent = hudFrame
    
    -- Lives display
    local livesLabel = Instance.new("TextLabel")
    livesLabel.Name = "LivesLabel"
    livesLabel.Size = UDim2.new(1, 0, 0.33, 0)
    livesLabel.Position = UDim2.new(0, 0, 0.33, 0)
    livesLabel.BackgroundTransparency = 1
    livesLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    livesLabel.Text = "Lives: 20"
    livesLabel.TextSize = 18
    livesLabel.Font = Enum.Font.SourceSansBold
    livesLabel.Parent = hudFrame
    
    -- Wave display
    local waveLabel = Instance.new("TextLabel")
    waveLabel.Name = "WaveLabel"
    waveLabel.Size = UDim2.new(1, 0, 0.33, 0)
    waveLabel.Position = UDim2.new(0, 0, 0.66, 0)
    waveLabel.BackgroundTransparency = 1
    waveLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    waveLabel.Text = "Wave: 1"
    waveLabel.TextSize = 18
    waveLabel.Font = Enum.Font.SourceSansBold
    waveLabel.Parent = hudFrame
    
    -- Store references
    self.UI = {
        ScreenGui = screenGui,
        TowerPanel = towerPanel,
        HUD = hudFrame,
        MoneyLabel = moneyLabel,
        LivesLabel = livesLabel,
        WaveLabel = waveLabel
    }
    
    -- Update HUD periodically
    spawn(function()
        while true do
            self:UpdateHUD()
            wait(0.5)
        end
    end)
end

function TowerPlacementClient:CreateTowerButton(parent, towerType, index)
    local towerData = TowerModule.TowerTypes[towerType]
    
    local button = Instance.new("TextButton")
    button.Name = towerType .. "Button"
    button.Size = UDim2.new(1, -10, 0, 60)
    button.Position = UDim2.new(0, 5, 0, 30 + (index - 1) * 70)
    button.BackgroundColor3 = towerData.Color
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 1
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = towerType .. "\n$" .. towerData.Cost .. "\nDmg: " .. towerData.Damage
    button.TextSize = 12
    button.Font = Enum.Font.SourceSans
    button.Parent = parent
    
    -- Button click event
    button.MouseButton1Click:Connect(function()
        self:SelectTowerType(towerType)
    end)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(
            math.min(255, towerData.Color.R * 255 + 50),
            math.min(255, towerData.Color.G * 255 + 50),
            math.min(255, towerData.Color.B * 255 + 50)
        )
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = towerData.Color
    end)
end

function TowerPlacementClient:SelectTowerType(towerType)
    self.SelectedTowerType = towerType
    self.PlacementMode = true
    print("Selected tower type: " .. towerType)
    
    -- Show placement instructions
    if not self.UI.InstructionLabel then
        local instruction = Instance.new("TextLabel")
        instruction.Name = "InstructionLabel"
        instruction.Size = UDim2.new(0, 400, 0, 50)
        instruction.Position = UDim2.new(0.5, -200, 0, 50)
        instruction.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        instruction.BackgroundTransparency = 0.3
        instruction.TextColor3 = Color3.fromRGB(255, 255, 255)
        instruction.TextSize = 16
        instruction.Font = Enum.Font.SourceSansBold
        instruction.TextStrokeTransparency = 0
        instruction.Parent = self.UI.ScreenGui
        self.UI.InstructionLabel = instruction
    end
    
    self.UI.InstructionLabel.Text = "Click on a blue placement zone to place " .. towerType .. " tower"
    self.UI.InstructionLabel.Visible = true
end

function TowerPlacementClient:ConnectEvents()
    -- Mouse click for tower placement
    mouse.Button1Down:Connect(function()
        if self.PlacementMode and self.SelectedTowerType then
            self:AttemptTowerPlacement()
        else
            self:SelectTowerAtPosition()
        end
    end)
    
    -- Right click to cancel placement or sell tower
    mouse.Button2Down:Connect(function()
        if self.PlacementMode then
            self:CancelPlacement()
        elseif self.SelectedTower then
            self:SellSelectedTower()
        end
    end)
    
    -- ESC key to cancel
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            self:CancelPlacement()
        end
    end)
    
    -- Mouse movement for preview
    mouse.Move:Connect(function()
        if self.PlacementMode then
            self:UpdatePlacementPreview()
        end
    end)
end

function TowerPlacementClient:AttemptTowerPlacement()
    local hit = mouse.Hit
    if not hit then return end
    
    local hitPart = mouse.Target
    if hitPart and hitPart.Name == "PlacementZone" then
        -- Check if player has enough money
        local towerCost = TowerModule.TowerTypes[self.SelectedTowerType].Cost
        local playerMoney = player:GetAttribute("Money") or 0
        
        if playerMoney >= towerCost then
            -- Place the tower
            PlaceTowerEvent:FireServer(self.SelectedTowerType, hit.Position)
            self:CancelPlacement()
        else
            print("Not enough money to place " .. self.SelectedTowerType .. " tower!")
        end
    else
        print("Invalid placement location! Click on a blue placement zone.")
    end
end

function TowerPlacementClient:SelectTowerAtPosition()
    local hit = mouse.Target
    if hit and hit.Parent and hit.Parent:FindFirstChild("Base") then
        local tower = hit.Parent
        if tower:GetAttribute("TowerType") then
            self:SelectTower(tower)
        end
    else
        self:DeselectTower()
    end
end

function TowerPlacementClient:SelectTower(tower)
    -- Deselect previous tower
    self:DeselectTower()
    
    self.SelectedTower = tower
    
    -- Show range indicator
    local rangeIndicator = tower:FindFirstChild("RangeIndicator")
    if rangeIndicator then
        rangeIndicator.Visible = true
    end
    
    -- Show sell UI
    self:ShowSellUI(tower)
    
    print("Selected tower: " .. tower:GetAttribute("TowerType"))
end

function TowerPlacementClient:DeselectTower()
    if self.SelectedTower then
        -- Hide range indicator
        local rangeIndicator = self.SelectedTower:FindFirstChild("RangeIndicator")
        if rangeIndicator then
            rangeIndicator.Visible = false
        end
        
        self.SelectedTower = nil
        self:HideSellUI()
    end
end

function TowerPlacementClient:ShowSellUI(tower)
    if self.UI.SellButton then
        self.UI.SellButton:Destroy()
    end
    
    local towerType = tower:GetAttribute("TowerType")
    local sellValue = math.floor(TowerModule.TowerTypes[towerType].Cost * 0.7)
    
    local sellButton = Instance.new("TextButton")
    sellButton.Name = "SellButton"
    sellButton.Size = UDim2.new(0, 120, 0, 40)
    sellButton.Position = UDim2.new(0.5, -60, 0.8, 0)
    sellButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    sellButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    sellButton.BorderSizePixel = 2
    sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sellButton.Text = "Sell for $" .. sellValue
    sellButton.TextSize = 14
    sellButton.Font = Enum.Font.SourceSansBold
    sellButton.Parent = self.UI.ScreenGui
    
    sellButton.MouseButton1Click:Connect(function()
        self:SellSelectedTower()
    end)
    
    self.UI.SellButton = sellButton
end

function TowerPlacementClient:HideSellUI()
    if self.UI.SellButton then
        self.UI.SellButton:Destroy()
        self.UI.SellButton = nil
    end
end

function TowerPlacementClient:SellSelectedTower()
    if self.SelectedTower then
        SellTowerEvent:FireServer(self.SelectedTower)
        self:DeselectTower()
    end
end

function TowerPlacementClient:UpdatePlacementPreview()
    if not self.PlacementMode or not self.SelectedTowerType then return end
    
    -- Remove existing preview
    if self.PreviewTower then
        self.PreviewTower:Destroy()
    end
    
    local hit = mouse.Hit
    if not hit then return end
    
    local hitPart = mouse.Target
    if hitPart and hitPart.Name == "PlacementZone" then
        -- Create preview tower
        self.PreviewTower = TowerModule:CreateTower(self.SelectedTowerType, hit.Position)
        if self.PreviewTower then
            -- Make it semi-transparent
            for _, part in pairs(self.PreviewTower:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0.5
                    part.CanCollide = false
                end
            end
            
            -- Show range indicator
            local rangeIndicator = self.PreviewTower:FindFirstChild("RangeIndicator")
            if rangeIndicator then
                rangeIndicator.Visible = true
                rangeIndicator.Transparency = 0.9
            end
            
            self.PreviewTower.Parent = workspace
        end
    end
end

function TowerPlacementClient:CancelPlacement()
    self.PlacementMode = false
    self.SelectedTowerType = nil
    
    if self.PreviewTower then
        self.PreviewTower:Destroy()
        self.PreviewTower = nil
    end
    
    if self.UI.InstructionLabel then
        self.UI.InstructionLabel.Visible = false
    end
    
    self:DeselectTower()
    print("Placement cancelled")
end

function TowerPlacementClient:UpdateHUD()
    if not self.UI then return end
    
    -- Update money
    local money = player:GetAttribute("Money") or 0
    self.UI.MoneyLabel.Text = "Money: $" .. money
    
    -- Update lives
    local lives = player:GetAttribute("Lives") or 20
    self.UI.LivesLabel.Text = "Lives: " .. lives
    
    -- Update wave (this would need to be communicated from server)
    -- For now, we'll leave it as is
end

-- Initialize the client
TowerPlacementClient:Init()

return TowerPlacementClient