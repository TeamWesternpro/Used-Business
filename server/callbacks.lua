ESX = nil

if GetResourceState('es_extended') == 'started' then
    ESX = exports['es_extended']:getSharedObject()
end

QBCore = nil

if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function GetPlayerData(src)
    if ESX then
        return ESX.GetPlayerData(src)
    elseif QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player then
            return {
                identifier = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                job = player.PlayerData.job
            }
        end
    end
    return nil
end

if lib then
    lib.callback.register('useddealership:server:getListings', function(source)
        return listings
    end)

    lib.callback.register('useddealership:server:isAuthenticated', function(source)
        return IsAdmin(source)
    end)

    lib.callback.register('useddealership:server:getPlayerData', function(source)
        return GetPlayerData(source)
    end)
end
