-- QB-Inventory Items Configuration
-- Add these items to your qb-core/shared/items.lua file

QBShared = QBShared or {}
QBShared.Items = QBShared.Items or {}

-- Farming Tools
QBShared.Items['farming_hoe'] = {
    name = 'farming_hoe',
    label = 'Farming Hoe',
    weight = 1000,
    type = 'item',
    image = 'farming_hoe.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A sturdy hoe for tilling soil and preparing farmland'
}

QBShared.Items['watering_can'] = {
    name = 'watering_can',
    label = 'Watering Can',
    weight = 800,
    type = 'item',
    image = 'watering_can.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Essential tool for keeping your crops hydrated'
}

QBShared.Items['fertilizer'] = {
    name = 'fertilizer',
    label = 'Plant Fertilizer',
    weight = 200,
    type = 'item',
    image = 'fertilizer.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Nutrient-rich fertilizer to accelerate plant growth'
}

-- Seeds
QBShared.Items['potato_seed'] = {
    name = 'potato_seed',
    label = 'Potato Seeds',
    weight = 10,
    type = 'item',
    image = 'potato_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'High-quality potato seeds for planting'
}

QBShared.Items['tomato_seed'] = {
    name = 'tomato_seed',
    label = 'Tomato Seeds',
    weight = 10,
    type = 'item',
    image = 'tomato_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Premium tomato seeds that grow into juicy tomatoes'
}

QBShared.Items['corn_seed'] = {
    name = 'corn_seed',
    label = 'Corn Seeds',
    weight = 15,
    type = 'item',
    image = 'corn_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Sweet corn seeds perfect for farming'
}

QBShared.Items['carrot_seed'] = {
    name = 'carrot_seed',
    label = 'Carrot Seeds',
    weight = 8,
    type = 'item',
    image = 'carrot_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Orange carrot seeds packed with nutrients'
}

QBShared.Items['lettuce_seed'] = {
    name = 'lettuce_seed',
    label = 'Lettuce Seeds',
    weight = 5,
    type = 'item',
    image = 'lettuce_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Fresh lettuce seeds for crispy greens'
}

QBShared.Items['wheat_seed'] = {
    name = 'wheat_seed',
    label = 'Wheat Seeds',
    weight = 12,
    type = 'item',
    image = 'wheat_seed.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Golden wheat seeds for bread making'
}

-- Fresh Crops (Low Quality)
QBShared.Items['potato'] = {
    name = 'potato',
    label = 'Fresh Potato',
    weight = 150,
    type = 'item',
    image = 'potato.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A freshly harvested potato, basic quality'
}

QBShared.Items['tomato'] = {
    name = 'tomato',
    label = 'Fresh Tomato',
    weight = 100,
    type = 'item',
    image = 'tomato.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A ripe tomato, perfect for cooking'
}

QBShared.Items['corn'] = {
    name = 'corn',
    label = 'Fresh Corn',
    weight = 120,
    type = 'item',
    image = 'corn.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Sweet corn kernels, fresh from the farm'
}

QBShared.Items['carrot'] = {
    name = 'carrot',
    label = 'Fresh Carrot',
    weight = 80,
    type = 'item',
    image = 'carrot.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A crunchy orange carrot'
}

QBShared.Items['lettuce'] = {
    name = 'lettuce',
    label = 'Fresh Lettuce',
    weight = 60,
    type = 'item',
    image = 'lettuce.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Crisp lettuce leaves for salads'
}

QBShared.Items['wheat'] = {
    name = 'wheat',
    label = 'Fresh Wheat',
    weight = 100,
    type = 'item',
    image = 'wheat.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Golden wheat ready for processing'
}

-- High Quality Crops
QBShared.Items['potato_hq'] = {
    name = 'potato_hq',
    label = 'Premium Potato',
    weight = 150,
    type = 'item',
    image = 'potato_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A perfectly grown potato of exceptional quality'
}

QBShared.Items['tomato_hq'] = {
    name = 'tomato_hq',
    label = 'Premium Tomato',
    weight = 100,
    type = 'item',
    image = 'tomato_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A flawless tomato with rich flavor'
}

QBShared.Items['corn_hq'] = {
    name = 'corn_hq',
    label = 'Premium Corn',
    weight = 120,
    type = 'item',
    image = 'corn_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Extra sweet corn of premium quality'
}

QBShared.Items['carrot_hq'] = {
    name = 'carrot_hq',
    label = 'Premium Carrot',
    weight = 80,
    type = 'item',
    image = 'carrot_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A perfectly shaped carrot with vibrant color'
}

QBShared.Items['lettuce_hq'] = {
    name = 'lettuce_hq',
    label = 'Premium Lettuce',
    weight = 60,
    type = 'item',
    image = 'lettuce_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Pristine lettuce leaves, perfectly crisp'
}

QBShared.Items['wheat_hq'] = {
    name = 'wheat_hq',
    label = 'Premium Wheat',
    weight = 100,
    type = 'item',
    image = 'wheat_hq.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Golden wheat of exceptional quality'
}

-- Special Items
QBShared.Items['plant_nutrients'] = {
    name = 'plant_nutrients',
    label = 'Plant Nutrients',
    weight = 50,
    type = 'item',
    image = 'plant_nutrients.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Special nutrients to boost plant health and yield'
}

QBShared.Items['soil_ph_kit'] = {
    name = 'soil_ph_kit',
    label = 'Soil pH Testing Kit',
    weight = 300,
    type = 'item',
    image = 'soil_ph_kit.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Professional kit for testing soil acidity levels'
}

QBShared.Items['greenhouse_permit'] = {
    name = 'greenhouse_permit',
    label = 'Greenhouse Permit',
    weight = 0,
    type = 'item',
    image = 'greenhouse_permit.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Official permit allowing greenhouse farming operations'
}
