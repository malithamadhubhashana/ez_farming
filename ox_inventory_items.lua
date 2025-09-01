-- ox_inventory items configuration
-- Add these items to your ox_inventory/data/items.lua file

-- Farming Seeds
['wheat_seed'] = {
    label = 'Wheat Seeds',
    weight = 10,
    stack = true,
    close = true,
    description = 'Seeds for growing wheat crops'
},

['corn_seed'] = {
    label = 'Corn Seeds',
    weight = 12,
    stack = true,
    close = true,
    description = 'Seeds for growing corn crops'
},

['tomato_seed'] = {
    label = 'Tomato Seeds',
    weight = 8,
    stack = true,
    close = true,
    description = 'Seeds for growing tomato crops'
},

['potato_seed'] = {
    label = 'Potato Seeds',
    weight = 15,
    stack = true,
    close = true,
    description = 'Seeds for growing potato crops'
},

['carrot_seed'] = {
    label = 'Carrot Seeds',
    weight = 9,
    stack = true,
    close = true,
    description = 'Seeds for growing carrot crops'
},

['lettuce_seed'] = {
    label = 'Lettuce Seeds',
    weight = 6,
    stack = true,
    close = true,
    description = 'Seeds for growing lettuce crops'
},

['strawberry_seed'] = {
    label = 'Strawberry Seeds',
    weight = 7,
    stack = true,
    close = true,
    description = 'Seeds for growing strawberry crops'
},

-- Farming Tools
['farming_hoe'] = {
    label = 'Farming Hoe',
    weight = 2000,
    stack = false,
    close = true,
    description = 'Essential tool for planting and harvesting crops',
    durability = 100
},

['watering_can'] = {
    label = 'Watering Can',
    weight = 1500,
    stack = false,
    close = true,
    description = 'Used to water plants and keep them healthy',
    durability = 100
},

['fertilizer'] = {
    label = 'Fertilizer',
    weight = 200,
    stack = true,
    close = true,
    description = 'Speeds up plant growth and improves crop quality'
},

['pesticide'] = {
    label = 'Pesticide',
    weight = 150,
    stack = true,
    close = true,
    description = 'Used to treat pest infestations on crops'
},

['fungicide'] = {
    label = 'Fungicide',
    weight = 150,
    stack = true,
    close = true,
    description = 'Used to treat plant diseases'
},

-- Harvested Crops (Regular Quality)
['wheat'] = {
    label = 'Wheat',
    weight = 25,
    stack = true,
    close = true,
    description = 'Freshly harvested wheat, good for making bread'
},

['corn'] = {
    label = 'Corn',
    weight = 30,
    stack = true,
    close = true,
    description = 'Fresh corn on the cob, sweet and nutritious'
},

['tomato'] = {
    label = 'Tomato',
    weight = 20,
    stack = true,
    close = true,
    description = 'Ripe red tomatoes, perfect for cooking'
},

['potato'] = {
    label = 'Potato',
    weight = 40,
    stack = true,
    close = true,
    description = 'Fresh potatoes, versatile vegetable for many dishes'
},

['carrot'] = {
    label = 'Carrot',
    weight = 18,
    stack = true,
    close = true,
    description = 'Orange carrots, crunchy and healthy'
},

['lettuce'] = {
    label = 'Lettuce',
    weight = 15,
    stack = true,
    close = true,
    description = 'Fresh green lettuce, perfect for salads'
},

['strawberry'] = {
    label = 'Strawberry',
    weight = 10,
    stack = true,
    close = true,
    description = 'Sweet red strawberries, delicious and healthy'
},

-- Quality Variants (Poor Quality)
['wheat_poor'] = {
    label = 'Poor Quality Wheat',
    weight = 25,
    stack = true,
    close = true,
    description = 'Low quality wheat, sells for less money'
},

['corn_poor'] = {
    label = 'Poor Quality Corn',
    weight = 30,
    stack = true,
    close = true,
    description = 'Low quality corn, not the best harvest'
},

