# EZ Farming - Advanced FiveM Farming Script

## Overview
EZ Farming is a comprehensive farming system for FiveM that supports multiple frameworks (ESX, QB-Core, QBX, and Standalone). It features advanced crop management, growth mechanics, weather/season effects, and a complete farming economy.

## Features

### 🌱 Core Farming System
- **Multiple Crop Types**: Wheat, Corn, Tomato, Potato, Carrot, Lettuce, Strawberry
- **Growth Stages**: Multi-stage growth system with visual progression
- **Farming Tools**: Hoe, Watering Can, Fertilizer with durability system
- **Quality System**: Crops have quality ratings that affect selling price

### 🏞️ Farming Zones
- **Pre-configured Zones**: Grapeseed Farm, Sandy Shores Farm, Paleto Bay Greenhouse
- **Zone Restrictions**: Different crops allowed in different zones
- **Plot Management**: Limited plots per zone to prevent overcrowding
- **Greenhouse System**: Special indoor growing with bonuses

### 🌦️ Dynamic Systems
- **Weather Effects**: Rain helps growth, sun increases water needs
- **Seasonal System**: 4-season cycle affecting crop growth and availability
- **Day/Night Cycle**: Some crops grow better at different times
- **Pest & Disease System**: Random events requiring player intervention

### 📊 Progression System
- **Player Levels**: 100 level farming system with experience points
- **Level Bonuses**: Harvest bonuses, growth speed increases, efficiency improvements
- **Statistics Tracking**: Total plants, harvests, session data
- **Achievements**: Milestone rewards and recognition

### 💰 Economy Integration
- **Farming Shops**: Buy seeds, tools, and supplies
- **Crop Sales**: Sell harvested crops at different prices
- **Quality Pricing**: Better quality crops sell for more money
- **Dynamic Pricing**: Market fluctuation based on supply/demand

### 🎨 User Interface
- **Modern UI**: Clean, responsive web-based interface
- **Interactive Menus**: Easy-to-use farming and shop menus
- **Real-time Info**: Plant status, growth progress, zone information
- **Admin Panel**: Comprehensive management tools for server owners

### 🔧 Multi-Framework Support
- **ESX Legacy**: Full integration with latest ESX
- **QB-Core**: Complete QB-Core compatibility
- **QBX Core**: QBox framework support
- **Standalone**: Works without any framework

## Testing Framework Compatibility

A test file `test_framework.lua` is included to help validate framework detection and basic functionality. To enable testing:

1. Add `test_framework.lua` to your client_scripts in fxmanifest.lua
2. Restart the resource
3. Use the `/testfarm` command to run manual tests
4. Check console output for framework detection results

## Installation

### Prerequisites
- **Database**: MySQL (mysql-async, oxmysql, or ghmattimysql)
- **Inventory**: ox_inventory (recommended), qb-inventory, or esx_inventoryhud
- **Target System**: ox_target (recommended) or qb-target
- **Framework**: ESX, QB-Core, QBX, or Standalone

### Inventory System Support

The script automatically detects and supports multiple inventory systems:

**Priority Order**: ox_inventory → qb-inventory → framework default

#### ox_inventory (Recommended)
- Full integration with metadata support
- Use items from `ox_inventory_items.lua`
- Best performance and features

#### qb-inventory (QB-Core)
- Native QB-Core inventory support
- Add items from `qb_inventory_items.lua` to your `qb-core/shared/items.lua`
- Compatible with QB-Core framework

#### Framework Default
- ESX: Uses native ESX inventory system
- QB-Core: Uses QB-Core player data items
- QBX: Defaults to ox_inventory (recommended setup)

### Target System Support

**Priority Order**: ox_target → qb-target → drawtext fallback

- **ox_target**: Modern, optimized target system (recommended)
- **qb-target**: Original QB-Core target system
- **Drawtext**: Fallback system if no target resource is found

### Drawtext System Support

**Priority Order**: ox_lib → qb-drawtext → native GTA drawtext

When target systems are not available or disabled, the script automatically uses drawtext systems:

#### ox_lib Drawtext
- Modern, customizable text UI
- Rich formatting options
- Position controls and icons

#### qb-drawtext
- Original QB-Core drawtext system
- Simple, reliable text display
- Basic positioning options

#### Native GTA Drawtext
- Built-in GTA drawtext system
- Always available fallback
- Basic 3D world text display

**Configuration:**
```lua
Config.UseTarget = false -- Set to false to use drawtext instead
Config.DrawTextSystem = 'auto' -- 'auto', 'ox_lib', 'qb-drawtext', 'native'
Config.DrawText = {
    enabled = true,
    showControls = true, -- Show [E] key prompts
    position = 'top-center', -- ox_lib position
    font = 0, -- GTA font for native
    scale = 0.35, -- Text scale for native
    color = {255, 255, 255, 255} -- RGBA for native
}
```

### Setup Steps

1. **Download and Extract**
   ```bash
   # Place in your resources folder
   resources/ez_farming/
   ```

2. **Database Setup**
   - The script will automatically create required tables
   - Supports mysql-async, oxmysql, and ghmattimysql

3. **Add to server.cfg**
   ```cfg
   ensure ox_inventory  # If using ox_inventory
   ensure ox_target     # If using ox_target
   ensure ez_farming
   ```

4. **Configure Framework & Systems**
   ```lua
   -- config.lua
   Config.Framework = 'auto' -- 'esx', 'qb', 'qbx', 'standalone', 'auto'
   Config.UseTarget = true   -- Enable ox_target/qb-target integration
   Config.UseOxInventory = true -- Enable ox_inventory integration
   ```

