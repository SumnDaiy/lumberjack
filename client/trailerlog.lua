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



AddEventHandler("projectr_lumberjack:AddVehicleLog", function(data)
    local added = lib.callback.await('projectr_lumberjack:AddTrailerLogServer', 200, data.entity, NetworkGetNetworkIdFromEntity(data.entity), GetEntityCoords(data.entity))

    if added then
        local removeLog = lib.callback.await("projectr_lumberjack:removeLog", 200, source)
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


AddEventHandler("projectr_lumberjack:RemoveVehicleLog", function(data)
    local remove = lib.callback.await('projectr_lumberjack:RemoveVehicleLog', 200, NetworkGetNetworkIdFromEntity(data.entity))
    if remove then
        lib.callback.await('projectr_lumberjack:giveReward', 200, source)
    end
end)


function GetLogsOnTrailer(trailer)
    local logs = Entity(trailer).state.logs
    local logsCount = #logs
    return logsCount
end

local optionNames = {}

RegisterNetEvent('projectr_lumberjack:addTarget', function (trailer)
    local options = {
        {
            name = "projectr_lumberjack:AddVehicleLog",
            icon = "fa-solid fa-plus",
            label = "Put log on trailer",
            distance = 2,
            items = 'log',
            canInteract = function (entity)
                if GetLogsOnTrailer(entity) < counter then
                    return true
                end
            end,
            onSelect = function(data)
                TriggerEvent("projectr_lumberjack:AddVehicleLog", data)
            end
        },
        {
            name = "projectr_lumberjack:RemoveVehicleLog",
            icon = "fa-solid fa-minus",
            label = "Rönk leszedése",
            distance = 2,
            canInteract = function(entity)
                local amount = exports.ox_inventory:Search('count', 'log')
                
                if amount == 0 and GetLogsOnTrailer(entity) > 0 then
                    return true
                end
            end,
            onSelect = function(data)
                TriggerEvent("projectr_lumberjack:RemoveVehicleLog", data)
            end
        }
    }
    
    optionNames = {'projectr_lumberjack:AddVehicleLog', 'projectr_lumberjack:RemoveVehicleLog'}
    exports.ox_target:addEntity(trailer, options)
end)

RegisterNetEvent('projectr_lumberjack:removeTarget', function(trailer)
    if trailer then
        exports.ox_target:removeEntity(trailer, optionNames)
        return true
    end
    return false
end)