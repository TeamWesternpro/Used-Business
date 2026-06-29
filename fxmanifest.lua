fx_version 'cerulean'
game 'gta5'

name 'tw-useddealership'
description 'Used Business Dealership - Sell & Buy Businesses In-Game'
author 'TW Scripts'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'html/tablet.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/js/admin.js',
    'html/js/tablet.js'
}

ui_page 'html/tablet.html'
