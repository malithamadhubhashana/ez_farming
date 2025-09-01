-- Drawtext System Management
local DrawTextSystem = nil
local ActiveDrawTexts = {}
local DrawTextThread = nil
local isDrawTextActive = false

-- Initialize drawtext system
CreateThread(function()
    Wait(1000) -- Wait for resources to load
    
    -- Auto-detect available drawtext system
    if Config.DrawTextSystem == 'auto' then
        if GetResourceState('ox_lib') == 'started' then
            DrawTextSystem = 'ox_lib'
        elseif GetResourceState('qb-drawtext') == 'started' then
            DrawTextSystem = 'qb-drawtext'
        else
            DrawTextSystem = 'native'
        end
    else
        DrawTextSystem = Config.DrawTextSystem
    end
    
    print('^2[EZ Farming]^7 Using drawtext system: ' .. DrawTextSystem)
    
    -- Start drawtext monitoring thread
    if DrawTextSystem and Config.DrawText.enabled then
        StartDrawTextThread()
    end
end)

-- Start the drawtext monitoring thread
function StartDrawTextThread()
    if DrawTextThread then return end
    
    DrawTextThread = CreateThread(function()
        while true do
            local sleep = 1000
            
            if not Config.UseTarget and next(ActiveDrawTexts) then
                sleep = 0
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                
                -- Check all active drawtexts
                for id, drawData in pairs(ActiveDrawTexts) do
                    local distance = #(playerCoords - drawData.coords)
                    
                    if distance <= drawData.maxDistance then
                        -- Show drawtext
                        ShowDrawText(drawData.text, drawData.coords, drawData.options or {})
                        
                        -- Handle interaction
                        if drawData.showControls and IsControlJustReleased(0, 38) then -- E key
                            if drawData.onInteract then
                                drawData.onInteract()
                            end
                        end
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

-- Show drawtext based on system
function ShowDrawText(text, coords, options)
    options = options or {}
    
    if DrawTextSystem == 'ox_lib' then
        -- ox_lib drawtext
        local position = options.position or Config.DrawText.position
        exports.ox_lib:showTextUI(text, {
            position = position,
            icon = options.icon,
            iconColor = options.iconColor
        })
    elseif DrawTextSystem == 'qb-drawtext' then
        -- qb-drawtext
        exports['qb-drawtext']:DrawText(text, options.position or 'left')
    else
        -- Native GTA drawtext
        local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
        if onScreen then
            SetTextScale(Config.DrawText.scale, Config.DrawText.scale)
            SetTextFont(Config.DrawText.font)
            SetTextProportional(1)
            SetTextColour(Config.DrawText.color[1], Config.DrawText.color[2], Config.DrawText.color[3], Config.DrawText.color[4])
            SetTextEntry("STRING")
            AddTextComponentString(text)
            DrawText(screenX, screenY)
        end
    end
end

-- Hide drawtext
function HideDrawText()
    if DrawTextSystem == 'ox_lib' then
        exports.ox_lib:hideTextUI()
    elseif DrawTextSystem == 'qb-drawtext' then
        exports['qb-drawtext']:HideText()
    end
    -- Native drawtext doesn't need hiding as it's drawn per frame
end

-- Add a drawtext area
function AddDrawText(id, coords, text, maxDistance, onInteract, options)
    options = options or {}
    
    ActiveDrawTexts[id] = {
        coords = coords,
        text = text,
        maxDistance = maxDistance or Config.MaxDistance,
        onInteract = onInteract,
        options = options,
        showControls = options.showControls ~= false
    }
    
    if Config.Debug then
        print('^2[EZ Farming]^7 Added drawtext: ' .. id)
    end
end

-- Remove a drawtext area
function RemoveDrawText(id)
    if ActiveDrawTexts[id] then
        ActiveDrawTexts[id] = nil
        HideDrawText()
        
        if Config.Debug then
            print('^2[EZ Farming]^7 Removed drawtext: ' .. id)
        end
    end
end

-- Update drawtext
function UpdateDrawText(id, newText, newOptions)
    if ActiveDrawTexts[id] then
        ActiveDrawTexts[id].text = newText
        if newOptions then
            for k, v in pairs(newOptions) do
                ActiveDrawTexts[id].options[k] = v
            end
        end
    end
end

-- Setup farming zone drawtexts
function SetupFarmingZoneDrawTexts()
    if Config.UseTarget then return end -- Only use if target system is disabled
    
    for i, zone in ipairs(Config.FarmingZones) do
        local text = "Press [E] to open farming menu"
        if Config.DrawText.showControls then
            text = "~INPUT_CONTEXT~ " .. zone.name or "Farming Zone"
        end
        
        AddDrawText('farming_zone_' .. i, zone.coords, text, zone.maxDistance or Config.MaxDistance, function()
            OpenFarmingMenu(i)
        end, {
            icon = 'fa-seedling',
            position = 'top-center'
        })
    end
end

-- Setup shop ped drawtexts
function SetupShopDrawTexts()
    if Config.UseTarget then return end
    
    for i, shop in ipairs(Config.Shops) do
        if shop.ped then
            local text = "Press [E] to open " .. shop.name
            if Config.DrawText.showControls then
                text = "~INPUT_CONTEXT~ " .. shop.name
            end
            
            AddDrawText('shop_' .. i, shop.coords, text, Config.MaxDistance, function()
                OpenShopMenu(i)
            end, {
                icon = 'fa-shopping-cart',
                position = 'top-center'
            })
        end
    end
end

-- Setup plant drawtexts
function SetupPlantDrawTexts()
    if Config.UseTarget then return end
    
    CreateThread(function()
        local addedDrawTexts = {}
        
        while true do
            Wait(5000)
            
            if not Config.UseTarget then
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                -- Remove drawtexts for harvested plants
                for plantId, _ in pairs(addedDrawTexts) do
                    if not PlantedCrops[plantId] then
                        RemoveDrawText('plant_' .. plantId)
                        addedDrawTexts[plantId] = nil
                    end
                end
                
                -- Add drawtexts for new plants
                for plantId, plant in pairs(PlantedCrops) do
                    if not addedDrawTexts[plantId] and #(playerCoords - plant.coords) < 50.0 then
                        local cropConfig = Config.Crops[plant.type]
                        if not cropConfig then goto continue end
                        
                        local actions = {}
                        local text = ""
                        
                        if plant.stage >= cropConfig.stages then
                            text = "Press [E] to harvest " .. cropConfig.label
                            table.insert(actions, function() HarvestPlant(plantId) end)
                        else
                            if plant.needsWater then
                                text = "Press [E] to water plant"
                                table.insert(actions, function() 
                                    if HasItem(Config.Tools.watering_can.item) then
                                        WaterPlant(plantId) 
                                    else
                                        ShowNotification('no_tool', Config.Tools.watering_can.label)
                                    end
                                end)
                            elseif cropConfig.fertilizerCompatible and not plant.fertilized then
                                text = "Press [E] for plant options"
                                table.insert(actions, function() InteractWithPlant(plantId) end)
                            else
                                text = "Plant is growing... (" .. plant.stage .. "/" .. cropConfig.stages .. ")"
                            end
                        end
                        
                        if Config.DrawText.showControls then
                            text = "~INPUT_CONTEXT~ " .. text:gsub("Press %[E%] ", "")
                        end
                        
                        AddDrawText('plant_' .. plantId, plant.coords, text, Config.MaxDistance, 
                            actions[1], {
                                icon = 'fa-leaf',
                                position = 'center'
                            })
                        
                        addedDrawTexts[plantId] = true
                        
                        ::continue::
                    end
                end
            end
        end
    end)
end

-- Initialize drawtext systems when resource starts
RegisterNetEvent('ez_farming:clientReady')
AddEventHandler('ez_farming:clientReady', function()
    Wait(2000) -- Wait for everything to initialize
    
    if not Config.UseTarget then
        SetupFarmingZoneDrawTexts()
        SetupShopDrawTexts()
        SetupPlantDrawTexts()
        print('^2[EZ Farming]^7 Drawtext system initialized')
    end
end)

-- Add missing function references
function WaterPlant(plantId)
    if HasItem(Config.Tools.watering_can.item) then
        TriggerServerEvent('ez_farming:waterPlant', plantId)
        PlayWateringAnimation()
    else
        ShowNotification('no_tool', Config.Tools.watering_can.label)
    end
end

function FertilizePlant(plantId)
    if HasItem(Config.Tools.fertilizer.item) then
        TriggerServerEvent('ez_farming:fertilizePlant', plantId)
        PlayFertilizingAnimation()
    else
        ShowNotification('no_tool', Config.Tools.fertilizer.label)
    end
end

function HarvestPlant(plantId)
    if HasItem(Config.Tools.hoe.item) then
        TriggerServerEvent('ez_farming:harvestCrop', plantId)
        PlayHarvestingAnimation()
    else
        ShowNotification('no_tool', Config.Tools.hoe.label)
    end
end

function InteractWithPlant(plantId)
    local plant = PlantedCrops[plantId]
    if not plant then return end
    
    local cropConfig = Config.Crops[plant.type]
    
    if plant.stage >= cropConfig.stages then
        HarvestPlant(plantId)
    elseif plant.needsWater then
        WaterPlant(plantId)
    elseif cropConfig.fertilizerCompatible and not plant.fertilized then
        FertilizePlant(plantId)
    else
        ShowNotification('not_ready')
    end
end

-- Export functions for use in other files
exports('AddDrawText', AddDrawText)
exports('RemoveDrawText', RemoveDrawText)
exports('UpdateDrawText', UpdateDrawText)
exports('HideDrawText', HideDrawText)
