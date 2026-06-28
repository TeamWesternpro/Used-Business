const { getConfig, saveConfig, readBody, sendJSON } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    const config = getConfig();

    if (req.method === 'GET') {
        sendJSON(res, 200, { success: true, config: config });
        return;
    }

    if (req.method === 'POST') {
        const body = await readBody(req);
        if (body && body.businessTypes) config.businessTypes = body.businessTypes;
        if (body && body.tagOptions) config.tagOptions = body.tagOptions;
        saveConfig(config);
        sendJSON(res, 200, { success: true, config: config });
        return;
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
