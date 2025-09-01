# EZ Farming - Framework Compatibility Changelog

## Version 1.1 - Documentation Compliance Update

### QBX Framework Corrections
Based on official QBX documentation (https://docs.qbox.re/):

**Client-side Changes:**
- ✅ Fixed QBX player data retrieval using `exports.qbx_core:GetPlayerData()`
- ✅ Updated QBX event handlers to use proper `qbx_core:client:*` events
- ✅ Corrected notification system to use `exports.qbx_core:Notify()`
- ✅ Fixed inventory checking to prioritize ox_inventory (QBX default)

**Server-side Changes:**
- ✅ Updated `GetPlayerFromId()` to use `exports.qbx_core:GetPlayer()`
- ✅ Fixed player identifier retrieval for QBX framework
- ✅ Ensured QBX uses ox_inventory by default for item management
- ✅ Removed incorrect `QBX.Functions` references

### QB-Core Framework Improvements
Based on official QB-Core documentation (https://docs.qbcore.org/):

**Enhanced Compatibility:**
- ✅ Improved QB-Core inventory detection (ox_inventory vs native)
- ✅ Better handling of QB-Core player data structure
- ✅ Proper fallback mechanisms for different QB-Core setups
- ✅ Corrected HasItem function for QB-Core inventory iteration

### ox_inventory Integration
- ✅ Prioritized ox_inventory for QBX (default inventory system)
- ✅ Added proper ox_inventory export checking
- ✅ Enhanced metadata support for ox_inventory items
- ✅ Improved item quality and durability handling

### General Framework Improvements
- ✅ Better auto-detection of available frameworks
- ✅ Improved error handling for missing framework functions
- ✅ Enhanced logging for framework initialization
- ✅ Added framework validation testing script

### Files Updated
- `client/main.lua` - Fixed QBX player data and events
- `client/utils.lua` - Updated notification system
- `server/main.lua` - Corrected QBX player functions and inventory
- `test_framework.lua` - Added comprehensive framework testing
- `README.md` - Updated with testing instructions

### Compatibility Matrix
| Framework | Status | Inventory | Target | Notes |
|-----------|--------|-----------|--------|--------|
| ESX | ✅ Full | Native/ox_inventory | ox_target/qb-target | Fully compatible |
| QB-Core | ✅ Full | Native/ox_inventory | qb-target/ox_target | Automatic detection |
| QBX | ✅ Full | ox_inventory (default) | ox_target (default) | Modern framework |
| Standalone | ✅ Full | ox_inventory (optional) | ox_target/qb-target | No framework required |

### Breaking Changes
- None. All changes maintain backward compatibility.

### Migration Notes
- No manual migration required
- Existing configurations remain valid
- Framework detection is automatic

### Testing
- Use `/testfarm` command to validate framework detection
- Check console output for any initialization errors
- Test all farming functions after updating

---

## Previous Versions

### Version 1.0 - Initial Release
- Multi-framework farming system
- Basic ESX, QB-Core, QBX, and Standalone support
- ox_target and ox_inventory compatibility
- Complete farming mechanics with progression system
