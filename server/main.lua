local listings = {}
local bookings = {}
local isLoaded = false

local function GetResPath()
    return GetResourcePath(GetCurrentResourceName())
end

local function SaveConfig()
    local config = {
        businessTypes = Config.BusinessTypes or { 'Dealership', 'Mechanic', 'Shops', 'Houses' },
        tagOptions = Config.TagOptions or { 'Available', 'Not Available' }
    }
    local path = GetResPath() .. '/data/config.json'
    local file = io.open(path, 'w')
    if file then
        file:write(json.encode(config, { indent = true }))
        file:close()
    end
end

local function LoadListings()
    local path = GetResPath() .. '/data/listings.json'
    local file = io.open(path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        if content and content ~= '' then
            local decoded = json.decode(content)
            if decoded then
                listings = decoded
            end
        end
    else
        listings = {}
    end
    isLoaded = true
    if Config.Debug then
        print('[UsedDealership] Loaded ' .. #listings .. ' listings')
    end
end

local function SaveListings()
    local path = GetResPath() .. '/data/listings.json'
    local file = io.open(path, 'w')
    if file then
        local encoded = json.encode(listings, { indent = true })
        file:write(encoded)
        file:close()
        return true
    end
    return false
end

local function LoadBookings()
    local path = GetResPath() .. '/data/bookings.json'
    local file = io.open(path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        if content and content ~= '' then
            local decoded = json.decode(content)
            if decoded then
                bookings = decoded
            end
        end
    end
end

local function SaveBookings()
    local path = GetResPath() .. '/data/bookings.json'
    local file = io.open(path, 'w')
    if file then
        file:write(json.encode(bookings, { indent = true }))
        file:close()
        return true
    end
    return false
end

local function GenerateId()
    return tostring(os.time()) .. tostring(math.random(1000, 9999))
end

local function IsAdmin(src)
    local license = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if string.find(identifier, 'license:') then
            license = string.gsub(identifier, 'license:', '')
            break
        end
    end

    if IsPlayerAceAllowed(src, 'useddealership.admin') then
        return true
    end
    if IsPlayerAceAllowed(src, 'useddealership.owner') then
        return true
    end
    if license and Config.AdminLicenses then
        for _, lic in ipairs(Config.AdminLicenses) do
            if lic == license then
                return true
            end
        end
    end

    return false
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadListings()
        LoadBookings()
        SaveConfig()
    end
end)

RegisterNetEvent('useddealership:server:requestSync', function()
    local src = source
    if Config.Debug then
        print('[UsedDealership] requestSync from source: ' .. tostring(src))
    end
    TriggerClientEvent('useddealership:client:receiveListings', src, listings)
    TriggerClientEvent('useddealership:client:receiveConfig', src, {
        businessTypes = Config.BusinessTypes or { 'Dealership', 'Mechanic', 'Shops', 'Houses' },
        tagOptions = Config.TagOptions or { 'Available', 'Not Available' }
    })
end)

RegisterNetEvent('useddealership:server:addListing', function(data)
    local src = source
    if Config.Debug then
        print('[UsedDealership] addListing from source: ' .. tostring(src) .. ', title: ' .. tostring(data.title))
    end
    if not IsAdmin(src) then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'You do not have permission to do this.')
        return
    end

    if not data or not data.title or not data.type then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid listing data.')
        return
    end

    local newListing = {
        id = GenerateId(),
        title = data.title or 'Untitled',
        description = data.description or '',
        tags = data.tags or 'Available',
        type = data.type or 'Dealership',
        price = tonumber(data.price) or 0,
        postal = data.postal or '',
        thumbnail = data.thumbnail or '',
        createdAt = os.time(),
        updatedAt = os.time()
    }

    table.insert(listings, newListing)
    SaveListings()

    TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing added successfully!')
    TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

    if Config.Debug then
        print('[UsedDealership] Added listing: ' .. newListing.title)
    end
end)

RegisterNetEvent('useddealership:server:editListing', function(data)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'You do not have permission to do this.')
        return
    end

    if not data or not data.id then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid listing data.')
        return
    end

    print('[UsedDealership] Editing listing: ' .. data.id)
    for i, listing in ipairs(listings) do
        if listing.id == data.id then
            listings[i].title = data.title or listing.title
            listings[i].description = data.description or listing.description
            listings[i].tags = data.tags or listing.tags
            listings[i].type = data.type or listing.type
            listings[i].price = tonumber(data.price) or listing.price
            listings[i].postal = data.postal ~= nil and data.postal or listing.postal
            listings[i].thumbnail = data.thumbnail or listing.thumbnail
            listings[i].updatedAt = os.time()

            SaveListings()

            TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing updated successfully!')
            TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

            if Config.Debug then
                print('[UsedDealership] Edited listing: ' .. listings[i].title)
            end
            return
        end
    end

    TriggerClientEvent('useddealership:client:notify', src, 'error', 'Listing not found.')
end)

RegisterNetEvent('useddealership:server:deleteListing', function(data)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'You do not have permission to do this.')
        return
    end

    if not data or not data.id then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid listing data.')
        return
    end

    for i, listing in ipairs(listings) do
        if listing.id == data.id then
            print('[UsedDealership] Deleting listing: ' .. listing.title)
            local removed = table.remove(listings, i)
            SaveListings()

            TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing deleted successfully!')
            TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

            if Config.Debug then
                print('[UsedDealership] Deleted listing: ' .. removed.title)
            end
            return
        end
    end

    TriggerClientEvent('useddealership:client:notify', src, 'error', 'Listing not found.')
end)

RegisterNetEvent('useddealership:server:checkAdmin', function()
    local src = source
    local admin = IsAdmin(src)
    TriggerClientEvent('useddealership:client:setAdmin', src, admin)
end)

RegisterNetEvent('useddealership:server:submitBooking', function(data)
    local src = source
    if not data or not data.username or not data.business then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid booking data.')
        return
    end

    local booking = {
        id = GenerateId(),
        listingId = data.listingId or '',
        business = data.business,
        username = data.username,
        phone = data.phone or '',
        date = data.date or '',
        time = data.time or '',
        notes = data.notes or '',
        createdAt = os.time()
    }

    table.insert(bookings, booking)
    SaveBookings()

    TriggerClientEvent('useddealership:client:notify', src, 'success', 'Booking request sent!')
end)

RegisterNetEvent('useddealership:server:getBookings', function()
    local src = source
    if not IsAdmin(src) then return end
    TriggerClientEvent('useddealership:client:receiveBookings', src, bookings)
end)

exports('GetListings', function()
    return listings
end)

exports('GetListingById', function(id)
    for _, listing in ipairs(listings) do
        if listing.id == id then
            return listing
        end
    end
    return nil
end)
