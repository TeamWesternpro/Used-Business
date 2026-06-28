const { getListings, readBody, sendJSON, getConfig } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    if (req.method === 'POST') {
        const body = await readBody(req);
        if (!body || !body.username || !body.business) {
            sendJSON(res, 400, { success: false, error: 'Name and business are required.' });
            return;
        }

        const config = await getConfig();
        if (config.bookingsWebhook) {
            const listings = await getListings();
            const listing = listings.find(function(l) { return l.id === body.listingId; }) || {};
            sendDiscordWebhook(config.bookingsWebhook, {
                embeds: [{
                    title: 'New Booking Request',
                    description: '**' + (body.business || 'Unknown Business') + '**',
                    color: 5814783,
                    fields: [
                        { name: 'Requester', value: body.username, inline: true },
                        { name: 'Phone', value: body.phone || 'N/A', inline: true },
                        { name: 'Business Type', value: (listing.type || 'N/A'), inline: true },
                        { name: 'Date', value: body.date || 'N/A', inline: true },
                        { name: 'Time', value: body.time || 'N/A', inline: true }
                    ],
                    footer: { text: 'Used Businesses' },
                    timestamp: new Date().toISOString()
                }]
            });
        }

        sendJSON(res, 200, { success: true });
        return;
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
