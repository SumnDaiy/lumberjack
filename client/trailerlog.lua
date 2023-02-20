local logPositions = {}

--[[ lib.requestModel(`trflat`, 500)
lib.requestModel(`prop_log_01`, 500) ]]
local tminimum, tmaximum = GetModelDimensions(`trflat`)
local trailerSize = tmaximum - tminimum

local lminimum, lmaximum = GetModelDimensions(`prop_log_01`)
local logSize = lmaximum - lminimum

local numberOfLogsInX = math.ceil(trailerSize.x / logSize.x)
local spaceBetweenLogsX = (trailerSize.x - (numberOfLogsInX * logSize.x)) / (numberOfLogsInX)

local numberOfLogsInY = math.ceil(trailerSize.y / logSize.y)
local spaceBetweenLogsY = (trailerSize.y - (numberOfLogsInY * logSize.y)) / (numberOfLogsInY)

local currentOffsetX = tminimum.x + (logSize.x / 2)
local currentOffsetY = tmaximum.y - (logSize.y / 2)

local currentZ = tmaximum.z + (logSize.z / 2.5)

local counter = 0

local amountoflogs = trailerSize / logSize

local perlayer = math.ceil(amountoflogs.x) * math.ceil(amountoflogs.y)
for i = 1, perlayer do
    for i = 1, numberOfLogsInX do

        currentOffsetY = tmaximum.y - (logSize.y / 2)
        
        for j = 1, numberOfLogsInY do
            counter += 1
            logPositions[#logPositions + 1] = vector3(currentOffsetX, currentOffsetY, currentZ)
            currentOffsetY = currentOffsetY - logSize.y - spaceBetweenLogsY
        end

        currentOffsetX = currentOffsetX + logSize.x + spaceBetweenLogsX
    end

    numberOfLogsInX = numberOfLogsInX - 1
    currentOffsetX = tminimum.x + (logSize.x / 2) + (logSize.x / 2) * i
    currentOffsetY = tmaximum.y - (logSize.y / 2)
    currentZ += logSize.z / 1.5
end

--[[ print(json.encode(logPositions, {indent = true})) ]]



AddEventHandler("lumberjack:AddVehicleLog", function(data)
    local added = lib.callback.await('lumberjack:AddTrailerLogServer', 200, data.entity, NetworkGetNetworkIdFromEntity(data.entity), GetEntityCoords(data.entity))

    if added then
        local removeLog = lib.callback.await("lumberjack:removeLog", 200, source)
    end
end)

AddStateBagChangeHandler("logs", nil, function(bagName, key, value) 
    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 then return end

    while not HasCollisionLoadedAroundEntity(entity) do

        if not DoesEntityExist(entity) then return end
        Wait(250)
    end
    for i = 1, #value do
        local logentity = NetworkGetEntityFromNetworkId(value[i])
        
        while not DoesEntityExist(logentity) do
            logentity = NetworkGetEntityFromNetworkId(value[i])
            Wait(0)
        end
        AttachEntityToEntity(logentity, entity, 0, logPositions[i].x, logPositions[i].y, logPositions[i].z, 0, 0, 0, false, false, false, false, 2, true)
    end
end)


AddEventHandler("lumberjack:RemoveVehicleLog", function(data)
    local remove = lib.callback.await('lumberjack:RemoveVehicleLog', 200, NetworkGetNetworkIdFromEntity(data.entity))
    if remove then
        lib.callback.await('lumberjack:giveReward', 200, source)
    end
end)


function GetLogsOnTrailer(netID)
    local netVeh = NetworkGetEntityFromNetworkId(netID)
    local logs = Entity(netVeh).state.logs
    if logs then
        local logsCount = #logs
        return logsCount
    end
end

local optionNames = {}

RegisterNetEvent('lumberjack:addTarget', function (trailer)
    local options = {
        {
            name = "lumberjack:AddVehicleLog",
            icon = "fa-solid fa-plus",
            label = locale('target_add_log'),
            distance = 2,
            items = 'log',
            canInteract = function (entity)
                local netID = NetworkGetNetworkIdFromEntity(entity)
                if GetLogsOnTrailer(netID) < counter then
                    return true
                end
            end,
            onSelect = function(data)
                TriggerEvent("lumberjack:AddVehicleLog", data)
            end
        },
        {
            name = "lumberjack:RemoveVehicleLog",
            icon = "fa-solid fa-minus",
            label = locale('target_remove_log'),
            distance = 2,
            canInteract = function(entity)
                local amount = exports.ox_inventory:Search('count', 'log')
                local netID = NetworkGetNetworkIdFromEntity(entity)
                
                if amount == 0 and GetLogsOnTrailer(netID) > 0 then
                    return true
                end
            end,
            onSelect = function(data)
                TriggerEvent("lumberjack:RemoveVehicleLog", data)
            end
        }
    }
    
    optionNames = {'lumberjack:AddVehicleLog', 'lumberjack:RemoveVehicleLog'}
    exports.ox_target:addEntity(trailer, options)
end)

RegisterNetEvent('lumberjack:removeTarget', function(trailer)
    if trailer then
        exports.ox_target:removeEntity(trailer, optionNames)
        return true
    end
    return false
end)