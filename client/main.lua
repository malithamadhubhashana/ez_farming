local QBCore, ESX, QBX = nil, nil, nil
local PlayerData = {}
local Framework = nil
local FarmingZones = {}
local PlantedCrops = {}
local ShopPeds = {}
local ConfigReady = false

-- Wait for Config to be available
CreateThread(function()
    while not Config do
        print("[ez_farming] Waiting for Config to load...")
        Wait(100)
    end
    ConfigReady = true
    print("^2[ez_farming]^7 Config loaded successfully!")
end)

-- Framework Detection and Initialization
CreateThread(function()
    -- Wait for Config to be ready
    while not ConfigReady do 
        Wait(100) 
    end
    
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            ESX = exports['es_extended']:getSharedObject()
            while not ESX.IsPlayerLoaded() do Wait(100) end
            PlayerData = ESX.GetPlayerData()
        elseif GetResourceState('qbx_core') == 'started' then
            Framework = 'qbx'
            -- QBX uses exports differently
            local success, playerData = pcall(function()
                return exports.qbx_core:GetPlayerData()
            end)
            if success and playerData then
                PlayerData = playerData
            else
                -- Wait for player to be loaded
                repeat
                    Wait(100)
                    success, playerData = pcall(function()
                        return exports.qbx_core:GetPlayerData()
                    end)
                until success and playerData and playerData.citizenid
                PlayerData = playerData
            end
        elseif GetResourceState('qb-core') == 'started' then
            Framework = 'qb'
            QBCore = exports['qb-core']:GetCoreObject()
            repeat
                Wait(100)
                PlayerData = QBCore.Functions.GetPlayerData()
            until PlayerData and PlayerData.citizenid
        else
            Framework = 'standalone'
        end
    else
        Framework = Config.Framework
        if Framework == 'esx' then
            ESX = exports['es_extended']:getSharedObject()
            while not ESX.IsPlayerLoaded() do Wait(100) end
            PlayerData = ESX.GetPlayerData()
        elseif Framework == 'qbx' then
            local success, playerData = pcall(function()
                return exports.qbx_core:GetPlayerData()
            end)
            if success and playerData then
                PlayerData = playerData
            else
                repeat
                    Wait(100)
                    success, playerData = pcall(function()
                        return exports.qbx_core:GetPlayerData()
                    end)
                until success and playerData and playerData.citizenid
                PlayerData = playerData
            end
        elseif Framework == 'qb' then
            QBCore = exports['qb-core']:GetCoreObject()
            repeat
                Wait(100)
                PlayerData = QBCore.Functions.GetPlayerData()
            until PlayerData and PlayerData.citizenid
        end
    end
    
    print('^2[EZ Farming]^7 Framework detected: ' .. Framework)
    
    -- Initialize after framework is loaded
    InitializeFarming()
end)

-- Framework Event Handlers
if Framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
        TriggerServerEvent('ez_farming:playerLoaded')
    end)
    
    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        PlayerData.job = job
    end)
elseif Framework == 'qb' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
        TriggerServerEvent('ez_farming:playerLoaded')
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)
    
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        PlayerData = val
    end)
elseif Framework == 'qbx' then
    RegisterNetEvent('qbx_core:client:playerLoaded', function()
        PlayerData = exports.qbx_core:GetPlayerData()
        TriggerServerEvent('ez_farming:playerLoaded')
    end)
    
    RegisterNetEvent('qbx_core:client:onJobUpdate', function(jobInfo)
        PlayerData.job = jobInfo
    end)
    
    AddEventHandler('qbx_core:client:playerLoggedOut', function()
        PlayerData = {}
    end)
end

-- Utility Functions
function ShowNotification(configKey, ...)
    local notifConfig = Config.Notifications[configKey]
    if not notifConfig then return end
    
    local message = string.format(notifConfig.message, ...)
    
    if Framework == 'esx' then
        ESX.ShowNotification(message)
    elseif Framework == 'qb' then
        QBCore.Functions.Notify(message, notifConfig.type, notifConfig.duration)
    elseif Framework == 'qbx' then
        exports.qbx_core:Notify(message, notifConfig.type, notifConfig.duration)
    else
        -- Standalone notification
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostMessagetext("CHAR_SOCIAL_CLUB", "CHAR_SOCIAL_CLUB", false, 1, notifConfig.title, "")
    end
