local ESX           = exports['es_extended']:getSharedObject()
local active        = false
local truck, trailer, deliveryBlip, driverPed
local escorts       = {}
local escortPeds    = {}

-- Charge un modèle
local function LoadModel(hash)
  RequestModel(hash)
  while not HasModelLoaded(hash) do Wait(10) end
end

-- Fonction de notification centralisée
local function notify(msg)
  if Config.Notify.type == 'chat' then
    TriggerEvent('chat:addMessage', {
      args = { Config.Notify.prefix, msg }
    })
  else
    ESX.ShowNotification(msg)
  end
end

-- Réception de la récompense
RegisterNetEvent('fang_petro_event:reward')
AddEventHandler('fang_petro_event:reward', function(rewardText)
  local msg = Config.Notify.msgs.success:gsub('{reward}', rewardText)
  notify(msg)
end)

-- Démarrage de l’événement
RegisterNetEvent('fang_petro_event:start')
AddEventHandler('fang_petro_event:start', function()
  if active then return end
  active = true

  local pt = Config.SpawnPoint
  notify(Config.Notify.msgs.start)

  -- 1) spawn semi-remorque
  LoadModel(Config.TruckModel)
  LoadModel(Config.TrailerModel)
  truck   = CreateVehicle(
    Config.TruckModel, pt.x, pt.y, pt.z, pt.heading, true, false
  )
  trailer = CreateVehicle(
    Config.TrailerModel, pt.x - 5.0, pt.y, pt.z, pt.heading, true, false
  )

  SetVehicleOnGroundProperly(truck)
  SetVehicleOnGroundProperly(trailer)
  AttachVehicleToTrailer(truck, trailer, 1.0)
  SetEntityInvincible(trailer, true)
  SetEntityAsMissionEntity(truck,   true, true)
  SetEntityAsMissionEntity(trailer, true, true)

  -- 2) chauffeur du hauler
  LoadModel(Config.TruckDriverModel)
  driverPed = CreatePedInsideVehicle(
    truck, 4, Config.TruckDriverModel, -1, true, false
  )
  GiveWeaponToPed(driverPed, `WEAPON_PISTOL`, 250, true, true)
  SetPedKeepTask(driverPed, true)
  SetPedCanBeDraggedOut(driverPed, false)
  SetPedConfigFlag(driverPed, 184, true)
  SetBlockingOfNonTemporaryEvents(driverPed, true)
  SetVehicleEngineOn(truck, true, true, false)
  TaskVehicleDriveToCoord(driverPed, truck,
    Config.Delivery.x, Config.Delivery.y, Config.Delivery.z,
    Config.TruckDriveSpeed, 0,
    Config.TruckModel, Config.TruckDriveStyle, 1.0
  )

  -- boucle pour garder le chauffeur à bord
  Citizen.CreateThread(function()
    while active do
      Wait(1000)
      if GetPedInVehicleSeat(truck, -1) ~= driverPed then
        TaskWarpPedIntoVehicle(driverPed, truck, -1)
      end
    end
  end)

  -- 3) Mesa verrouillées + PNJ escortes
  local offsets = {
    vector3(pt.x + 15.0, pt.y,      pt.z),
    vector3(pt.x - 15.0, pt.y,      pt.z)
  }

  for _, pos in ipairs(offsets) do
    LoadModel(`mesa3`)
    local evVeh = CreateVehicle(`mesa3`, pos.x, pos.y, pos.z, pt.heading, true, false)
    SetVehicleOnGroundProperly(evVeh)
    SetVehicleEngineOn(evVeh, true, true, false)
    SetEntityAsMissionEntity(evVeh, true, true)
    SetVehicleDoorsLocked(evVeh, 4)

    -- conducteur
    LoadModel(Config.EscortDriverPed)
    local dPed = CreatePedInsideVehicle(
      evVeh, 4, Config.EscortDriverPed, -1, true, false
    )
    GiveWeaponToPed(dPed, `WEAPON_PISTOL`, 250, true, true)
    SetPedKeepTask(dPed, true)
    SetPedCombatAttributes(dPed, 46, true)
    SetPedAsEnemy(dPed, true)

    -- passager
    LoadModel(Config.EscortPassengerPed)
    local pPed = CreatePedInsideVehicle(
      evVeh, 4, Config.EscortPassengerPed, 0, true, false
    )
    GiveWeaponToPed(pPed, `WEAPON_PISTOL`, 250, true, true)
    SetPedCombatAttributes(pPed, 46, true)
    SetPedAsEnemy(pPed, true)

    table.insert(escorts,   { vehicle = evVeh, driver = dPed })
    table.insert(escortPeds, dPed)
    table.insert(escortPeds, pPed)
  end

  -- 4) blip semi-remorque
  local truckBlip = AddBlipForEntity(truck)
  SetBlipSprite(truckBlip, 477)
  SetBlipColour(truckBlip, 5)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString('Camion pétrolier')
  EndTextCommandSetBlipName(truckBlip)
  SetBlipRoute(truckBlip, true)

  -- 5) Mesa suivent en boucle
  Citizen.CreateThread(function()
    while active do
      Wait(1000)
      if not DoesEntityExist(truck) then break end
      local tcoords = GetEntityCoords(truck)
      for _, esc in ipairs(escorts) do
        if DoesEntityExist(esc.driver) and DoesEntityExist(esc.vehicle) then
          ClearPedTasks(esc.driver)
          TaskVehicleDriveToCoord(esc.driver, esc.vehicle,
            tcoords.x, tcoords.y, tcoords.z,
            Config.EscortDriveSpeed, 0,
            `mesa3`, Config.EscortDriveStyle, 1.0, 10.0
          )
        end
      end
    end
  end)

  -- 6) point de livraison + nettoyage
  Citizen.CreateThread(function()
    local blipCreated = false

    while active do
      Wait(500)
      if not DoesEntityExist(truck) then break end

      local ped        = PlayerPedId()
      local inTruck    = IsPedInVehicle(ped, truck, false)
      local tcoords    = GetEntityCoords(truck)
      local dist       = #(tcoords - vector3(
                          Config.Delivery.x,
                          Config.Delivery.y,
                          Config.Delivery.z
                        ))
      local driverNow  = GetPedInVehicleSeat(truck, -1)
      local playerDrive= (driverNow == ped)

      if inTruck and not blipCreated then
        deliveryBlip = AddBlipForCoord(
          Config.Delivery.x, Config.Delivery.y, Config.Delivery.z
        )
        SetBlipSprite(deliveryBlip, 1)
        SetBlipColour(deliveryBlip, 5)
        SetBlipRoute(deliveryBlip, true)
        notify(Config.Notify.msgs.delivery)
        blipCreated = true
      end

      if dist < Config.Delivery.radius then
        if playerDrive then
          TriggerServerEvent('fang_petro_event:delivered')
        end

        if deliveryBlip then RemoveBlip(deliveryBlip) end
        DeleteEntity(truck)
        DeleteEntity(trailer)
        for _, esc in ipairs(escorts) do
          if DoesEntityExist(esc.vehicle) then DeleteEntity(esc.vehicle) end
        end
        for _, p in ipairs(escortPeds) do
          if DoesEntityExist(p) then DeleteEntity(p) end
        end

        active = false
      end
    end
  end)
end)
