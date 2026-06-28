local spawnedPeds = {}
local spawnedBlips = {}
local isAdmin = false
local tabletOpen = false
local cachedListings = {}
local nearestPedIndex = nil

local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(1)
    end
    return hash
end

local function CreatePedAndBlip()
    for i, ped in ipairs(Config.Peds) do
        local hash = LoadModel(ped.model)

        local x, y, z, heading = ped.coords.x, ped.coords.y, ped.coords.z, ped.coords.w

        RequestCollisionAtCoord(x, y, z)
        local timeout = 0
        local found, groundZ = false, 0
        while timeout < 50 do
            found, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
            if found then break end
            Wait(10)
            timeout = timeout + 1
        end
        if found then z = groundZ end

        local p = CreatePed(4, hash, x, y, z, heading, false, true)
        SetEntityAsMissionEntity(p, true, true)
        SetBlockingOfNonTemporaryEvents(p, true)
        SetPedDiesWhenInjured(p, false)
        SetPedCanPlayAmbientAnims(p, true)
        SetPedCanRagdollFromPlayerImpact(p, false)
        SetEntityInvincible(p, true)
        FreezeEntityPosition(p, true)
        SetModelAsNoLongerNeeded(hash)
        spawnedPeds[i] = p

        if ped.blip and ped.blip.enabled then
            local b = AddBlipForCoord(x, y, z)
            SetBlipSprite(b, ped.blip.sprite)
            SetBlipDisplay(b, 4)
            SetBlipScale(b, ped.blip.scale)
            SetBlipColour(b, ped.blip.color)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(ped.blip.label)
            EndTextCommandSetBlipName(b)
            spawnedBlips[i] = b
        end
    end
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function IsNearPed()
    nearestPedIndex = nil
    local playerCoords = GetEntityCoords(PlayerPedId())
    for i, p in ipairs(spawnedPeds) do
        if DoesEntityExist(p) then
            local pedCoords = GetEntityCoords(p)
            if #(playerCoords - pedCoords) < Config.Tablet.InteractionDistance then
                nearestPedIndex = i
                return true
            end
        end
    end
    return false
end

local function OpenTablet()
    if tabletOpen then return end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        isAdmin = isAdmin
    })
    TriggerServerEvent('useddealership:server:requestSync')
end

local function CloseTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeTablet'
    })
end

RegisterNetEvent('useddealership:client:receiveListings', function(data)
    cachedListings = data or {}
    SendNUIMessage({
        action = 'updateListings',
        listings = cachedListings
    })
end)

RegisterNetEvent('useddealership:client:receiveConfig', function(data)
    SendNUIMessage({
        action = 'updateConfig',
        config = data
    })
end)

RegisterNetEvent('useddealership:client:receiveWebhook', function(listingsUrl, bookingsUrl)
    SendNUIMessage({
        action = 'receiveWebhook',
        listings = listingsUrl or '',
        bookings = bookingsUrl or ''
    })
end)

RegisterNetEvent('useddealership:client:notify', function(type, message)
    SendNUIMessage({
        action = 'notify',
        notifyType = type,
        message = message
    })
end)

RegisterNetEvent('useddealership:client:setAdmin', function(admin)
    isAdmin = admin
    SendNUIMessage({
        action = 'setAdmin',
        isAdmin = admin
    })
end)

RegisterCommand(Config.Tablet.Command, function()
    if tabletOpen then
        CloseTablet()
    else
        OpenTablet()
    end
end, false)

RegisterKeyMapping(Config.Tablet.Command, 'Open Used Dealership Tablet', 'keyboard', Config.Tablet.Keybind)

CreateThread(function()
    CreatePedAndBlip()
    TriggerServerEvent('useddealership:server:requestSync')
    TriggerServerEvent('useddealership:server:checkAdmin')
end)

CreateThread(function()
    while true do
        local sleep = 500

        if IsNearPed() then
            sleep = 0
            local p = spawnedPeds[nearestPedIndex]
            if p and DoesEntityExist(p) then
                local pedCoords = GetEntityCoords(p)
                DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, Config.Tablet.PromptText)

                if IsControlJustPressed(0, Config.Tablet.InteractionKey) then
                    OpenTablet()
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNUICallback('closeTablet', function(data, cb)
    CloseTablet()
    cb('ok')
end)

RegisterNUICallback('requestSync', function(data, cb)
    TriggerServerEvent('useddealership:server:requestSync')
    cb('ok')
end)

RegisterNUICallback('openDashboard', function(data, cb)
    if isAdmin then
        SendNUIMessage({
            action = 'openDashboard'
        })
    else
        SendNUIMessage({
            action = 'notify',
            notifyType = 'error',
            message = 'You do not have admin access.'
        })
    end
    cb('ok')
end)

RegisterNUICallback('addListing', function(data, cb)
    TriggerServerEvent('useddealership:server:addListing', data)
    cb('ok')
end)

RegisterNUICallback('editListing', function(data, cb)
    TriggerServerEvent('useddealership:server:editListing', data)
    cb('ok')
end)

RegisterNUICallback('deleteListing', function(data, cb)
    TriggerServerEvent('useddealership:server:deleteListing', data)
    cb('ok')
end)

RegisterNUICallback('resendWebhook', function(data, cb)
    TriggerServerEvent('useddealership:server:resendWebhook', data)
    cb('ok')
end)

RegisterNUICallback('getWebhook', function(data, cb)
    TriggerServerEvent('useddealership:server:getWebhook')
    cb('ok')
end)

RegisterNUICallback('saveWebhook', function(data, cb)
    TriggerServerEvent('useddealership:server:saveWebhook', data)
    cb('ok')
end)

RegisterNUICallback('submitBooking', function(data, cb)
    TriggerServerEvent('useddealership:server:submitBooking', data)
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, p in ipairs(spawnedPeds) do
            if DoesEntityExist(p) then
                DeleteEntity(p)
            end
        end
        for _, b in ipairs(spawnedBlips) do
            if DoesBlipExist(b) then
                RemoveBlip(b)
            end
        end
        if tabletOpen then
            CloseTablet()
        end
    end
end)
