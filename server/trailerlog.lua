alllogs = {}

lib.callback.register('projectr_lumberjack:AddTrailerLogServer', function(_, trailer, netId, coords)
     local netVeh = NetworkGetEntityFromNetworkId(netId)
     local log = CreateObjectNoOffset(Config.log, coords.x, coords.y, coords.z, true, true, false)
     while not DoesEntityExist(log) do
          Wait(250)
     end
     local logs = Entity(netVeh).state.logs
     logs[#logs+1] = NetworkGetNetworkIdFromEntity(log)
     Entity(netVeh).state.logs = logs
     table.insert(alllogs, log)
     return true
end)

lib.callback.register('projectr_lumberjack:RemoveVehicleLog', function(_, netId)
     local netVeh = NetworkGetEntityFromNetworkId(netId)
     if netVeh then
          local logs = Entity(netVeh).state.logs
          local last = #logs
          local logEntity = NetworkGetEntityFromNetworkId(logs[last])
          DeleteEntity(logEntity)
          logs[last] = nil
          Entity(netVeh).state.logs = logs
          table.insert(alllogs, logEntity)
          return true
     end
end)

AddEventHandler('onResourceStop', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
       return
     end
     for i = 1, #alllogs, 1 do
          DeleteEntity(alllogs[i])
     end
end)