end

function HasItem(item, amount)
    amount = amount or 1
    
    -- Inventory system priority: ox_inventory > qb-inventory > framework default
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:Search('count', item) >= amount
    elseif GetResourceState('qb-inventory') == 'started' and Framework == 'qb' then
        -- Use qb-inventory if available
        local hasItem = exports['qb-inventory']:HasItem(item, amount)
        return hasItem ~= nil and hasItem
    elseif Framework == 'esx' then
        local itemCount = ESX.SearchInventory(item, false)
        return itemCount and itemCount >= amount
    elseif Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayerData()
        if not Player or not Player.items then return false end
        
        local totalAmount = 0
        for _, itemData in pairs(Player.items) do
            if itemData.name == item then
                totalAmount = totalAmount + itemData.amount
            end
        end
        return totalAmount >= amount
    elseif Framework == 'qbx' then
        -- QBX primarily uses ox_inventory, but fallback to checking player data
        local Player = exports.qbx_core:GetPlayerData()
        if not Player then return false end
        
        -- Check if ox_inventory is available (should always be for QBX)
        if exports.ox_inventory then
            return exports.ox_inventory:Search('count', item) >= amount
        end
        
        return false -- QBX relies on ox_inventory
    else
        -- Standalone - trigger server event to check
        local hasItem = false
        TriggerServerEvent('ez_farming:checkItem', item, amount)
        return true -- Placeholder
    end
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Main Initialization
function InitializeFarming()
    if not ConfigReady or not Config then
        print("[ez_farming] Config not ready in InitializeFarming")
        return
    end
    
    CreateBlips()
    SetupFarmingZones()
    SetupShops()
    
    -- Request planted crops from server
    TriggerServerEvent('ez_farming:requestPlantedCrops')
    
    -- Trigger drawtext system initialization
    TriggerEvent('ez_farming:clientReady')
    
    -- Start main threads
    CreateThread(MainThread)
    CreateThread(PlantGrowthThread)
end

