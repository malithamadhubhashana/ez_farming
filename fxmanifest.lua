fx_version 'cerulean'
game 'gta5'

author 'EZ Farming Script'
description 'Advanced farming script with multi-framework support'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'debug_config.lua', -- Temporary debug script
    'client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- Comment this out if not using mysql-async
    'server/*.lua'
}

lua54 'yes'
