# 🎮 Roblox Studio Setup Guide

Follow this step-by-step guide to set up your Tower Defense game in Roblox Studio.

## 📋 Prerequisites
- Roblox Studio installed
- Basic familiarity with Roblox Studio interface

## 🚀 Step-by-Step Setup

### Step 1: Create New Place
1. Open Roblox Studio
2. Click "New" > "Baseplate" to create a new place
3. Save your place with a name like "Tower Defense Game"

### Step 2: Set Up Folder Structure
In the Explorer window, create this exact folder structure:

1. **ServerScriptService** (already exists)
   - Right-click ServerScriptService → Insert Object → Script
   - Rename it to "GameManager"
   - Delete the default "print('Hello world!')" line
   - Copy the contents from `ServerScriptService/GameManager.lua`

2. **ServerScriptService** 
   - Right-click ServerScriptService → Insert Object → Script
   - Rename it to "RemoteEventsSetup"
   - Copy the contents from `ServerScriptService/RemoteEventsSetup.lua`

3. **ReplicatedStorage** (already exists)
   - Right-click ReplicatedStorage → Insert Object → Folder
   - Rename to "RemoteEvents"
   - Right-click ReplicatedStorage → Insert Object → Folder
   - Rename to "Modules"

4. **Inside ReplicatedStorage > RemoteEvents**:
   - Right-click RemoteEvents → Insert Object → RemoteEvent
   - Rename to "PlaceTower"
   - Right-click RemoteEvents → Insert Object → RemoteEvent
   - Rename to "SellTower"

5. **Inside ReplicatedStorage > Modules**:
   - Right-click Modules → Insert Object → ModuleScript
   - Rename to "TowerModule"
   - Replace default code with contents from `ReplicatedStorage/Modules/TowerModule.lua`
   - Repeat for "EnemyModule" and "WaveModule"

6. **StarterPlayerScripts** (already exists)
   - Right-click StarterPlayerScripts → Insert Object → LocalScript
   - Rename to "TowerPlacementClient"
   - Copy contents from `StarterPlayerScripts/TowerPlacementClient.lua`

7. **StarterGui** (already exists)
   - Right-click StarterGui → Insert Object → ScreenGui
   - Rename to "TowerDefenseGui"
   - Right-click TowerDefenseGui → Insert Object → LocalScript
   - Rename to "TowerDefenseGui"
   - Copy contents from `StarterGui/TowerDefenseGui.lua`

### Step 3: Run Setup Script
1. In ServerScriptService, double-click "RemoteEventsSetup"
2. Click the green "Play" button in Studio
3. Check the Output window - you should see "RemoteEvents setup complete!"
4. Stop the game

### Step 4: Test the Game
1. Click the "Play" button in Studio
2. You should see:
   - Instructions popup in the center
   - Tower shop on the left
   - Game HUD on the right
   - Green waypoints and blue placement zones appearing
3. Try placing a tower by clicking a tower button, then clicking a blue zone

## 🔧 Common Setup Issues

### Issue: "Infinite yield" errors
**Solution**: Make sure all RemoteEvents are created as actual RemoteEvent instances, not Scripts

### Issue: Modules not found
**Solution**: Ensure the Modules folder is directly inside ReplicatedStorage

### Issue: Client script not running
**Solution**: Make sure the LocalScript is in StarterPlayerScripts (not StarterPlayer)

### Issue: No UI appearing
**Solution**: Check that the ScreenGui is in StarterGui and contains a LocalScript

## 🎯 Quick Test Checklist

After setup, verify these work:
- [ ] Instructions popup appears when testing
- [ ] Tower shop buttons are clickable
- [ ] Can place towers on blue zones
- [ ] Enemies spawn after 3 seconds
- [ ] Towers shoot at enemies
- [ ] Money/lives display updates
- [ ] Can sell towers by right-clicking

## 📁 Final Folder Structure
Your Explorer should look like this:
```
Workspace
├── Camera
├── Terrain
└── SpawnLocation

ServerScriptService
├── GameManager (Script)
└── RemoteEventsSetup (Script)

StarterPlayer
├── StarterPlayerScripts
│   └── TowerPlacementClient (LocalScript)
└── StarterGui
    └── TowerDefenseGui (ScreenGui)
        └── TowerDefenseGui (LocalScript)

ReplicatedStorage
├── RemoteEvents (Folder)
│   ├── PlaceTower (RemoteEvent)
│   └── SellTower (RemoteEvent)
└── Modules (Folder)
    ├── TowerModule (ModuleScript)
    ├── EnemyModule (ModuleScript)
    └── WaveModule (ModuleScript)
```

## 🎮 Ready to Play!
Once everything is set up correctly:
1. Click Play in Studio
2. Wait for the map to generate (3 seconds)
3. Close the instructions popup
4. Start defending against the waves!

## 🔄 Next Steps
- Customize tower stats in TowerModule.lua
- Add new enemy types in EnemyModule.lua
- Create custom wave patterns in WaveModule.lua
- Experiment with the UI layout
- Publish your game to Roblox!

---
**Need help?** Check the main README.md for troubleshooting tips and customization options!