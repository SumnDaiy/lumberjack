lib.locale()

local isWorking = false
local hasTrailer = false
local trailerEntity = nil
local netId = nil
local blip = nil
local npc = nil
local playerState = LocalPlayer.state

if Config.AddBlip then
    local settings = Config.BlipSettings
    AddTextEntry(settings.name, settings.name)
    local blip = AddBlipForCoord(settings.coords.x, settings.coords.y, settings.coords.z)
    SetBlipSprite(blip, settings.id)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, settings.scale)
    SetBlipColour(blip, settings.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName(settings.name)
    EndTextCommandSetBlipName(blip)
end

local function CreateBlip(vehicle, coords)
    local blip = coords and AddBlipForCoord(coords.x, coords.y, coords.z) or AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 208)
    SetBlipDisplay(blip, 6)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, false)

    if coords == nil then
        AddTextEntry('trailerBlip', locale('blip_trailer'))
        SetBlipColour(blip, 0)
    else
        AddTextEntry('trailerBlip', locale('blip_trailer_lost'))
        SetBlipColour(blip, 1)
    end
        BeginTextCommandSetBlipName('trailerBlip')
        EndTextCommandSetBlipName(blip)

    return blip
end

AddStateBagChangeHandler('ped', nil, function(bagName, key, value)
    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 or not value then return end

    if Config.target and not npc then
        npc = NetworkGetNetworkIdFromEntity(entity)

        local options = {
            {
                name = 'lumberjack_openmenu',
                icon = 'fa-solid fa-briefcase',
                label = locale('open_menu', ""),
                canInteract = function()
                    if not playerState.dead then return true end
                end,
                onSelect = function()
                    lib.showMenu('lumberjack_menu')
                end
            }
        }
        exports.ox_target:addEntity(npc, options)
    end
    
    if NetworkGetEntityOwner(entity) == cache.playerId then

        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(100)
        end

        FreezeEntityPosition(entity, true)
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
    end
end)

AddStateBagChangeHandler('trailerHandler', nil, function(bagName, key, value)
    if not player then return end

    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 or not value then return end

    if player then
        if value[player.charid] then
            netId = NetworkGetNetworkIdFromEntity(entity)
            TriggerEvent('lumberjack:addTarget', netId)

            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            blip = CreateBlip(entity, nil)

            local trailerCoords = GetEntityCoords(entity)

            while DoesEntityExist(entity) do
                trailerCoords = GetEntityCoords(entity)
                Wait(200)
            end

            RemoveBlip(blip)
            blip = CreateBlip(nil, trailerCoords)
        end
    end
end)

local alloptions = {
    {label = locale('start_job'), icon = 'play', args = {'start_job'}},
    {label = locale('stop_job'), icon = 'stop', args = {'stop_job'}},
    {label = locale('get_trailer'), icon = 'trailer', args = {'get_trailer'}},
    {label = locale('get_payment'), icon = 'money-bill-1', args = {'get_payment'}}
}

local options = {alloptions[1]}

MenuData = {
    id = 'lumberjack_menu',
    title = locale('menu_title'),
    position = 'top-right',
    options = options
}

