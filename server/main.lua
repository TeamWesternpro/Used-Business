local listings = {}
local isLoaded = false
local savedWebhook = ''
local savedBookingWebhook = ''

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

local function LoadWebhook()
    local path = GetResPath() .. '/data/webhook.json'
    local file = io.open(path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        if content and content ~= '' then
            local decoded = json.decode(content)
            if decoded then
                if decoded.listings then
                    savedWebhook = decoded.listings
                elseif decoded.url then
                    savedWebhook = decoded.url
                end
                if decoded.bookings then
                    savedBookingWebhook = decoded.bookings
                end
            end
        end
    end
end

local function SaveWebhook(listingsUrl, bookingsUrl)
    savedWebhook = listingsUrl or ''
    savedBookingWebhook = bookingsUrl or ''
    local path = GetResPath() .. '/data/webhook.json'
    local file = io.open(path, 'w')
    if file then
        file:write(json.encode({ listings = savedWebhook, bookings = savedBookingWebhook }, { indent = true }))
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
        print('[UsedDealingship] Loaded ' .. #listings .. ' listings')
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

-- Website sync (Vercel)
local function SyncFromWebsite()
    if not Config.WebsiteURL or Config.WebsiteURL == '' then return end
    local url = Config.WebsiteURL .. '/api/listings'
    PerformHttpRequest(url, function(statusCode, text)
        if statusCode == 200 and text then
            local ok, data = pcall(json.decode, text)
            if ok and data and data.success and data.listings then
                listings = data.listings
                SaveListings()
                TriggerClientEvent('useddealership:client:receiveListings', -1, listings)
                if Config.Debug then
                    print('[UsedDealership] Synced ' .. #listings .. ' listings from website')
                end
            end
        else
            print('[UsedDealership] Website sync failed (HTTP ' .. tostring(statusCode) .. '), using local data')
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end

local function PushToWebsite(method, data)
    if not Config.WebsiteURL or Config.WebsiteURL == '' then return end
    local url = Config.WebsiteURL .. '/api/listings'
    if method ~= 'POST' then
        url = Config.WebsiteURL .. '/api/listings/' .. data.id
    end
    PerformHttpRequest(url, function(statusCode, text)
        if statusCode >= 200 and statusCode < 300 then
            if Config.Debug then
                print('[UsedDealership] Pushed to website: ' .. method)
            end
        else
            print('[UsedDealership] Website push failed (HTTP ' .. tostring(statusCode) .. ')')
        end
    end, method, json.encode(data), { ['Content-Type'] = 'application/json' })
end

local function GenerateId()
    return tostring(os.time()) .. tostring(math.random(1000, 9999))
end

local function Base64Decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

local function SendDiscordWebhook(listing)
    local webhookUrl = savedWebhook
    if not webhookUrl or webhookUrl == '' then
        return
    end

    local tagEmoji = listing.tags == 'Available' and '✅' or '❌'
    local typeIcon = '💼'
    if listing.type == 'Mechanic' then
        typeIcon = '🔧'
    elseif listing.type == 'Shops' then
        typeIcon = '🛒'
    elseif listing.type == 'Houses' then
        typeIcon = '🏠'
    end

    local embedFields = {
        { name = '📋 Type', value = '```' .. typeIcon .. ' ' .. (listing.type or 'Unknown') .. '```', inline = true },
        { name = '💰 Price', value = '```$' .. tostring(listing.price or 0) .. '```', inline = true },
        { name = '📊 Status', value = '```' .. tagEmoji .. ' ' .. (listing.tags or 'Available') .. '```', inline = true }
    }

    if listing.postal and listing.postal ~= '' then
        table.insert(embedFields, { name = '📍 Location', value = '```' .. listing.postal .. '```', inline = true })
    end

    if listing.description and listing.description ~= '' then
        local desc = listing.description
        if #desc > 200 then desc = string.sub(desc, 1, 200) end
        table.insert(embedFields, { name = '\u{200b}', value = '\u{200b}', inline = true })
        table.insert(embedFields, { name = '\u{200b}', value = '\u{200b}', inline = true })
        table.insert(embedFields, { name = '📝 Description', value = desc, inline = false })
    end

    local embed = {
        {
            author = { name = typeIcon .. ' New Business Listed!', icon_url = 'https://i.imgur.com/4Y4bEeI.png' },
            description = '**' .. (listing.title or 'Untitled') .. '**',
            color = listing.tags == 'Available' and 3066993 or 15158332,
            fields = embedFields,
            footer = { text = 'Used Businesses', icon_url = 'https://i.imgur.com/4Y4bEeI.png' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }

    local hasThumbnail = listing.thumbnail and listing.thumbnail ~= '' and string.find(listing.thumbnail, 'data:image')
    if hasThumbnail then
        local thumbData = listing.thumbnail
        local ext = 'png'
        if string.find(thumbData, 'image/jpeg') then ext = 'jpg'
        elseif string.find(thumbData, 'image/gif') then ext = 'gif' end
        embed[1].image = { url = 'attachment://thumbnail.' .. ext }

        local base64Content = string.gsub(thumbData, 'data:image/[^;]+;base64,', '')
        local binaryData = Base64Decode(base64Content)
        local boundary = '----FormBoundary' .. tostring(os.time()) .. tostring(math.random(1000, 9999))

        local body = ''
        body = body .. '--' .. boundary .. '\r\n'
        body = body .. 'Content-Disposition: form-data; name="payload_json"\r\n'
        body = body .. 'Content-Type: application/json\r\n\r\n'
        body = body .. json.encode({ embeds = embed }) .. '\r\n'
        body = body .. '--' .. boundary .. '\r\n'
        body = body .. 'Content-Disposition: form-data; name="files[0]"; filename="thumbnail.' .. ext .. '"\r\n'
        body = body .. 'Content-Type: image/' .. ext .. '\r\n\r\n'
        body = body .. binaryData .. '\r\n'
        body = body .. '--' .. boundary .. '--\r\n'

        PerformHttpRequest(webhookUrl, function(statusCode, text)
            if statusCode >= 200 and statusCode < 300 then
                print('[UsedDealership] Webhook sent: ' .. (listing.title or 'Unknown'))
            else
                print('[UsedDealership] Webhook failed: ' .. tostring(statusCode) .. ' ' .. tostring(text))
            end
        end, 'POST', body, { ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary })
    else
        local payload = json.encode({ embeds = embed })
        PerformHttpRequest(webhookUrl, function(statusCode, text)
            if statusCode >= 200 and statusCode < 300 then
                print('[UsedDealership] Webhook sent: ' .. (listing.title or 'Unknown'))
            else
                print('[UsedDealership] Webhook failed: ' .. tostring(statusCode))
            end
        end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    end
end

local function IsAdmin(src)
    local discordId = nil
    local license = nil

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if string.find(identifier, 'discord:') then
            discordId = string.gsub(identifier, 'discord:', '')
        elseif string.find(identifier, 'license:') then
            license = string.gsub(identifier, 'license:', '')
        end
    end

    local hasPermission = false

    if discordId then
        hasPermission = IsPlayerAceAllowed(src, 'discord:' .. discordId)
    end
    if not hasPermission and license then
        hasPermission = IsPlayerAceAllowed(src, 'license:' .. license)
    end
    if not hasPermission then
        hasPermission = IsPlayerAceAllowed(src, 'useddealership.admin')
    end
    if not hasPermission then
        hasPermission = IsPlayerAceAllowed(src, 'useddealership.owner')
    end

    return hasPermission
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadListings()
        LoadWebhook()
        SaveConfig()
        SyncFromWebsite()
    end
end)

RegisterNetEvent('useddealership:server:requestSync', function()
    local src = source
    TriggerClientEvent('useddealership:client:receiveListings', src, listings)
    TriggerClientEvent('useddealership:client:receiveConfig', src, {
        businessTypes = Config.BusinessTypes or { 'Dealership', 'Mechanic', 'Shops', 'Houses' },
        tagOptions = Config.TagOptions or { 'Available', 'Not Available' }
    })
end)

RegisterNetEvent('useddealership:server:addListing', function(data)
    local src = source
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
    SendDiscordWebhook(newListing)
    PushToWebsite('POST', newListing)

    TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing added successfully!')
    TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

    if Config.Debug then
        print('[UsedDealingship] Added listing: ' .. newListing.title)
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
            PushToWebsite('PUT', listings[i])

            TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing updated successfully!')
            TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

            if Config.Debug then
                print('[UsedDealingship] Edited listing: ' .. listings[i].title)
            end
            return
        end
    end

    TriggerClientEvent('useddealership:client:notify', src, 'error', 'Listing not found.')
end

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
            local removed = table.remove(listings, i)
            SaveListings()
            PushToWebsite('DELETE', { id = removed.id })

            TriggerClientEvent('useddealership:client:notify', src, 'success', 'Listing deleted successfully!')
            TriggerClientEvent('useddealership:client:receiveListings', -1, listings)

            if Config.Debug then
                print('[UsedDealingship] Deleted listing: ' .. removed.title)
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

RegisterNetEvent('useddealership:server:getWebhook', function()
    local src = source
    if not IsAdmin(src) then return end
    TriggerClientEvent('useddealership:client:receiveWebhook', src, savedWebhook, savedBookingWebhook)
end)

RegisterNetEvent('useddealership:server:saveWebhook', function(data)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'You do not have permission to do this.')
        return
    end

    local listingsUrl = data and data.listings or ''
    local bookingsUrl = data and data.bookings or ''
    SaveWebhook(listingsUrl, bookingsUrl)
    TriggerClientEvent('useddealership:client:notify', src, 'success', 'Webhook URLs saved!')
end)

RegisterNetEvent('useddealership:server:resendWebhook', function(data)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'You do not have permission to do this.')
        return
    end

    if not data or not data.id then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid listing ID.')
        return
    end

    for _, listing in ipairs(listings) do
        if listing.id == data.id then
            SendDiscordWebhook(listing)
            TriggerClientEvent('useddealership:client:notify', src, 'success', 'Webhook resent for: ' .. (listing.title or 'Unknown'))
            return
        end
    end

    TriggerClientEvent('useddealership:client:notify', src, 'error', 'Listing not found.')
end)

RegisterNetEvent('useddealership:server:submitBooking', function(data)
    local src = source
    if not data or not data.username or not data.business then
        TriggerClientEvent('useddealership:client:notify', src, 'error', 'Invalid booking data.')
        return
    end

    local playerName = GetPlayerName(src) or 'Unknown'
    local discordId = nil
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if string.find(identifier, 'discord:') then
            discordId = string.gsub(identifier, 'discord:', '')
        end
    end

    local listingInfo = nil
    if data.listingId then
        for _, listing in ipairs(listings) do
            if listing.id == data.listingId then
                listingInfo = listing
                break
            end
        end
    end

    local webhookUrl = savedBookingWebhook
    if webhookUrl and webhookUrl ~= '' then
        local tagEmoji = ''
        local typeIcon = '💼'
        if listingInfo then
            if listingInfo.tags == 'Available' then tagEmoji = '✅' else tagEmoji = '❌' end
            if listingInfo.type == 'Mechanic' then typeIcon = '🔧'
            elseif listingInfo.type == 'Shops' then typeIcon = '🛒'
            elseif listingInfo.type == 'Houses' then typeIcon = '🏠'
            end
        end

        local fields = {
            { name = '👤 Requester', value = '```' .. (data.username or 'Unknown') .. '```', inline = true },
            { name = '📞 Phone', value = '```' .. (data.phone or 'N/A') .. '```', inline = true },
            { name = '\u{200b}', value = '\u{200b}', inline = true }
        }

        if listingInfo then
            table.insert(fields, { name = '🏢 Business', value = '```' .. (data.business or 'Unknown') .. '```', inline = true })
            table.insert(fields, { name = '📋 Type', value = '```' .. typeIcon .. ' ' .. (listingInfo.type or 'N/A') .. '```', inline = true })
            table.insert(fields, { name = '💰 Price', value = '```$' .. tostring(listingInfo.price or 0) .. '```', inline = true })
            if listingInfo.postal and listingInfo.postal ~= '' then
                table.insert(fields, { name = '📍 Location', value = '```' .. listingInfo.postal .. '```', inline = true })
            end
            if listingInfo.description and listingInfo.description ~= '' then
                local desc = listingInfo.description
                if #desc > 200 then desc = string.sub(desc, 1, 200) end
                table.insert(fields, { name = '\u{200b}', value = '\u{200b}', inline = true })
                table.insert(fields, { name = '\u{200b}', value = '\u{200b}', inline = true })
                table.insert(fields, { name = '📝 Description', value = desc, inline = false })
            end
        else
            table.insert(fields, { name = '🏢 Business', value = '```' .. (data.business or 'Unknown') .. '```', inline = true })
            table.insert(fields, { name = '\u{200b}', value = '\u{200b}', inline = true })
        end

        table.insert(fields, { name = '───────────────────', value = '\u{200b}', inline = false })
        table.insert(fields, { name = '📅 Date', value = '```' .. (data.date or 'N/A') .. '```', inline = true })
        table.insert(fields, { name = '🕐 Time', value = '```' .. (data.time or 'N/A') .. '```', inline = true })
        table.insert(fields, { name = '\u{200b}', value = '\u{200b}', inline = true })

        if data.notes and data.notes ~= '' then
            table.insert(fields, { name = '💬 Notes', value = data.notes, inline = false })
        end

        local embed = {
            {
                author = { name = '📅 New Booking Request', icon_url = 'https://i.imgur.com/4Y4bEeI.png' },
                description = '**' .. (data.business or 'Unknown') .. '**',
                color = 5814783,
                fields = fields,
                footer = { text = 'Used Businesses', icon_url = 'https://i.imgur.com/4Y4bEeI.png' },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }

        PerformHttpRequest(webhookUrl, function(statusCode, text)
            if statusCode >= 200 and statusCode < 300 then
                print('[UsedDealership] Booking webhook sent for: ' .. (data.business or 'Unknown'))
            else
                print('[UsedDealership] Booking webhook failed: ' .. tostring(statusCode))
            end
        end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
    end

    TriggerClientEvent('useddealership:client:notify', src, 'success', 'Booking request sent!')
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
