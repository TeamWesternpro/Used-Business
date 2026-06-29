local spawnedPeds = {}
local spawnedBlips = {}
local isAdmin = false
local tabletOpen = false
local cachedListings = {}
local nearestPedIndex = nil

local function CreatePedAndBlip()
    for i, pedConfig in ipairs(Config.Peds) do
        local model = pedConfig.model
        local hash = GetHashKey(model)
        RequestModel(hash)
        local attempts = 0
        while not HasModelLoaded(hash) and attempts < 200 do
            Wait(50)
            attempts = attempts + 1
        end
        if not HasModelLoaded(hash) then
            print('[UsedDealership] Failed to load model for ped #' .. i .. ': ' .. model)
            goto continue
        end

        local coords = pedConfig.coords
        local x, y, z, heading

        if coords then
            x = coords.x or coords[1]
            y = coords.y or coords[2]
            z = coords.z or coords[3]
            heading = coords.w or coords.heading or coords[4] or 0.0
        end

        if not x or not y or not z then
            print('[UsedDealership] Invalid coordinates for ped #' .. i)
            SetModelAsNoLongerNeeded(hash)
            goto continue
        end

        RequestCollisionAtCoord(x, y, z)
        Wait(100)

        local found, gz = GetGroundZFor_3dCoord(x, y, z + 100.0, false)
        if found and gz then
            z = gz
        end

        Wait(100)

        local p = CreatePed(4, hash, x, y, z, heading, true, true)
        if p == 0 then
            print('[UsedDealership] CreatePed returned 0 for ped #' .. i)
            SetModelAsNoLongerNeeded(hash)
            goto continue
        end

        SetEntityAsMissionEntity(p, true, true)
        SetBlockingOfNonTemporaryEvents(p, true)
        SetPedDiesWhenInjured(p, false)
        SetPedCanPlayAmbientAnims(p, true)
        SetPedCanRagdollFromPlayerImpact(p, false)
        SetEntityInvincible(p, true)
        FreezeEntityPosition(p, true)
        SetModelAsNoLongerNeeded(hash)

        spawnedPeds[i] = p
        print('[UsedDealership] Spawned ped #' .. i .. ' (' .. model .. ') at ' .. tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(z))

        if pedConfig.blip and pedConfig.blip.enabled then
            local b = AddBlipForCoord(x, y, z)
            SetBlipSprite(b, pedConfig.blip.sprite)
            SetBlipDisplay(b, 4)
            SetBlipScale(b, pedConfig.blip.scale)
            SetBlipColour(b, pedConfig.blip.color)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(pedConfig.blip.label)
            EndTextCommandSetBlipName(b)
            spawnedBlips[i] = b
            print('[UsedDealership] Blip #' .. i .. ' created')
        end

        ::continue::
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
    print('[UsedDealership Client] Received listings update: ' .. tostring(#data) .. ' listings')
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
    if admin then
        SendNUIMessage({
            action = 'openDashboard'
        })
    else
        SendNUIMessage({
            action = 'notify',
            notifyType = 'error',
            message = '[Used Dealership] You do not have permission to access the admin panel.'
        })
    end
end)

RegisterCommand(Config.Tablet.Command, function()
    if tabletOpen then
        CloseTablet()
    else
        OpenTablet()
    end
end, false)

RegisterCommand('usedadmin', function()
    if tabletOpen then
        CloseTablet()
    else
        OpenTablet()
        TriggerServerEvent('useddealership:server:checkAdmin')
    end
end, false)

RegisterKeyMapping(Config.Tablet.Command, 'Open Used Dealership Tablet', 'keyboard', Config.Tablet.Keybind)

CreateThread(function()
    CreatePedAndBlip()
    TriggerServerEvent('useddealership:server:requestSync')
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
    TriggerServerEvent('useddealership:server:checkAdmin')
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

RegisterNUICallback('submitBooking', function(data, cb)
    TriggerServerEvent('useddealership:server:submitBooking', data)
    cb('ok')
end)

RegisterNUICallback('requestBookings', function(data, cb)
    TriggerServerEvent('useddealership:server:getBookings')
    cb('ok')
end)

RegisterNetEvent('useddealership:client:receiveBookings', function(data)
    SendNUIMessage({
        action = 'updateBookings',
        bookings = data or {}
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, p in pairs(spawnedPeds) do
            if DoesEntityExist(p) then
                DeleteEntity(p)
            end
        end
        for _, b in pairs(spawnedBlips) do
            if DoesBlipExist(b) then
                RemoveBlip(b)
            end
        end
        if tabletOpen then
            CloseTablet()
        end
    end
end)
