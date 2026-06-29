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
    for i, pedConfig in ipairs(Config.Peds) do
        local hash = LoadModel(pedConfig.model)
        local coords = pedConfig.coords

        local x, y, z, heading
        if type(coords) == 'userdata' then
            x = coords.x
            y = coords.y
            z = coords.z
            heading = coords.w or 0.0
        elseif type(coords) == 'table' then
            x = coords.x or coords[1]
            y = coords.y or coords[2]
            z = coords.z or coords[3]
            heading = coords.w or coords.heading or coords[4] or 0.0
        end

        if not x or not y or not z then
            print('[UsedDealership] Invalid coordinates for ped #' .. i)
            goto continue
        end

        print('[UsedDealership] Spawning ped #' .. i .. ' at: ' .. tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(z) .. ' heading: ' .. tostring(heading))

        RequestCollisionAtCoord(x, y, z)
        local timeout = 0
        local found, groundZ = false, 0
        while timeout < 100 do
            found, groundZ = GetGroundZFor_3dCoord(x, y, z + 25.0, false)
            if found then break end
            Wait(10)
            timeout = timeout + 1
        end
        if found then
            z = groundZ
            if Config.Debug then
                print('[UsedDealership] Ground Z found at: ' .. tostring(z))
            end
        elseif Config.Debug then
            print('[UsedDealership] Ground Z not found, using original Z: ' .. tostring(z))
        end

        if not HasModelLoaded(hash) then
            print('[UsedDealership] Model not loaded for ped #' .. i .. ': ' .. pedConfig.model)
            SetModelAsNoLongerNeeded(hash)
            goto continue
        end

        local p = CreatePed(4, hash, x, y, z, heading, true, true)

        if p == 0 or not DoesEntityExist(p) then
            print('[UsedDealership] Failed to create ped #' .. i .. ' at: ' .. tostring(x) .. ', ' .. tostring(y) .. ', ' .. tostring(z))
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

        print('[UsedDealership] Spawned ped #' .. i .. ' (' .. pedConfig.model .. ')')

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
            print('[UsedDealership] Blip #' .. i .. ' (' .. pedConfig.blip.label .. ') sprite:' .. pedConfig.blip.sprite .. ' colour:' .. pedConfig.blip.color)
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
