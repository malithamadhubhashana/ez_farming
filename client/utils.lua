-- Advanced client utilities and additional features
local CurrentWeather = 'CLEAR'
local CurrentSeason = 'spring'
local FarmingUI = {
    isOpen = false,
    currentMenu = nil
}

-- Weather sync
RegisterNetEvent('ez_farming:weatherSync')
AddEventHandler('ez_farming:weatherSync', function(weather)
    CurrentWeather = weather
end)

RegisterNetEvent('ez_farming:seasonChanged')
AddEventHandler('ez_farming:seasonChanged', function(season)
    CurrentSeason = season
    ShowNotification('season_change', 'Season changed to ' .. season)
end)

-- Custom Menu System (for non-ESX frameworks)
RegisterNetEvent('ez_farming:openCustomMenu')
AddEventHandler('ez_farming:openCustomMenu', function(menuData)
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    FarmingUI.currentMenu = menuData
    
    -- Send NUI message for custom UI
    SendNUIMessage({
        type = 'openMenu',
        data = menuData
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('ez_farming:openShopMenu')
AddEventHandler('ez_farming:openShopMenu', function(shopData)
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    
    SendNUIMessage({
        type = 'openShop',
        data = shopData
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('ez_farming:openAdminMenu')
AddEventHandler('ez_farming:openAdminMenu', function()
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    
    local adminData = {
        title = 'Farming Admin Panel',
        options = {
            {label = 'View All Plants', value = 'view_plants'},
            {label = 'Remove All Plants', value = 'remove_all'},
            {label = 'Set Season', value = 'set_season'},
            {label = 'Set Weather', value = 'set_weather'},
            {label = 'Player Stats', value = 'player_stats'},
            {label = 'Reload Config', value = 'reload_config'}
        }
    }
    
    SendNUIMessage({
        type = 'openAdmin',
        data = adminData
    })
    SetNuiFocus(true, true)
end)

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    FarmingUI.isOpen = false
    FarmingUI.currentMenu = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('menuAction', function(data, cb)
    local action = data.action
    local value = data.value
    
    if FarmingUI.currentMenu then
        if string.find(action, 'plant_') then
            local cropType = string.gsub(action, 'plant_', '')
            PlantCrop(cropType, FarmingUI.currentMenu.zoneIndex)
        elseif action == 'zone_info' then
            ShowZoneInfo(FarmingUI.currentMenu.zoneIndex)
        end
    end
    
    FarmingUI.isOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('shopAction', function(data, cb)
    local action = data.action -- 'buy' or 'sell'
    local item = data.item
    local amount = data.amount or 1
    local shopIndex = data.shopIndex
    
    if action == 'buy' then
        TriggerServerEvent('ez_farming:buyItem', shopIndex, item, amount)
    elseif action == 'sell' then
        TriggerServerEvent('ez_farming:sellItem', shopIndex, item, amount)
    end
    
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    local action = data.action
    local value = data.value
    
    if action == 'view_plants' then
        TriggerServerEvent('ez_farming:adminViewPlants')
    elseif action == 'remove_all' then
        TriggerServerEvent('ez_farming:adminRemoveAll')
    elseif action == 'set_season' then
        TriggerServerEvent('ez_farming:adminSetSeason', value)
    elseif action == 'set_weather' then
        TriggerServerEvent('ez_farming:adminSetWeather', value)
    elseif action == 'player_stats' then
        TriggerServerEvent('ez_farming:adminPlayerStats', value)
    elseif action == 'reload_config' then
        TriggerServerEvent('ez_farming:adminReloadConfig')
    end
    
    cb('ok')
end)

-- Plant visual effects system
function CreatePlantObject(plantId, plant)
    local cropConfig = Config.Crops[plant.cropType]
    if not cropConfig or not cropConfig.model then return end
    
    local model = GetHashKey(cropConfig.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local object = CreateObject(model, plant.coords.x, plant.coords.y, plant.coords.z, false, false, false)
    SetEntityHeading(object, math.random(0, 360))
    
    -- Scale based on growth stage
    local scale = 0.3 + (plant.stage / plant.maxStages * 0.7)
    SetEntityScale(object, scale, scale, scale)
    
    -- Store object reference
    if not PlantObjects then PlantObjects = {} end
    PlantObjects[plantId] = object
    
    return object
end

function UpdatePlantVisuals()
    if not PlantObjects then PlantObjects = {} end
    
    for plantId, plant in pairs(PlantedCrops) do
        if PlantObjects[plantId] then
            -- Update existing plant visual
            local scale = 0.3 + (plant.stage / plant.maxStages * 0.7)
            SetEntityScale(PlantObjects[plantId], scale, scale, scale)
        else
            -- Create new plant visual
            CreatePlantObject(plantId, plant)
        end
    end
    
    -- Remove objects for harvested plants
    for plantId, object in pairs(PlantObjects) do
        if not PlantedCrops[plantId] then
            DeleteEntity(object)
            PlantObjects[plantId] = nil
        end
    end
end

-- Enhanced plant interaction system
function GetPlantInteractionOptions(plantId)
    local plant = PlantedCrops[plantId]
    if not plant then return {} end
    
    local options = {}
    local cropConfig = Config.Crops[plant.cropType]
    
    if plant.stage >= plant.maxStages then
        table.insert(options, {
            label = 'Harvest ' .. cropConfig.label,
            icon = 'fas fa-hand-paper',
            action = function()
                if HasItem(Config.Tools.hoe.item) then
                    TriggerServerEvent('ez_farming:harvestCrop', plantId)
                else
                    ShowNotification('no_tool', Config.Tools.hoe.label)
                end
            end
        })
    end
    
    if plant.needsWater then
        table.insert(options, {
            label = 'Water Plant',
            icon = 'fas fa-tint',
            action = function()
                if HasItem(Config.Tools.watering_can.item) then
                    TriggerServerEvent('ez_farming:waterPlant', plantId)
                    -- Play watering animation
                    PlayWateringAnimation()
                else
                    ShowNotification('no_tool', Config.Tools.watering_can.label)
                end
            end
        })
    end
    
    if cropConfig.fertilizerCompatible and not plant.fertilized and HasItem(Config.Tools.fertilizer.item) then
        table.insert(options, {
            label = 'Apply Fertilizer',
            icon = 'fas fa-seedling',
            action = function()
                TriggerServerEvent('ez_farming:fertilizePlant', plantId)
                PlayFertilizingAnimation()
            end
        })
    end
    
    table.insert(options, {
        label = 'Plant Information',
        icon = 'fas fa-info-circle',
        action = function()
            ShowPlantInfo(plant)
        end
    })
    
    return options
end

-- Animation system
function PlayPlantingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(playerPed)
end

function PlayWateringAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    -- Create watering can prop
    local prop = CreateObject(GetHashKey('prop_wateringcan'), 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(3000)
    
    DeleteEntity(prop)
    ClearPedTasks(playerPed)
end

function PlayFertilizingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
end

function PlayHarvestingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(4000)
    ClearPedTasks(playerPed)
end

-- Information display system
function ShowPlantInfo(plant)
    local cropConfig = Config.Crops[plant.cropType]
    local growthProgress = math.floor((plant.stage / plant.maxStages) * 100)
    
    local info = string.format([[
<div style="background: rgba(0,0,0,0.8); color: white; padding: 20px; border-radius: 10px; max-width: 300px;">
    <h3>%s</h3>
    <p><strong>Growth:</strong> Stage %d/%d (%d%%)</p>
    <p><strong>Status:</strong> %s</p>
    <p><strong>Watered:</strong> %s</p>
    <p><strong>Fertilized:</strong> %s</p>
    <p><strong>Season:</strong> %s</p>
    <p><strong>Weather Effects:</strong> %s</p>
</div>
    ]], 
    cropConfig.label,
    plant.stage, plant.maxStages, growthProgress,
    plant.stage >= plant.maxStages and "Ready to Harvest" or "Growing",
    plant.needsWater and "No" or "Yes",
    plant.fertilized and "Yes" or "No",
    CurrentSeason,
    GetWeatherEffectDescription()
    )
    
    SendNUIMessage({
        type = 'showInfo',
        data = {
            html = info,
            duration = 10000
        }
    })
end

function GetWeatherEffectDescription()
    local effects = Config.Weather.effects[CurrentWeather]
    if not effects then return "None" end
    
    local descriptions = {}
    
    if effects.growth_bonus then
        table.insert(descriptions, string.format("+%.0f%% Growth", effects.growth_bonus * 100))
    end
    if effects.growth_penalty then
        table.insert(descriptions, string.format("-%.0f%% Growth", effects.growth_penalty * 100))
    end
    if effects.water_bonus then
        table.insert(descriptions, string.format("+%.0f%% Water Eff.", effects.water_bonus * 100))
    end
    if effects.water_penalty then
        table.insert(descriptions, string.format("-%.0f%% Water Eff.", effects.water_penalty * 100))
    end
    
    return #descriptions > 0 and table.concat(descriptions, ", ") or "None"
end

-- Enhanced notification system
RegisterNetEvent('ez_farming:notify')
AddEventHandler('ez_farming:notify', function(message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if Framework == 'esx' then
        ESX.ShowNotification(message)
    elseif Framework == 'qb' then
        QBCore.Functions.Notify(message, type, duration)
    elseif Framework == 'qbx' then
        exports.qbx_core:Notify(message, type, duration)
    else
        -- Custom notification for standalone
        SendNUIMessage({
            type = 'notification',
            data = {
                message = message,
                type = type,
                duration = duration
            }
        })
    end
end)

-- Farming statistics tracking
local FarmingStats = {
    plantsWatered = 0,
    plantsFertilized = 0,
    plantsHarvested = 0,
    sessionTime = 0
}

CreateThread(function()
    while true do
        Wait(60000) -- Update every minute
        FarmingStats.sessionTime = FarmingStats.sessionTime + 1
        
        -- Send stats to server every 5 minutes
        if FarmingStats.sessionTime % 5 == 0 then
            TriggerServerEvent('ez_farming:updateSessionStats', FarmingStats)
        end
    end
end)

-- Event handlers for stat tracking
RegisterNetEvent('ez_farming:waterSuccess')
AddEventHandler('ez_farming:waterSuccess', function(plantId)
    FarmingStats.plantsWatered = FarmingStats.plantsWatered + 1
    -- Original water success logic
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].needsWater = false
        PlantedCrops[plantId].lastWaterTime = GetGameTimer()
    end
    ShowNotification('water_success')
end)

RegisterNetEvent('ez_farming:fertilizeSuccess')
AddEventHandler('ez_farming:fertilizeSuccess', function(plantId)
    FarmingStats.plantsFertilized = FarmingStats.plantsFertilized + 1
    -- Original fertilize success logic
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].fertilized = true
    end
    ShowNotification('fertilize_success')
end)

RegisterNetEvent('ez_farming:harvestSuccess')
AddEventHandler('ez_farming:harvestSuccess', function(plantId, harvestData)
    FarmingStats.plantsHarvested = FarmingStats.plantsHarvested + 1
    -- Original harvest success logic
    PlantedCrops[plantId] = nil
    ShowNotification('harvest_success', Config.Crops[harvestData.cropType].label, harvestData.amount)
    
    -- Play harvest animation and effects
    PlayHarvestingAnimation()
end)

-- Visual effects system
CreateThread(function()
    while true do
        Wait(5000) -- Update visuals every 5 seconds
        UpdatePlantVisuals()
    end
end)

-- Target system integration (if qb-target or ox_target is available)
CreateThread(function()
    if not Config.UseTarget then return end
    
    Wait(2000) -- Wait for resources to load
    
    local targetResource = nil
    if GetResourceState('ox_target') == 'started' then
        targetResource = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        targetResource = 'qb-target'
    end
    
    if not targetResource then
        print('^3[EZ Farming]^7 No target system found, using drawtext system')
        return
    end
    
    print('^2[EZ Farming]^7 Using target system: ' .. targetResource)
    
    -- Add target zones for farming areas
    for i, zone in ipairs(Config.FarmingZones) do
        local options = {
            {
                name = "ez_farming_zone_" .. i,
                icon = "fas fa-seedling",
                label = "Open Farming Menu",
                onSelect = function()
                    OpenFarmingMenu(i)
                end,
                distance = Config.MaxDistance
            }
        }
        
        if targetResource == 'ox_target' then
            exports.ox_target:addBoxZone({
                coords = zone.coords,
                size = zone.size,
                rotation = zone.rotation or 0,
                debug = Config.Debug,
                options = options
            })
        elseif targetResource == 'qb-target' then
            exports['qb-target']:AddBoxZone("farming_zone_" .. i, zone.coords, zone.size.x, zone.size.y, {
                name = "farming_zone_" .. i,
                heading = zone.rotation or 0,
                debugPoly = Config.Debug,
                minZ = zone.coords.z - zone.size.z/2,
                maxZ = zone.coords.z + zone.size.z/2,
            }, {
                options = {
                    {
                        type = "client",
                        event = "ez_farming:openFarmingMenuTarget",
                        icon = "fas fa-seedling",
                        label = "Open Farming Menu",
                        zoneIndex = i
                    }
                },
                distance = Config.MaxDistance
            })
        end
    end
    
    -- Add target for shop peds
    for i, shop in ipairs(Config.Shops) do
        if shop.ped then
            CreateThread(function()
                Wait(3000) -- Wait for peds to spawn
                local ped = ShopPeds[i]
                if ped and DoesEntityExist(ped) then
                    local options = {
                        {
                            name = "ez_farming_shop_" .. i,
                            icon = "fas fa-shopping-cart",
                            label = "Open " .. shop.name,
                            onSelect = function()
                                OpenShopMenu(i)
                            end,
                            distance = Config.MaxDistance
                        }
                    }
                    
                    if targetResource == 'ox_target' then
                        exports.ox_target:addLocalEntity(ped, options)
                    elseif targetResource == 'qb-target' then
                        exports['qb-target']:AddTargetEntity(ped, {
                            options = {
                                {
                                    type = "client",
                                    event = "ez_farming:openShopMenuTarget",
                                    icon = "fas fa-shopping-cart",
                                    label = "Open " .. shop.name,
                                    shopIndex = i
                                }
                            },
                            distance = Config.MaxDistance
                        })
                    end
                end
            end)
        end
    end
    
    -- Add dynamic targets for planted crops
    CreateThread(function()
        local addedTargets = {}
        
        while true do
            Wait(5000) -- Check every 5 seconds
            
            -- Remove targets for harvested plants
            for plantId, _ in pairs(addedTargets) do
                if not PlantedCrops[plantId] then
                    if targetResource == 'ox_target' then
                        exports.ox_target:removeZone('plant_' .. plantId)
                    elseif targetResource == 'qb-target' then
                        exports['qb-target']:RemoveZone('plant_' .. plantId)
                    end
                    addedTargets[plantId] = nil
                end
            end
            
            -- Add targets for new plants
            local playerCoords = GetEntityCoords(PlayerPedId())
            for plantId, plant in pairs(PlantedCrops) do
                if not addedTargets[plantId] and #(playerCoords - plant.coords) < 50.0 then
                    local cropConfig = Config.Crops[plant.cropType]
                    local options = {}
                    
                    if plant.stage >= plant.maxStages then
                        table.insert(options, {
                            name = "harvest_plant",
                            icon = "fas fa-hand-paper",
                            label = "Harvest " .. cropConfig.label,
                            onSelect = function()
                                InteractWithPlant(plantId)
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.hoe.item)
                            end
                        })
                    end
                    
                    if plant.needsWater then
                        table.insert(options, {
                            name = "water_plant",
                            icon = "fas fa-tint",
                            label = "Water Plant",
                            onSelect = function()
                                if HasItem(Config.Tools.watering_can.item) then
                                    TriggerServerEvent('ez_farming:waterPlant', plantId)
                                    PlayWateringAnimation()
                                else
                                    ShowNotification('no_tool', Config.Tools.watering_can.label)
                                end
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.watering_can.item)
                            end
                        })
                    end
                    
                    if cropConfig.fertilizerCompatible and not plant.fertilized and HasItem(Config.Tools.fertilizer.item) then
                        table.insert(options, {
                            name = "fertilize_plant",
                            icon = "fas fa-seedling",
                            label = "Apply Fertilizer",
                            onSelect = function()
                                TriggerServerEvent('ez_farming:fertilizePlant', plantId)
                                PlayFertilizingAnimation()
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.fertilizer.item)
                            end
                        })
                    end
                    
                    table.insert(options, {
                        name = "plant_info",
                        icon = "fas fa-info-circle",
                        label = "Plant Information",
                        onSelect = function()
                            ShowPlantInfo(plant)
                        end
                    })
                    
                    if #options > 0 then
                        if targetResource == 'ox_target' then
                            exports.ox_target:addSphereZone({
                                coords = plant.coords,
                                radius = 1.0,
                                debug = Config.Debug,
                                options = options
                            })
                        elseif targetResource == 'qb-target' then
                            exports['qb-target']:AddCircleZone('plant_' .. plantId, plant.coords, 1.0, {
                                name = 'plant_' .. plantId,
                                debugPoly = Config.Debug,
                            }, {
                                options = options,
                                distance = Config.MaxDistance
                            })
                        end
                        
                        addedTargets[plantId] = true
                    end
                end
            end
        end
    end)
end)

-- Target events
RegisterNetEvent('ez_farming:openFarmingMenu')
AddEventHandler('ez_farming:openFarmingMenu', function(data)
    OpenFarmingMenu(data.zoneIndex)
end)

RegisterNetEvent('ez_farming:openFarmingMenuTarget')
AddEventHandler('ez_farming:openFarmingMenuTarget', function(data)
    OpenFarmingMenu(data.zoneIndex)
end)

RegisterNetEvent('ez_farming:openShopMenuTarget')
AddEventHandler('ez_farming:openShopMenuTarget', function(data)
    OpenShopMenu(data.shopIndex)
end)

-- Enhanced debug system
if Config.Debug then
    CreateThread(function()
        while true do
            Wait(1000)
            
            -- Debug info on screen
            local playerCoords = GetEntityCoords(PlayerPedId())
            local debugText = string.format(
                "Framework: %s\nWeather: %s\nSeason: %s\nPlants Loaded: %d\nCoords: %.2f, %.2f, %.2f",
                Framework or 'Unknown',
                CurrentWeather,
                CurrentSeason,
                GetTableLength(PlantedCrops),
                playerCoords.x, playerCoords.y, playerCoords.z
            )
            
            SetTextFont(0)
            SetTextScale(0.3, 0.3)
            SetTextColour(255, 255, 255, 255)
            SetTextEntry("STRING")
            AddTextComponentSubstringPlayerName(debugText)
            DrawText(0.01, 0.01)
        end
    end)
end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print('^2[EZ Farming]^7 Client utilities loaded successfully!')
