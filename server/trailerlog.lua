alllogs = {}

lib.callback.register('lumberjack:AddTrailerLogServer', function(_, trailer, netId, coords)
     local netVeh = NetworkGetEntityFromNetworkId(netId)
     local log = CreateObjectNoOffset(Config.log, coords.x, coords.y, coords.z, true, true, false)
     while not DoesEntityExist(log) do
          Wait(250)
     end
     local logs = Entity(netVeh).state.logs
     logs[#logs+1] = NetworkGetNetworkIdFromEntity(log)
     Entity(netVeh).state.logs = logs
     alllogs[#alllogs+1] = log
     return true
end)

lib.callback.register('lumberjack:RemoveVehicleLog', function(_, netId)
     local netVeh = NetworkGetEntityFromNetworkId(netId)
     if netVeh then
          local logs = Entity(netVeh).state.logs
          local last = #logs
          local logEntity = NetworkGetEntityFromNetworkId(logs[last])
          DeleteEntity(logEntity)
          logs[last] = nil
          Entity(netVeh).state.logs = logs
          return true
     end
end)

lib.callback.register('lumberjack:RemoveAllVehicleLog', function(_, netId)
     local netVeh = NetworkGetEntityFromNetworkId(netId)
     if netVeh then
          local logs = Entity(netVeh).state.logs
          for i = #logs, 1, -1 do
               local logEntity = NetworkGetEntityFromNetworkId(logs[i])
               DeleteEntity(logEntity)
          end
          Entity(netVeh).state.logs = {}
          
          return #logs
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