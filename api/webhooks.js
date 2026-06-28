const { getConfig, saveConfig, readBody, sendJSON } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    if (req.method === 'GET') {
        const config = getConfig();
        sendJSON(res, 200, { success: true, webhooks: { listings: config.listingsWebhook || '', bookings: config.bookingsWebhook || '' } });
        return;
    }

    if (req.method === 'POST') {
        const body = await readBody(req);
        const config = getConfig();
        if (body && body.listings !== undefined) config.listingsWebhook = body.listings || '';
        if (body && body.bookings !== undefined) config.bookingsWebhook = body.bookings || '';
        saveConfig(config);
        sendJSON(res, 200, { success: true, webhooks: { listings: config.listingsWebhook, bookings: config.bookingsWebhook } });
        return;
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