['tomato_poor'] = {
    label = 'Poor Quality Tomato',
    weight = 20,
    stack = true,
    close = true,
    description = 'Poor quality tomatoes, damaged or underripe'
},

['potato_poor'] = {
    label = 'Poor Quality Potato',
    weight = 40,
    stack = true,
    close = true,
    description = 'Poor quality potatoes, small and damaged'
},

['carrot_poor'] = {
    label = 'Poor Quality Carrot',
    weight = 18,
    stack = true,
    close = true,
    description = 'Poor quality carrots, small and bitter'
},

['lettuce_poor'] = {
    label = 'Poor Quality Lettuce',
    weight = 15,
    stack = true,
    close = true,
    description = 'Poor quality lettuce, wilted and damaged'
},

['strawberry_poor'] = {
    label = 'Poor Quality Strawberry',
    weight = 10,
    stack = true,
    close = true,
    description = 'Poor quality strawberries, small and sour'
},

-- Quality Variants (Good Quality)
['wheat_good'] = {
    label = 'Good Quality Wheat',
    weight = 25,
    stack = true,
    close = true,
    description = 'Good quality wheat, well-grown and healthy'
},

['corn_good'] = {
    label = 'Good Quality Corn',
    weight = 30,
    stack = true,
    close = true,
    description = 'Good quality corn, large and sweet'
},

['tomato_good'] = {
    label = 'Good Quality Tomato',
    weight = 20,
    stack = true,
    close = true,
    description = 'Good quality tomatoes, ripe and juicy'
},

['potato_good'] = {
    label = 'Good Quality Potato',
    weight = 40,
    stack = true,
    close = true,
    description = 'Good quality potatoes, large and healthy'
},

['carrot_good'] = {
    label = 'Good Quality Carrot',
    weight = 18,
    stack = true,
    close = true,
    description = 'Good quality carrots, crisp and sweet'
},

['lettuce_good'] = {
    label = 'Good Quality Lettuce',
    weight = 15,
    stack = true,
    close = true,
    description = 'Good quality lettuce, fresh and crispy'
},

['strawberry_good'] = {
    label = 'Good Quality Strawberry',
    weight = 10,
    stack = true,
    close = true,
    description = 'Good quality strawberries, sweet and juicy'
},

-- Quality Variants (Premium Quality)
['wheat_premium'] = {
    label = 'Premium Wheat',
    weight = 25,
    stack = true,
    close = true,
    description = 'Premium quality wheat, perfectly grown and organic'
},

['corn_premium'] = {
    label = 'Premium Corn',
    weight = 30,
    stack = true,
    close = true,
    description = 'Premium quality corn, exceptionally sweet and large'
},

['tomato_premium'] = {
    label = 'Premium Tomato',
    weight = 20,
    stack = true,
    close = true,
    description = 'Premium quality tomatoes, perfectly ripe and flavorful'
},

['potato_premium'] = {
    label = 'Premium Potato',
    weight = 40,
    stack = true,
    close = true,
    description = 'Premium quality potatoes, large and perfectly formed'
},

['carrot_premium'] = {
    label = 'Premium Carrot',
    weight = 18,
    stack = true,
    close = true,
    description = 'Premium quality carrots, exceptionally sweet and crunchy'
},

['lettuce_premium'] = {
    label = 'Premium Lettuce',
    weight = 15,
    stack = true,
    close = true,
    description = 'Premium quality lettuce, perfectly fresh and organic'
},

['strawberry_premium'] = {
    label = 'Premium Strawberry',
    weight = 10,
    stack = true,
    close = true,
    description = 'Premium quality strawberries, exceptionally sweet and large'
},

-- Other Farming Items
['water'] = {
    label = 'Water',
    weight = 100,
    stack = true,
    close = true,
    description = 'Clean water for refilling watering cans'
},

['steel'] = {
    label = 'Steel',
    weight = 500,
    stack = true,
    close = true,
    description = 'Steel material for repairing farming tools'
}