function CreateBlips()
    if not Config or not Config.FarmingZones or not Config.Shops then
        print("[ez_farming] Config not available for CreateBlips")
        return
    end
    
    for i, zone in ipairs(Config.FarmingZones) do
        if zone.blip and zone.blip.enabled then
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, zone.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, zone.blip.scale)
            SetBlipColour(blip, zone.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(zone.name)
            EndTextCommandSetBlipName(blip)
        end
    end
    
    -- Shop blips
    for i, shop in ipairs(Config.Shops) do
        local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
        SetBlipSprite(blip, 52)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(shop.name)
        EndTextCommandSetBlipName(blip)
    end
end

function SetupFarmingZones()
    if not Config or not Config.FarmingZones then
        print("[ez_farming] Config not available for SetupFarmingZones")
        return
    end
    
    for i, zone in ipairs(Config.FarmingZones) do
        FarmingZones[i] = {
            coords = zone.coords,
            size = zone.size,
            name = zone.name,
            maxPlots = zone.maxPlots,
            allowedCrops = zone.allowedCrops,
            isGreenhouse = zone.isGreenhouse or false
        }
    end
end

function SetupShops()
    if not Config or not Config.Shops then
        print("[ez_farming] Config not available for SetupShops")
        return
    end
    
    for i, shop in ipairs(Config.Shops) do
        if shop.ped then
            local model = GetHashKey(shop.ped.model)
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(1)
            end
            
            local ped = CreatePed(4, model, shop.ped.coords.x, shop.ped.coords.y, shop.ped.coords.z, shop.ped.heading, false, true)
            SetEntityHeading(ped, shop.ped.heading)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            
            ShopPeds[i] = ped
            
            if Config.UseTarget then
                -- Target system integration would go here
                -- exports['qb-target']:AddTargetEntity(ped, options)
            end
        end
    end
end

-- Main interaction thread
function MainThread()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check farming zones
        for i, zone in ipairs(FarmingZones) do
            local distance = #(playerCoords - zone.coords)
            if distance < 50.0 then
                wait = 5
                
                -- Draw zone marker
                DrawMarker(1, zone.coords.x, zone.coords.y, zone.coords.z - 1.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 
                          zone.size.x, zone.size.y, 2.0, 50, 205, 50, 100, false, true, 2, false, false, false, false)
                
                if distance < Config.MaxDistance then
                    if not Config.UseTarget then
                        DrawText3D(zone.coords.x, zone.coords.y, zone.coords.z + 1.0, 
                                  "[E] " .. zone.name .. " - Farming Zone")
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            OpenFarmingMenu(i)
                        end
                    end
                end
            end
        end
        
        -- Check shop interactions
        for i, shop in ipairs(Config.Shops) do
            local distance = #(playerCoords - shop.coords)
            if distance < Config.MaxDistance then
                wait = 5
                if not Config.UseTarget then
                    DrawText3D(shop.coords.x, shop.coords.y, shop.coords.z + 1.0, 
                              "[E] " .. shop.name)
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenShopMenu(i)
                    end
                end
            end
        end
        
        -- Draw planted crops
        for plantId, plant in pairs(PlantedCrops) do
            local distance = #(playerCoords - plant.coords)
            if distance < 20.0 then
                wait = 5
                
                -- Only show markers and text if not using target system
                if not Config.UseTarget or (GetResourceState('ox_target') ~= 'started' and GetResourceState('qb-target') ~= 'started') then
                    -- Draw plant marker based on growth stage
                    local color = {r = 255, g = 0, b = 0} -- Red for not ready
                    if plant.stage >= plant.maxStages then
                        color = {r = 0, g = 255, b = 0} -- Green for ready
                    elseif plant.stage > 1 then
                        color = {r = 255, g = 255, b = 0} -- Yellow for growing
                    end
                    
                    DrawMarker(2, plant.coords.x, plant.coords.y, plant.coords.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 
                              0.3, 0.3, 0.3, color.r, color.g, color.b, 150, true, true, 2, false, false, false, false)
                    
                    if distance < Config.MaxDistance then
                        local cropConfig = Config.Crops[plant.cropType]
                        local text = string.format("[E] %s (Stage %d/%d)", cropConfig.label, plant.stage, plant.maxStages)
                        
                        if plant.needsWater then
                            text = text .. " - Needs Water!"
                        end
                        
                        DrawText3D(plant.coords.x, plant.coords.y, plant.coords.z + 0.5, text)
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            InteractWithPlant(plantId)
                        end
                    end
                else
                    -- Still draw visual markers even with target system
                    local color = {r = 255, g = 0, b = 0} -- Red for not ready
                    if plant.stage >= plant.maxStages then
                        color = {r = 0, g = 255, b = 0} -- Green for ready
                    elseif plant.stage > 1 then
                        color = {r = 255, g = 255, b = 0} -- Yellow for growing
                    end
                    
                    DrawMarker(2, plant.coords.x, plant.coords.y, plant.coords.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 
                              0.3, 0.3, 0.3, color.r, color.g, color.b, 100, true, true, 2, false, false, false, false)
                end
            end
        end
        
        Wait(wait)
    end
end

-- Plant growth monitoring thread
function PlantGrowthThread()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        for plantId, plant in pairs(PlantedCrops) do
            if plant.stage < plant.maxStages then
                local currentTime = GetGameTimer()
                local timeSinceLastGrowth = currentTime - (plant.lastGrowthTime or plant.plantTime)
                
                local cropConfig = Config.Crops[plant.cropType]
                local growthTime = cropConfig.growthTime * 1000 -- Convert to milliseconds
                
                -- Apply bonuses/penalties
                if plant.fertilized then
                    growthTime = growthTime * (1 - Config.FertilizerBonus)
                end
                
                if timeSinceLastGrowth >= growthTime then
                    -- Plant should grow
                    TriggerServerEvent('ez_farming:growPlant', plantId)
                end
                
                -- Check if plant needs water
                if cropConfig.waterNeeded and not plant.needsWater then
                    local timeSinceWater = currentTime - (plant.lastWaterTime or plant.plantTime)
                    if timeSinceWater >= (Config.WateringInterval * 1000) then
                        plant.needsWater = true
                        TriggerServerEvent('ez_farming:updatePlantWater', plantId, true)
                    end
                end
            end
        end
    end
end

-- Farming menu functions
function OpenFarmingMenu(zoneIndex)
    if not Config then 
        print("[ez_farming] Config not loaded yet, please try again...")
        if Framework and Framework == 'qb' then
            QBCore.Functions.Notify("System not ready yet, please try again...", "error")
        elseif Framework and Framework == 'esx' then
            ESX.ShowNotification("System not ready yet, please try again...")
        else
            -- Standalone notification
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName("System not ready yet, please try again...")
            EndTextCommandThefeedPostTicker(false, true)
        end
        return 
    end
    
    if not Config.Crops then
        print("[ez_farming] Config.Crops not available")
        return
    end
    
    local zone = FarmingZones[zoneIndex]
    if not zone then
        print("[ez_farming] Invalid zone index: " .. tostring(zoneIndex))
        return
    end
    
    local elements = {}
    
    -- Add plant option for each allowed crop
    for _, cropType in ipairs(zone.allowedCrops) do
        local cropConfig = Config.Crops[cropType]
        if cropConfig and HasItem(cropConfig.seedItem) then
            table.insert(elements, {
                label = "Plant " .. cropConfig.label,
                value = "plant_" .. cropType,
                cropType = cropType
            })
        end
    end
    
    table.insert(elements, {
        label = "View Zone Info",
        value = "zone_info"
    })
    
    -- Framework-specific menu opening
    if Framework == 'esx' then
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'farming_menu', {
            title = zone.name,
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            if data.current.value == 'zone_info' then
                ShowZoneInfo(zoneIndex)
            elseif string.find(data.current.value, 'plant_') then
                PlantCrop(data.current.cropType, zoneIndex)
                menu.close()
            end
        end, function(data, menu)
            menu.close()
        end)
    else
        -- For QB/QBX/Standalone, you could use ox_lib menu or custom menu
        TriggerEvent('ez_farming:openCustomMenu', {
            title = zone.name,
            elements = elements,
            zoneIndex = zoneIndex
        })
    end
end

function ShowZoneInfo(zoneIndex)
    local zone = FarmingZones[zoneIndex]
    local plotsUsed = 0
    
    for _, plant in pairs(PlantedCrops) do
        if plant.zoneIndex == zoneIndex then
            plotsUsed = plotsUsed + 1
        end
    end
    
    local info = string.format(
        "Zone: %s\nPlots Used: %d/%d\nAllowed Crops: %s",
        zone.name,
        plotsUsed,
        zone.maxPlots,
        table.concat(zone.allowedCrops, ", ")
    )
    
    ShowNotification('zone_info', info)
end

function PlantCrop(cropType, zoneIndex)
    if not Config or not Config.Crops or not Config.Tools then
        print("[ez_farming] Config not fully loaded for PlantCrop")
        return
    end
    
    local zone = FarmingZones[zoneIndex]
    local cropConfig = Config.Crops[cropType]
    
    if not cropConfig then
        print("[ez_farming] Invalid crop type: " .. tostring(cropType))
        return
    end
    
    -- Check if player has the required tool
    if not HasItem(Config.Tools.hoe.item) then
        ShowNotification('no_tool', Config.Tools.hoe.label)
        return
    end
    
    -- Check if player has seeds
    if not HasItem(cropConfig.seedItem) then
        ShowNotification('no_seeds')
        return
    end
    
    -- Find a suitable planting spot
    local playerCoords = GetEntityCoords(PlayerPedId())
    local plantCoords = GetSuitablePlantingSpot(playerCoords, zoneIndex)
    
    if plantCoords then
        TriggerServerEvent('ez_farming:plantCrop', {
            cropType = cropType,
            coords = plantCoords,
            zoneIndex = zoneIndex
        })
    else
        ShowNotification('plot_occupied')
    end
end

function GetSuitablePlantingSpot(playerCoords, zoneIndex)
    local zone = FarmingZones[zoneIndex]
    
    -- Simple grid-based planting system
    for x = -zone.size.x/2, zone.size.x/2, 2.0 do
        for y = -zone.size.y/2, zone.size.y/2, 2.0 do
            local testCoords = vector3(
                zone.coords.x + x,
                zone.coords.y + y,
                zone.coords.z
            )
            
            -- Check if spot is occupied
            local occupied = false
            for _, plant in pairs(PlantedCrops) do
                if #(plant.coords - testCoords) < 1.5 then
                    occupied = true
                    break
                end
            end
            
            if not occupied and #(playerCoords - testCoords) < 3.0 then
                return testCoords
            end
        end
    end
    
    return nil
end

function InteractWithPlant(plantId)
    local plant = PlantedCrops[plantId]
    if not plant then return end
    
    local cropConfig = Config.Crops[plant.cropType]
    
    if plant.stage >= plant.maxStages then
        -- Ready to harvest
        if HasItem(Config.Tools.hoe.item) then
            TriggerServerEvent('ez_farming:harvestCrop', plantId)
        else
            ShowNotification('no_tool', Config.Tools.hoe.label)
        end
    elseif plant.needsWater then
        -- Needs watering
        if HasItem(Config.Tools.watering_can.item) then
            TriggerServerEvent('ez_farming:waterPlant', plantId)
        else
            ShowNotification('no_tool', Config.Tools.watering_can.label)
        end
    elseif cropConfig.fertilizerCompatible and not plant.fertilized and HasItem(Config.Tools.fertilizer.item) then
        -- Can be fertilized
        TriggerServerEvent('ez_farming:fertilizePlant', plantId)
    else
        ShowNotification('not_ready')
    end
end

function OpenShopMenu(shopIndex)
    local shop = Config.Shops[shopIndex]
    local elements = {}
    
    for _, item in ipairs(shop.items) do
        local label = item.item .. " - $" .. item.price
        if item.stock and item.stock > 0 then
            label = label .. " (Stock: " .. item.stock .. ")"
        end
        
        table.insert(elements, {
            label = label,
            value = item.item,
            price = item.price,
            sellOnly = shop.sellOnly
        })
    end
    
    -- Open shop menu based on framework
    TriggerEvent('ez_farming:openShopMenu', {
        title = shop.name,
        elements = elements,
        shopIndex = shopIndex
    })
end

-- Network Events
RegisterNetEvent('ez_farming:updatePlantedCrops')
AddEventHandler('ez_farming:updatePlantedCrops', function(crops)
    PlantedCrops = crops
end)

RegisterNetEvent('ez_farming:plantSuccess')
AddEventHandler('ez_farming:plantSuccess', function(plantData)
    PlantedCrops[plantData.id] = plantData
    
    -- Safe config access
    local cropLabel = 'Unknown Crop'
    if Config and Config.Crops and Config.Crops[plantData.cropType] and Config.Crops[plantData.cropType].label then
        cropLabel = Config.Crops[plantData.cropType].label
    end
    
    ShowNotification('plant_success', cropLabel)
end)

RegisterNetEvent('ez_farming:harvestSuccess')
AddEventHandler('ez_farming:harvestSuccess', function(plantId, harvestData)
    PlantedCrops[plantId] = nil
    
    -- Safe config access
    local cropLabel = 'Unknown Crop'
    if Config and Config.Crops and Config.Crops[harvestData.cropType] and Config.Crops[harvestData.cropType].label then
        cropLabel = Config.Crops[harvestData.cropType].label
    end
    
    ShowNotification('harvest_success', cropLabel, harvestData.amount)
end)

RegisterNetEvent('ez_farming:waterSuccess')
AddEventHandler('ez_farming:waterSuccess', function(plantId)
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].needsWater = false
        PlantedCrops[plantId].lastWaterTime = GetGameTimer()
    end
    ShowNotification('water_success')
end)