function NewOptions()
    options = {alloptions[1]}
    if isWorking then
        options = {alloptions[2]}

        if not hasTrailer then
            options[#options+1] = alloptions[3]
        end

        if hasTrailer and trailerEntity then
            options[#options+1] = alloptions[4]
        end
    end
    MenuData = {
        id = 'lumberjack_menu',
        title = locale('menu_title'),
        position = 'top-right',
        options = options
    }
    lib.hideMenu()
    lib.registerMenu(MenuData, MenuCB)
    lib.showMenu('lumberjack_menu')
end

function MenuCB(selected, _, args)
    if args[1] == "start_job" then
        isWorking = true

    elseif args[1] == 'stop_job' then

        if hasTrailer then
            local alert = lib.alertDialog({
                header = locale('alert_header'),
                content = locale('alert_warning'),
                centered = true,
                cancel = true,
                labels = {
                    cancel = "No",
                    confirm = "Yes"
                }
            })

            if alert == 'confirm' then
                TriggerEvent('lumberjack:removeTarget', netId)
                local deleted = lib.callback.await('lumberjack:DeleteTrailer', 200, trailerEntity.entityID)

                if deleted then
                    isWorking = false
                    hasTrailer = false
                    trailerEntity = nil
                    netId = nil
                end
            end
        else
            isWorking = false
        end
    elseif args[1] == 'get_trailer' then
        local coords = Config.trailerSpawnCoords
        local occupied = IsPositionOccupied(coords.x, coords.y, coords.z, 20, false, true, false, false, false, 0, false)

        if not occupied then
            local vehicle = lib.callback.await('lumberjack:createTrailer', 200)

            if vehicle then
                hasTrailer = true
                trailerEntity = 
                    {
                        entityID = vehicle.entity,
                        netID = vehicle.netid,
                        plate = vehicle.plate
                    }
                lib.notify({
                    title = locale('notify_title'),
                    description = locale('trailer_created'),
                    position = 'top',
                    type = 'success'
                })
            end
        else
            lib.notify({
                title = locale('notify_title'),
                description = locale('area_occupied'),
                position = 'top',
                type = 'error'
            })
        end
    elseif args[1] == 'get_payment' then
        if hasTrailer and isWorking and trailerEntity then
            local logCount = GetLogsOnTrailer(trailerEntity.netID)
            if logCount ~= nil and logCount > 0 then
                if #(Config.bossLocation.xyz - GetEntityCoords(cache.ped)) < 5 then
                    local removed = lib.callback.await('lumberjack:RemoveAllVehicleLog',200, trailerEntity.netID)

                    if removed then
                        lib.callback.await('lumberjack:GetPayment', 200, removed*Config.PriceMultiplier)
                    end
                end
            else
                lib.notify({
                    title = locale('notify_title'),
                    description = locale('tree_missing'),
                    position = 'top',
                    type = 'error'
                })
            end
        end
    end
    NewOptions()
end

lib.registerMenu(MenuData, MenuCB)

if not Config.target then
    local bossPoint = lib.points.new(Config.bossLocation.xyz,2,{ text = locale('open_menu', "[E] -"), options = { position = 'top-center', icon = 'tree', style = {}}})
    function bossPoint:nearby()
        if lib.getOpenMenu() ~= 'lumberjack_menu' then --if the menu is not open only then show TextUi
            lib.showTextUI(self.text,self.options)
        end

        if self.currentDistance < 2 and IsControlJustReleased(2,51) then
            lib.hideTextUI()
            lib.showMenu('lumberjack_menu')
        end
        function bossPoint:onExit()
            lib.hideTextUI()
            lib.hideMenu()
        end
    end
end

RegisterCommand('menu', function()
    lib.showMenu('lumberjack_menu')
end) 


AddEventHandler('ox:playerLogout', function()
    if netId ~= nil then
        TriggerEvent('lumberjack:removeTarget', netId)
        netId = nil
    end
end)


--@TODO Working Group System
--[[ local groupList = {}
local function inviteInputDialog()
    ---@diagnostic disable-next-line: missing-parameter
    local input = lib.inputDialog('Invite to Group', {
        { type = "input", label = "ServerID", placeholder = "ServerID", icon = "user" }
    })
    if not input then print('no input') return end
    local invitedid = tonumber(input[1])
    local client = GetPlayerServerId((cache.playerId))
    if invitedid == client then
        print('You can\'t invite yourself')
    elseif invitedid == 0 then
        print('ServerID cant be 0')
    else
        local target = lib.callback.await('lumberjack:returnPlayer', 200, invitedid)
        if not target then
            print('no player found')
        else
            groupList[target.charid] = target.name
            print(groupList[target.charid]) 
        end
    end
end ]]

--[[ lib.registerContext({
    id = 'group_manager',
    title = 'Lumberjack Group',
    onExit = function()
        print('Hello there')
    end,
    options = {
        {
            title = locale('invite_player'),
            description = locale('invite_player_description'),
            onSelect = function()
                inviteInputDialog()
            end
        },
        {
            title = locale('current_group'),
            menu = 'group_members_menu',
            description = locale('current_group_description'),
            metadata = {'It also has metadata support'}
        },
    },
    {
        id = 'group_members_menu',
        title = locale('group_members'),
        menu = 'group_manager',
        options = {
            {
                title = player.name,
                description = player.serverid,
                metadata = {"You"}
            },
            {
                title = "Quari Mor",
                description = "[2] - ServerID",
                metadata = {"Kick"},
                onSelect = function ()
                    print('kick player')
                end
            }
        }
    }
})

RegisterCommand('testcontext', function()
    lib.showContext('group_manager')
end) ]]