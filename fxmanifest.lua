--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

name "lumberjack"
description "good"
author "SumnDaiy"
version "1.0"

files {
	'locales/*.json'
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
	'config.lua'
}

client_scripts {
	'@ox_core/imports/client.lua',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    '@ox_core/imports/server.lua',
	'server/*.lua'
}