5. **Add Items to ox_inventory**
   - Copy contents from `ox_inventory_items.lua`
   - Add to your `ox_inventory/data/items.lua` file
   - Or use the provided items configuration

### ox_inventory Integration
The script includes full ox_inventory support with:
- **Metadata Support**: Items carry quality information, harvest dates, and farmer details
- **Item Stacking**: Proper stacking for seeds and crops
- **Tool Durability**: Farming tools have durability systems
- **Quality Variants**: Different item types for different crop qualities

### ox_target Integration
Enhanced interaction system with ox_target:
- **Farming Zones**: Click-to-interact with farming areas
- **Plant Interactions**: Right-click plants for context menus
- **Shop Integration**: Easy interaction with shop NPCs
- **Dynamic Targets**: Targets automatically appear/disappear based on plant status

### Configuration Options:
### Basic Settings
```lua
-- Framework and general settings
Config.Framework = 'auto' -- Auto-detect or specify: 'esx', 'qb', 'qbx', 'standalone'
Config.Debug = false
Config.UseTarget = true -- ox_target/qb-target integration
Config.UseOxInventory = true -- ox_inventory integration
Config.MaxDistance = 2.0
```

### Farming Zones
```lua
Config.FarmingZones = {
    {
        name = "Custom Farm",
        coords = vector3(x, y, z),
        size = vector3(50.0, 50.0, 10.0),
        maxPlots = 20,
        allowedCrops = {'wheat', 'corn', 'tomato'},
        blip = {enabled = true, sprite = 140, color = 2}
    }
}
```

### Custom Crops
```lua
Config.Crops = {
    ['custom_crop'] = {
        label = 'Custom Crop',
        seedItem = 'custom_seed',
        harvestItem = 'custom_harvest',
        growthStages = 4,
        growthTime = 300, -- seconds
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer'},
        minHarvest = 1,
        maxHarvest = 3,
        sellPrice = 20,
        experience = 10
    }
}
```

## Usage

### For Players

#### Starting Farming
1. Visit a farming supply shop
2. Buy seeds, hoe, and watering can
3. Go to a farming zone
4. Use the farming menu to plant seeds
5. Water and maintain your crops
6. Harvest when ready and sell for profit

#### Commands
- `/farmstats` - View your farming statistics
- `/farmingadmin` - Admin panel (requires permission)

### For Server Owners

#### Admin Commands
- View all planted crops
- Remove all plants
- Set weather and season
- View player statistics
- Reload configuration

#### Monitoring
- Performance monitoring with automatic reporting
- Backup system for data protection
- Debug mode for troubleshooting

## API & Events

### Client Events
```lua
-- Listen for farming events
RegisterNetEvent('ez_farming:levelUp')
AddEventHandler('ez_farming:levelUp', function(newLevel)
    -- Player leveled up
end)

RegisterNetEvent('ez_farming:plantGrown')
AddEventHandler('ez_farming:plantGrown', function(plantId, newStage)
    -- Plant grew to next stage
end)
```

### Server Events
```lua
-- Custom farming integration
TriggerEvent('ez_farming:getPlayerStats', playerId, function(stats)
    -- Get player farming stats
end)

TriggerEvent('ez_farming:addExperience', playerId, amount)
-- Add experience to player
```

### Exports
```lua
-- Client exports
exports['ez_farming']:GetPlayerFarmingLevel() -- Returns player level
exports['ez_farming']:GetNearbyPlants(radius) -- Get plants near player

-- Server exports
exports['ez_farming']:GetPlayerStats(identifier) -- Get player stats
exports['ez_farming']:SetPlayerLevel(identifier, level) -- Set player level
```

## Advanced Features

### Quality System
Crops have quality ratings (0.1x to 2.0x) affected by:
- Proper watering and fertilization
- Weather conditions
- Season compatibility
- Player skill level
- Pest and disease management

### Pest & Disease System
- Random infestations requiring treatment
- Pesticide and fungicide items
- Prevention through good farming practices
- Visual indicators and notifications

### Greenhouse Benefits
- Weather protection
- Extended growing seasons
- Faster growth rates
- Reduced pest/disease chance

### Economic Features
- Dynamic pricing based on supply/demand
- Quality-based pricing tiers
- Bulk selling bonuses
- Market fluctuation system

## Troubleshooting

### Common Issues

**Plants not growing:**
- Check if plants need watering
- Verify season compatibility
- Check for pest/disease issues
- Ensure proper weather conditions

**Menu not opening:**
- Check target system configuration
- Verify framework detection
- Check console for errors
- Test with Config.UseTarget = false

**Database errors:**
- Verify database resource is running
- Check Config.DatabaseResource setting
- Ensure proper permissions
- Check connection strings

### Debug Mode
Enable debug mode in config.lua:
```lua
Config.Debug = true
```

This will show:
- Framework detection info
- Player coordinates
- Active plants count
- Performance metrics

## Support & Updates

### Getting Help
1. Check the documentation thoroughly
2. Enable debug mode and check console
3. Review configuration settings
4. Test with minimal config first

### Performance Tips
- Limit farming zones to reasonable sizes
- Set appropriate plot limits
- Use database cleanup for old plants
- Monitor performance metrics

### Customization
The script is designed to be highly customizable:
- Modify crop types and properties
- Adjust growth times and mechanics
- Create custom farming zones
- Integrate with other systems

## License
This script is provided as-is for FiveM servers. Please respect the license terms and give appropriate credit when using or modifying the code.

## Changelog

### Version 1.0.0
- Initial release
- Multi-framework support
- Complete farming system
- Advanced UI interface
- Quality and progression systems
- Admin management tools

---

**Enjoy farming in your FiveM server!** 🌾🚜
