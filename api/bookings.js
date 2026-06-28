const { getListings, readBody, sendJSON } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }
    if (req.method !== 'POST') { sendJSON(res, 405, { success: false, error: 'Method not allowed' }); return; }

    const body = await readBody(req);
    if (!body || !body.username || !body.business) {
        sendJSON(res, 400, { success: false, error: 'Name and business are required.' });
        return;
    }

    sendJSON(res, 200, { success: true });
};