RegisterNetEvent('ez_farming:fertilizeSuccess')
AddEventHandler('ez_farming:fertilizeSuccess', function(plantId)
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].fertilized = true
    end
    ShowNotification('fertilize_success')
end)

RegisterNetEvent('ez_farming:plantGrown')
AddEventHandler('ez_farming:plantGrown', function(plantId, newStage)
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].stage = newStage
        PlantedCrops[plantId].lastGrowthTime = GetGameTimer()
    end
end)

RegisterNetEvent('ez_farming:levelUp')
AddEventHandler('ez_farming:levelUp', function(newLevel)
    ShowNotification('level_up', newLevel)
end)

-- Commands
RegisterCommand(Config.Commands.farming_stats.command, function()
    TriggerServerEvent('ez_farming:getPlayerStats')
end, false)

RegisterNetEvent('ez_farming:showPlayerStats')
AddEventHandler('ez_farming:showPlayerStats', function(stats)
    local text = string.format(
        "Farming Level: %d\nExperience: %d\nTotal Plants: %d\nTotal Harvests: %d",
        stats.level or 1,
        stats.experience or 0,
        stats.totalPlants or 0,
        stats.totalHarvests or 0
    )
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"Farming Stats", text}
    })
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, ped in pairs(ShopPeds) do
            DeleteEntity(ped)
        end
    end
end)
