Config = {}

-- Point unique de spawn
Config.SpawnPoint = {
  x       = 1220.7264,
  y       = 3537.2769,
  z       = 35.2077,
  heading = 90.0
}

-- Semi-remorque
Config.TruckModel    = `hauler`
Config.TrailerModel  = `tanker`

-- Chauffeur du hauler
Config.TruckDriverModel  = `s_m_y_swat_01`
Config.TruckDriverWeapon = `WEAPON_PISTOL`
Config.TruckDriveSpeed   = 25.0
Config.TruckDriveStyle   = 786603

-- Escortes initiales
Config.EscortVehs           = { `mesa3` }
Config.EscortDriverPed      = `s_m_y_swat_01`
Config.EscortPassengerPed   = `s_m_y_swat_01`
Config.EscortDriveSpeed     = 30.0
Config.EscortDriveStyle     = 786603

-- Point de livraison
Config.Delivery = {
  x      = 396.1501,
  y      = 2987.0513,
  z      = 40.8332,
  radius = 25.0
}

-- Type de récompense
Config.Reward = {
  type = 'money',  -- 'money' ou 'item'
  money = {
    account = 'black_money',
    label   = 'argent sale',
    min     = 15000,
    max     = 30000
  },
  item = {
    name  = 'water',
    label = 'Bouteille d’eau',
    count = 1
  }
}

-- Notifications et messages
Config.Notify = {
  type   = 'esx',     -- 'esx' ou 'chat'
  prefix = '[Petro]',
  msgs = {
    start    = '🚨 Un convoi pétrolier est en route au nord, interceptez-le !',
    delivery = '🚚 Dirigez-vous vers le point de livraison !',
    success  = '🎉 Félicitations ! Vous avez reçu {reward}.',
    cooldown = 'Event en cooldown, patientez {time}s.'
  }
}

-- Cooldown entre chaque event (secondes)
Config.Cooldown = 1800
