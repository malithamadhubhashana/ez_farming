-- Enhanced Debug script to test Config loading and error tracking
print("^3[DEBUG] Starting enhanced Config debug test...")

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print("^1[DEBUG ERROR] " .. tostring(result))
        return false, result
    end
    return true, result
end

CreateThread(function()
    local attempts = 0
    local maxAttempts = 100
    
    while not Config and attempts < maxAttempts do
        attempts = attempts + 1
        if attempts % 10 == 0 then
            print("^3[DEBUG] Attempt " .. attempts .. ": Still waiting for Config...")
        end
        Wait(50)
    end
    
    if Config then
        print("^2[DEBUG] ✅ Config loaded successfully after " .. attempts .. " attempts")
        print("^2[DEBUG] Config.Framework = " .. tostring(Config.Framework))
        print("^2[DEBUG] Config.Debug = " .. tostring(Config.Debug))
        print("^2[DEBUG] Config.Crops exists = " .. tostring(Config.Crops ~= nil))
        if Config.Crops then
            print("^2[DEBUG] Available crops:")
            for cropType, cropData in pairs(Config.Crops) do
                print("^2[DEBUG]   - " .. cropType .. " (label: " .. tostring(cropData.label) .. ")")
            end
        end
        print("^2[DEBUG] Config.FarmingZones exists = " .. tostring(Config.FarmingZones ~= nil))
        if Config.FarmingZones then
            print("^2[DEBUG] Number of farming zones: " .. #Config.FarmingZones)
        end
        
        -- Test framework detection
        Wait(2000) -- Wait a bit more for framework to initialize
        print("^2[DEBUG] Framework detection test:")
        local esxState = GetResourceState('es_extended')
        local qbState = GetResourceState('qb-core')
        local qbxState = GetResourceState('qbx_core')
        print("^2[DEBUG] ESX State: " .. esxState)
        print("^2[DEBUG] QB-Core State: " .. qbState)
        print("^2[DEBUG] QBX State: " .. qbxState)
        
    else
        print("^1[DEBUG] ❌ Config failed to load after " .. maxAttempts .. " attempts")
    end
end)

-- Test event handlers
RegisterNetEvent('ez_farming:debugTest')
AddEventHandler('ez_farming:debugTest', function()
    print("^3[DEBUG] Testing farming menu opening...")
    if not Config then
        print("^1[DEBUG] Config is nil when trying to open menu!")
        return
    end
    
    if not Config.Crops then
        print("^1[DEBUG] Config.Crops is nil when trying to open menu!")
        return
    end
    
    if not Config.FarmingZones then
        print("^1[DEBUG] Config.FarmingZones is nil when trying to open menu!")
        return
    end
    
    print("^2[DEBUG] Config checks passed, attempting to open farming menu...")
    
    -- Try to call OpenFarmingMenu safely
    local success, error = SafeCall(function()
        if OpenFarmingMenu then
            OpenFarmingMenu(1) -- Try zone 1
        else
            print("^1[DEBUG] OpenFarmingMenu function not found!")
        end
    end)
    
    if not success then
        print("^1[DEBUG] Error calling OpenFarmingMenu: " .. tostring(error))
    else
        print("^2[DEBUG] OpenFarmingMenu called successfully")
    end
end)

-- Command to test specific functionality
RegisterCommand('testfarming', function()
    print("^3[DEBUG] Testing farming system...")
    TriggerEvent('ez_farming:debugTest')
end, false)

-- Command to test menu directly
RegisterCommand('testmenu', function()
    print("^3[DEBUG] Testing menu opening directly...")
    if Config and Config.FarmingZones and Config.FarmingZones[1] then
        local success, error = SafeCall(function()
            TriggerEvent('ez_farming:openFarmingMenuTarget', {zoneIndex = 1})
        end)
        if not success then
            print("^1[DEBUG] Error opening menu: " .. tostring(error))
        end
    else
        print("^1[DEBUG] Config or FarmingZones not available")
    end
end, false)

-- Monitor for errors
local originalPrint = print
print = function(...)
    local args = {...}
    local message = table.concat(args, " ")
    if string.find(string.lower(message), "error") or string.find(string.lower(message), "nil") then
        originalPrint("^1[ERROR DETECTED] " .. message)
    else
        originalPrint(...)
    end
end

print("^2[DEBUG] Enhanced debug script loaded. Commands: /testfarming, /testmenu")
