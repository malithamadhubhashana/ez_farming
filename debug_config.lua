-- Debug script to test Config loading
print("^3[DEBUG] Starting Config debug test...")

CreateThread(function()
    local attempts = 0
    local maxAttempts = 50
    
    while not Config and attempts < maxAttempts do
        attempts = attempts + 1
        print("^3[DEBUG] Attempt " .. attempts .. ": Config = " .. tostring(Config))
        Wait(100)
    end
    
    if Config then
        print("^2[DEBUG] ✅ Config loaded successfully after " .. attempts .. " attempts")
        print("^2[DEBUG] Config.Framework = " .. tostring(Config.Framework))
        print("^2[DEBUG] Config.Debug = " .. tostring(Config.Debug))
        print("^2[DEBUG] Config.Crops exists = " .. tostring(Config.Crops ~= nil))
        if Config.Crops then
            print("^2[DEBUG] Available crops:")
            for cropType, _ in pairs(Config.Crops) do
                print("^2[DEBUG]   - " .. cropType)
            end
        end
        print("^2[DEBUG] Config.FarmingZones exists = " .. tostring(Config.FarmingZones ~= nil))
        if Config.FarmingZones then
            print("^2[DEBUG] Number of farming zones: " .. #Config.FarmingZones)
        end
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
    
    print("^2[DEBUG] Config checks passed, menu should work now")
end)

-- Command to test
RegisterCommand('testfarming', function()
    print("^3[DEBUG] Testing farming system...")
    TriggerEvent('ez_farming:debugTest')
end, false)

print("^2[DEBUG] Debug script loaded. Use /testfarming to test the system")
