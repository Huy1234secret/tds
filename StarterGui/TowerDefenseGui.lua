-- TowerDefenseGui.lua - Starter GUI for Tower Defense game
-- This script creates the basic GUI structure that gets cloned to new players

local screenGui = script.Parent

-- Main game instructions
local instructionsFrame = Instance.new("Frame")
instructionsFrame.Name = "InstructionsFrame"
instructionsFrame.Size = UDim2.new(0, 400, 0, 200)
instructionsFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
instructionsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
instructionsFrame.BackgroundTransparency = 0.3
instructionsFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
instructionsFrame.BorderSizePixel = 2
instructionsFrame.Visible = true
instructionsFrame.Parent = screenGui

-- Instructions title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🏰 TOWER DEFENSE 🏰"
title.TextSize = 24
title.Font = Enum.Font.SourceSansBold
title.TextStrokeTransparency = 0
title.Parent = instructionsFrame

-- Instructions text
local instructions = Instance.new("TextLabel")
instructions.Name = "Instructions"
instructions.Size = UDim2.new(1, -20, 1, -80)
instructions.Position = UDim2.new(0, 10, 0, 40)
instructions.BackgroundTransparency = 1
instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
instructions.TextSize = 14
instructions.Font = Enum.Font.SourceSans
instructions.TextWrapped = true
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.TextStrokeTransparency = 0
instructions.Text = [[
🎯 HOW TO PLAY:
• Click tower buttons to select a tower type
• Click on blue placement zones to place towers
• Towers automatically attack enemies in range
• Defend against waves of enemies
• Don't let enemies reach the end!

🏗️ TOWER TYPES:
• Basic Tower - Balanced damage and cost
• Rapid Tower - Fast attack speed
• Heavy Tower - High damage, slow attack
• Splash Tower - Area damage

💰 CONTROLS:
• Left Click: Place tower / Select tower
• Right Click: Cancel placement / Sell tower
• ESC: Cancel current action
]]
instructions.Parent = instructionsFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 100, 0, 30)
closeButton.Position = UDim2.new(0.5, -50, 1, -35)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
closeButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BorderSizePixel = 1
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "START GAME"
closeButton.TextSize = 14
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = instructionsFrame

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    instructionsFrame.Visible = false
end)

-- Auto-close after 10 seconds
spawn(function()
    wait(10)
    if instructionsFrame.Parent then
        instructionsFrame.Visible = false
    end
end)

return screenGui