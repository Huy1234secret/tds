-- RemoteEventsSetup.lua - Creates necessary RemoteEvents for client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder if it doesn't exist
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create Modules folder if it doesn't exist
local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
if not modulesFolder then
    modulesFolder = Instance.new("Folder")
    modulesFolder.Name = "Modules"
    modulesFolder.Parent = ReplicatedStorage
end

-- Create PlaceTower RemoteEvent
local placeTowerEvent = remoteEventsFolder:FindFirstChild("PlaceTower")
if not placeTowerEvent then
    placeTowerEvent = Instance.new("RemoteEvent")
    placeTowerEvent.Name = "PlaceTower"
    placeTowerEvent.Parent = remoteEventsFolder
end

-- Create SellTower RemoteEvent
local sellTowerEvent = remoteEventsFolder:FindFirstChild("SellTower")
if not sellTowerEvent then
    sellTowerEvent = Instance.new("RemoteEvent")
    sellTowerEvent.Name = "SellTower"
    sellTowerEvent.Parent = remoteEventsFolder
end

print("RemoteEvents setup complete!")

return true