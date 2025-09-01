-- Framework Test Validation Script
-- This file can be used to test framework detection and basic functions

local function TestFrameworkDetection()
    print("^2[EZ Farming] ^7Testing Framework Detection...")
    
    -- Test ESX
    if GetResourceState('es_extended') == 'started' then
        print("^3ESX detected: es_extended is running")
        local ESX = exports['es_extended']:getSharedObject()
        if ESX then
            print("^2ESX shared object loaded successfully")
        else
            print("^1ESX shared object failed to load")
        end
    else
        print("^7ESX not detected")
    end
    
    -- Test QB-Core
    if GetResourceState('qb-core') == 'started' then
        print("^3QB-Core detected: qb-core is running")
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            print("^2QB-Core object loaded successfully")
        else
            print("^1QB-Core object failed to load")
        end
    else
        print("^7QB-Core not detected")
    end
    
    -- Test QBX
    if GetResourceState('qbx_core') == 'started' then
        print("^3QBX detected: qbx_core is running")
        -- QBX doesn't use a core object, just test exports
        local success, result = pcall(function()
            return exports.qbx_core
        end)
        if success and result then
            print("^2QBX exports are accessible")
        else
            print("^1QBX exports failed to load")
        end
    else
        print("^7QBX not detected")
    end
    
    -- Test ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        print("^3ox_inventory detected and running")
        local success, result = pcall(function()
            return exports.ox_inventory
        end)
        if success and result then
            print("^2ox_inventory exports are accessible")
        else
            print("^1ox_inventory exports failed to load")
        end
    else
        print("^7ox_inventory not detected")
    end
    
    -- Test qb-inventory
    if GetResourceState('qb-inventory') == 'started' then
        print("^3qb-inventory detected and running")
        local success, result = pcall(function()
            return exports['qb-inventory']
        end)
        if success and result then
            print("^2qb-inventory exports are accessible")
        else
            print("^1qb-inventory exports failed to load")
        end
    else
        print("^7qb-inventory not detected")
    end
    
    -- Test ox_target
    if GetResourceState('ox_target') == 'started' then
        print("^3ox_target detected and running")
    elseif GetResourceState('qb-target') == 'started' then
        print("^3qb-target detected and running")
    else
        print("^7No target system detected")
    end
    
    -- Test drawtext systems
    if GetResourceState('ox_lib') == 'started' then
        print("^3ox_lib detected and running (supports drawtext)")
    elseif GetResourceState('qb-drawtext') == 'started' then
        print("^3qb-drawtext detected and running")
    else
        print("^7No advanced drawtext system detected - using native")
    end
end

-- Framework-specific function tests
local function TestFrameworkFunctions()
    print("^2[EZ Farming] ^7Testing Framework Functions...")
    
    -- Test player data retrieval (client-side)
    CreateThread(function()
        Wait(5000) -- Wait for frameworks to load
        
        if GetResourceState('es_extended') == 'started' then
            local ESX = exports['es_extended']:getSharedObject()
            if ESX and ESX.IsPlayerLoaded() then
                local playerData = ESX.GetPlayerData()
                print("^2ESX Player Data loaded: " .. (playerData.identifier or "unknown"))
            end
        end
        
        if GetResourceState('qb-core') == 'started' then
            local QBCore = exports['qb-core']:GetCoreObject()
            if QBCore and QBCore.Functions.GetPlayerData then
                local playerData = QBCore.Functions.GetPlayerData()
                if playerData and playerData.citizenid then
                    print("^2QB-Core Player Data loaded: " .. playerData.citizenid)
                end
            end
        end
        
        if GetResourceState('qbx_core') == 'started' then
            local success, playerData = pcall(function()
                return exports.qbx_core:GetPlayerData()
            end)
            if success and playerData and playerData.citizenid then
                print("^2QBX Player Data loaded: " .. playerData.citizenid)
            end
        end
    end)
end

-- Test inventory functions
local function TestInventoryFunctions()
    print("^2[EZ Farming] ^7Testing Inventory Functions...")
    
    CreateThread(function()
        Wait(5000)
        
        -- Test ox_inventory
        if GetResourceState('ox_inventory') == 'started' then
            local success, result = pcall(function()
                return exports.ox_inventory.AddItem ~= nil
            end)
            if success then
                print("^2ox_inventory AddItem function is available")
            else
                print("^1ox_inventory AddItem function is not available")
            end
        end
        
        -- Test qb-inventory
        if GetResourceState('qb-inventory') == 'started' then
            local success, result = pcall(function()
                return exports['qb-inventory'].AddItem ~= nil
            end)
            if success then
                print("^2qb-inventory AddItem function is available")
            else
                print("^1qb-inventory AddItem function is not available")
            end
        end
    end)
end

-- Auto-run tests when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(2000) -- Wait for other resources to start
        TestFrameworkDetection()
        TestFrameworkFunctions()
        TestInventoryFunctions()
    end
end)

-- Manual test command
RegisterCommand('testfarm', function(source, args)
    TestFrameworkDetection()
    TestFrameworkFunctions()
    TestInventoryFunctions()
end, false)
