fx_version 'cerulean'
game 'gta5'

author 'Fang dev'
description 'Événement RP : Vol de camion pétrolier'
version '1.0.0'

shared_scripts {
  'config.lua'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua', -- si tu utilises MySQL
  'server.lua'
}

client_scripts {
  'client.lua'
}
