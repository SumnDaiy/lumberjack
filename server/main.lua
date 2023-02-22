Trees = {}
Stumps = {}

CreateThread(function ()
    for i = 1, #Config.Locations do
        local tree = Config.Locations[i]
        local treeObject = 
        CreateObjectNoOffset(
            tree.model, 
            tree.location.x, 
            tree.location.y, 
            tree.location.z, 
            true,
            true,
            false
        )
        FreezeEntityPosition(treeObject, true)
        local netId = NetworkGetNetworkIdFromEntity(treeObject)
        Trees[netId] = true
        Entity(treeObject).state.tree = {
            model = tree.model,
            location = tree.location,
            rotation = tree.rotation
        }
    end
end)

lib.callback.register('lumberjack:CheckTree', function(source, netID)
    return source and Trees[netID] and DoesEntityExist(NetworkGetEntityFromNetworkId(netID))
end)

RegisterNetEvent('lumberjack:placeStump', function (data, networkID, entityRotation)
    local entityID = NetworkGetEntityFromNetworkId(networkID)
    local location = data.coords
    local rotation = entityRotation
    --FreezeEntityPosition(entityID, false)
    --ApplyForceToEntity(entityID, 0, math.random(), math.random(), 0, 0, 0, 0, 0, false, true, false, false, true)
    DeleteEntity(entityID)
    Trees[networkID] = nil
    local offset = 0.9
    local stump = CreateObjectNoOffset(Config.stump, location.x, location.y, location.z-offset, true, true, false)
    FreezeEntityPosition(stump, true)
    local netId = NetworkGetNetworkIdFromEntity(stump)
    Stumps[netId] = true
    Entity(stump).state.stump = {
        model = Config.stump,
        location = data.coords,
        rotation = rotation
    }
    TriggerEvent('lumberjack:treeTimer', netId, location, rotation)
    print('start timer')
end)

lib.callback.register("lumberjack:giveReward", function(source)
    if source then
        exports.ox_inventory:AddItem(source, "log", 1)
        return true
    end
end)

lib.callback.register("lumberjack:removeLog", function(source)
    if source then
        exports.ox_inventory:RemoveItem(source, "log", 1)
        return true
    else
        return false
    end
end)

RegisterNetEvent('lumberjack:treeTimer', function (netId, location, rotation)
    SetTimeout(Config.respawnTimer, function ()
        DeleteEntity(NetworkGetEntityFromNetworkId(netId))
        Stumps[netId] = nil
        PlaceTree(location, rotation)
    end)
end)

function PlaceTree(location, rotation)
    local offset = 0.9
    local treeObject = CreateObjectNoOffset(Config.treeModel, location.x, location.y, location.z-offset, true, true, false)
    FreezeEntityPosition(treeObject, true)
    local netId = NetworkGetNetworkIdFromEntity(treeObject)
    Trees[#Trees+1] = netId
    Entity(treeObject).state.tree = {
        model = Config.treeModel,
        location = location,
        rotation = rotation
    }
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    for i = 1, #Trees do
        local entity = NetworkGetEntityFromNetworkId(Trees[i])
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    for i = 1, #Stumps do
        local entity = NetworkGetEntityFromNetworkId(Stumps[i])
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)