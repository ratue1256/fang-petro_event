local ESX       = exports['es_extended']:getSharedObject()
local lastEvent = 0

-- Commande de test
RegisterCommand('petrotest', function(source)
  local now = os.time()
  if now - lastEvent < Config.Cooldown then
    local left = Config.Cooldown - (now - lastEvent)
    if Config.Notify.type == 'chat' then
      TriggerClientEvent('chat:addMessage', source, {
        args = { Config.Notify.prefix, Config.Notify.msgs.cooldown:gsub('{time}', left) }
      })
    else
      TriggerClientEvent('esx:showNotification', source,
        Config.Notify.msgs.cooldown:gsub('{time}', left)
      )
    end
    return
  end

  lastEvent = now
  TriggerClientEvent('fang_petro_event:start', -1)
end, true)

-- Réception de la livraison
RegisterNetEvent('fang_petro_event:delivered')
AddEventHandler('fang_petro_event:delivered', function()
  local _src    = source
  local xPlayer = ESX.GetPlayerFromId(_src)
  if not xPlayer then return end

  local rewardText = ''

  if Config.Reward.type == 'money' then
    local amount = math.random(
      Config.Reward.money.min,
      Config.Reward.money.max
    )
    xPlayer.addAccountMoney(Config.Reward.money.account, amount)
    rewardText = Config.Reward.money.label .. ' ' .. amount .. '$'
  else
    local itm = Config.Reward.item
    xPlayer.addInventoryItem(itm.name, itm.count)
    rewardText = itm.label .. ' x' .. itm.count
  end

  TriggerClientEvent('fang_petro_event:reward', _src, rewardText)
end)
