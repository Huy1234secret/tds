# Roblox Tower Defense Game

A complete tower defense game built for Roblox using Luau scripting. Defend against waves of enemies by strategically placing towers!

## 🎮 Game Features

### Tower Types
- **Basic Tower** - $50 - Balanced damage and range
- **Rapid Tower** - $100 - Fast attack speed, lower damage
- **Heavy Tower** - $200 - High damage, slow attack speed
- **Splash Tower** - $300 - Area of effect damage

### Enemy Types
- **Basic Enemy** - Standard health and speed
- **Fast Enemy** - Low health but high speed
- **Heavy Enemy** - High health but slow
- **Flying Enemy** - Can fly over obstacles

### Game Mechanics
- **Wave System** - 10+ waves with increasing difficulty
- **Economy** - Earn money by defeating enemies and completing waves
- **Lives System** - Lose lives when enemies reach the end
- **Tower Upgrading** - Sell towers for 70% of original cost

## 🚀 Setup Instructions

### 1. Roblox Studio Setup
1. Open Roblox Studio
2. Create a new place
3. Set up the folder structure as shown below

### 2. Folder Structure
```
ServerScriptService/
├── GameManager.lua
└── RemoteEventsSetup.lua

ReplicatedStorage/
├── RemoteEvents/
│   ├── PlaceTower (RemoteEvent)
│   └── SellTower (RemoteEvent)
└── Modules/
    ├── TowerModule.lua
    ├── EnemyModule.lua
    └── WaveModule.lua

StarterPlayerScripts/
└── TowerPlacementClient.lua

StarterGui/
└── TowerDefenseGui.lua
```

### 3. Script Installation
1. Copy each script file to its corresponding location in Roblox Studio
2. **Important**: For RemoteEvents, you need to create actual RemoteEvent instances:
   - In ReplicatedStorage, create a Folder named "RemoteEvents"
   - Inside that folder, create two RemoteEvent instances:
     - Name one "PlaceTower"
     - Name one "SellTower"
3. Run the RemoteEventsSetup script first to create the folder structure

### 4. Game Setup
1. The game will automatically create the map when you run it
2. Players start with $100 and 20 lives
3. The first wave begins 3 seconds after the game starts

## 🎯 How to Play

### Placing Towers
1. Click on a tower button in the left panel
2. Click on any blue placement zone to place the tower
3. Towers will automatically attack enemies in range

### Managing Towers
- **Select Tower**: Click on any placed tower
- **Sell Tower**: Right-click a selected tower or use the sell button
- **View Range**: Selected towers show their attack range

### Controls
- **Left Click**: Place tower / Select tower
- **Right Click**: Cancel placement / Sell selected tower
- **ESC Key**: Cancel current action

## 📊 Game Progression

### Waves 1-10
Predefined waves with specific enemy types and counts

### Waves 11+
Advanced mixed waves with scaling difficulty:
- Enemy health increases with wave number
- Multiple enemy types per wave
- Faster spawn rates

### Economy
- Starting money: $100
- Enemy rewards: 10-25$ per enemy
- Wave completion bonus: 10 + (wave * 5)$
- Milestone bonuses: 1.5x for waves divisible by 5, 2x for waves divisible by 10

## 🛠️ Customization

### Adding New Tower Types
Edit `TowerModule.lua` and add new tower types to the `TowerTypes` table:

```lua
NewTower = {
    Cost = 150,
    Damage = 50,
    Range = 30,
    AttackSpeed = 1.2,
    Color = Color3.fromRGB(0, 255, 255),
    Size = Vector3.new(4, 7, 4)
}
```

### Adding New Enemy Types
Edit `EnemyModule.lua` and add new enemy types to the `EnemyTypes` table:

```lua
NewEnemy = {
    Health = 200,
    Speed = 10,
    Reward = 20,
    Color = Color3.fromRGB(255, 0, 255),
    Size = Vector3.new(2.5, 4.5, 2.5)
}
```

### Modifying Waves
Edit `WaveModule.lua` to change wave compositions and difficulty scaling.

## 🎨 Visual Features

- **Health Bars** - Dynamic health bars above enemies
- **Range Indicators** - Visual range display for selected towers
- **Projectile System** - Animated projectiles with collision detection
- **Particle Effects** - Explosions and coin effects
- **UI System** - Clean, intuitive user interface

## 🔧 Technical Details

### Architecture
- **Client-Server Model** - Server handles game logic, client handles UI
- **Module System** - Organized code using ModuleScripts
- **Event-Driven** - RemoteEvents for client-server communication
- **Object-Oriented** - Clean, maintainable code structure

### Performance
- **Efficient Targeting** - Optimized enemy detection for towers
- **Garbage Collection** - Automatic cleanup of destroyed objects
- **Smooth Movement** - TweenService for enemy movement
- **Responsive UI** - 60 FPS user interface updates

## 🐛 Troubleshooting

### Common Issues
1. **"Infinite yield" errors**: Make sure all RemoteEvents are created as actual RemoteEvent instances
2. **Towers not attacking**: Check that enemies have the correct naming pattern ("Enemy_")
3. **UI not showing**: Ensure StarterPlayerScripts contains the client script
4. **Map not generating**: Run the game and wait 3 seconds for initialization

### Debug Tips
- Check the Output window for error messages
- Ensure all scripts are in the correct locations
- Verify RemoteEvents exist in ReplicatedStorage/RemoteEvents
- Test in both Studio and live games

## 📈 Future Enhancements

Potential additions to expand the game:
- Tower upgrade system
- Special abilities and power-ups
- Multiplayer cooperative mode
- Leaderboards and statistics
- More enemy types and behaviors
- Boss enemies
- Multiple maps/levels
- Achievement system

## 📄 License

This project is open source and available for educational and personal use. Feel free to modify and expand upon it for your own Roblox games!

---

**Happy Tower Defending!** 🏰⚔️