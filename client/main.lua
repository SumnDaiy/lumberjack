lib.locale()
local carryLog = 0
playerState = LocalPlayer.state

local options = {
    {
        name = "lumberjack:cutTree",
        icon = "fa-solid fa-axe",
        label = locale('cut_tree'),
        items = "WEAPON_HATCHET",
        canInteract = function()
            if cache.weapon == `WEAPON_HATCHET` then
                return true
            end
        end,
        onSelect = function (entity)
            TriggerEvent("lumberjack:cutTree", entity)
        end
    }
}

AddStateBagChangeHandler('tree', nil, function(bagName, key, value)
    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 or not value then return end

    exports.ox_target:removeEntity(NetworkGetNetworkIdFromEntity(entity), "lumberjack:cutTree")
    exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(entity), options)

    if NetworkGetEntityOwner(entity) == cache.playerId then
        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(100)
        end

        local offset = 0.9
        FreezeEntityPosition(entity, true)
        SetEntityRotation(entity, value.rotation.x, value.rotation.y, value.rotation.z, 0, false)
        PlaceObjectOnGroundProperly(entity)

        local coords = GetEntityCoords(entity)
        SetEntityCoords(entity, coords.x, coords.y, coords.z-offset, false, false, false, false)
    end
end)

AddStateBagChangeHandler('stump', nil, function(bagName, key, value)
    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 or not value then return end

    if NetworkGetEntityOwner(entity) == cache.playerId then
        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(100)
        end

        FreezeEntityPosition(entity, true)
        local offset = 0.9
        SetEntityRotation(entity, value.rotation.x, value.rotation.y, value.rotation.z, 0, false)
        PlaceObjectOnGroundProperly(entity)

        local coords = GetEntityCoords(entity)
        SetEntityCoords(entity, coords.x, coords.y, coords.z-offset, false, false, false, false)
    end
end)

function CutTree(data)
    local anim = {
        dict = 'melee@hatchet@streamed_core',
        clip = 'plyr_rear_takedown_b',
        lockX = true,
        lockY = true,
        lockZ = false,
    }

    lib.requestAnimDict(anim.dict)

    TaskPlayAnim(cache.ped, anim.dict, anim.clip, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1, anim.flag or 49, anim.playbackRate or 0, anim.lockX, anim.lockY, anim.lockZ)
    RemoveAnimDict(anim.dict)

    local successful = lib.skillCheck({'easy','easy','easy','easy', 'easy','easy','easy','easy'}, {'a', 'd'})

    if successful then
        TriggerServerEvent('lumberjack:placeStump', data, NetworkGetNetworkIdFromEntity(data.entity), GetEntityRotation(data.entity))

        lib.callback.await("lumberjack:giveReward", 200)

        lib.notify({
            title = locale('notify_title'),
            description = locale('successful_skillcheck'),
            type = 'success'
        })
    else
        ClearPedTasksImmediately(cache.ped)
        
        local anim = {
            dict = 'melee@hatchet@streamed_core',
            clip = 'plyr_front_takedown_b',
            lockX = true,
            lockY = true,
            lockZ = false,
            duration = 5000,
            flag = 15
        }
        
        lib.requestAnimDict(anim.dict)
    
        TaskPlayAnim(cache.ped, anim.dict, anim.clip, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1, anim.flag or 49, anim.playbackRate or 0, anim.lockX, anim.lockY, anim.lockZ)
        RemoveAnimDict(anim.dict)

        lib.notify({
            title = locale('notify_title'),
            description = locale('missed_skillcheck'),
            type = 'error'
        })
    end
end

AddEventHandler("lumberjack:cutTree", function (data)
    CutTree(data)
end)

AddEventHandler('ox:playerLoaded',function ()
    TriggerEvent('lumberjack:CarryLog')
end)

function CustomControl()
    Citizen.CreateThread(function ()
        local playerPed = PlayerPedId()
        local enable = true
        
        while enable do
            if IsControlPressed(0, 35) then -- Right
                FreezeEntityPosition(playerPed, false)
                SetEntityHeading(playerPed, GetEntityHeading(playerPed)+0.5)

            elseif IsControlPressed(0, 34) then -- Left
                FreezeEntityPosition(playerPed, false)
                SetEntityHeading(playerPed, GetEntityHeading(playerPed)-0.5)

            elseif IsControlPressed(0, 32) or IsControlPressed(0, 33) then
                FreezeEntityPosition(playerPed, false)

            else
                FreezeEntityPosition(playerPed, true)
                TaskPlayAnim(PlayerPedId(), 'combat@drag_ped@', 'injured_drag_plyr', 0.0, 0.0, 1, 2, 7, false, false, false)
            end
            Wait(0)

            if carryLog ~= 0 then
                enable = true
            else
                enable = false
            end
        end
        FreezeEntityPosition(playerPed, false)
        ClearPedSecondaryTask(playerPed)
        ClearPedTasksImmediately(playerPed)
    end)
end

function PlayCarryAnim()
    if carryLog ~= 0 then
        lib.requestAnimDict('combat@drag_ped@')
        TaskPlayAnim(PlayerPedId(), 'combat@drag_ped@', 'injured_drag_plyr', 2.0, 2.0, 100000, 1, 0, false, false, false)
        CustomControl()
        
        while carryLog ~= 0 do
            while not IsEntityPlayingAnim(PlayerPedId(), 'combat@drag_ped@', 'injured_drag_plyr', 1) do
                TaskPlayAnim(PlayerPedId(), 'combat@drag_ped@', 'injured_drag_plyr', 2.0, 2.0, 100000, 1, 0, false, false, false)
                Wait(0)
            end

            Wait(500)
        end
    else
        ClearPedSecondaryTask(PlayerPedId())
    end
end

AddEventHandler('lumberjack:CarryLog', function ()
    local logCount = exports.ox_inventory:Search('count', 'log')
    
    if logCount > 0 then
        local playerPed = cache.ped
        TriggerEvent('ox_inventory:disarm')
        FreezeEntityPosition(playerPed, false)
        
        lib.requestModel(Config.log) -- log
        DeleteEntity(carryLog)
        carryLog = CreateObject(1366334172, GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetEntityInvincible(carryLog, true)
        SetEntityHealth(carryLog, 0)
        AttachEntityToEntity(carryLog, PlayerPedId(),11816, -0.05, 2.4, -0.7, -15, 30, 0, false, false, false, true, 2, true)
        PlayCarryAnim()
    else
        DeleteEntity(carryLog)
        carryLog = 0
        PlayCarryAnim()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    ClearAllPedProps(cache.ped)

    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if carryLog ~= 0 then
        DeleteEntity(carryLog)
        carryLog = 0
    end
end)