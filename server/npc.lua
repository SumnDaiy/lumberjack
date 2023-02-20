local bossModel = `s_m_m_dockwork_01`

local coords = Config.bossLocation
Ped = CreatePed(0, bossModel, coords.x, coords.y, coords.z, coords.w, true, true)
Entity(Ped).state.ped = {}

AddEventHandler('onResourceStop', function(resourceName)
    if (resourceName ~= cache.resource) then
      return
    end
    DeleteEntity(Ped)
end)

lib.callback.register('lumberjack:createTrailer', function (source)
  local vehicle = Ox.CreateVehicle({
    model = 'trflat',
    owner = false,
  }, Config.trailerSpawnCoords.xyz, Config.trailerSpawnCoords.w)

  if vehicle then
    local player = Ox.GetPlayer(source)

    if player then
      Entity(vehicle.entity).state.trailerHandler = {
        [player.charid] = true
      }
      Entity(vehicle.entity).state.logs = {}
      return vehicle
    end
  end
end)

lib.callback.register('lumberjack:returnPlayer', function (_, target)
  local target = Ox.GetPlayer(target)

  if target then return target end

  return false
end)

lib.callback.register('lumberjack:GetPayment', function(source, amount)
  if source then
    local success, response = exports.ox_inventory:AddItem(source, 'money', amount)
    if not success then
      print(response)
    end
--[[     lib.notify(source{
      title = locale('notify_title'),
      description = locale('paid', amount),
      type = 'success'
  }) ]]
  end
end)

lib.callback.register('lumberjack:DeleteTrailer', function (_, trailer)
  if trailer then
    local vehicle = Ox.GetVehicle(trailer)
    if vehicle then
      vehicle:despawn()
      return true
    end
    return false
  end
end)