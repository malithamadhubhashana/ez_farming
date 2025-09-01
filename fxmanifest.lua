fx_version 'cerulean'
game 'gta5'

author 'EZ Farming Script'
description 'Advanced farming script with multi-framework support'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- Comment this out if not using mysql-async
    'server/*.lua'
}

dependencies {
    'es_extended', -- Optional
    'qb-core',     -- Optional
    'qbx_core',    -- Optional
    'ox_target',   -- Optional
    'ox_inventory' -- Optional
}

lua54 'yes'
