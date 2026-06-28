const { getConfig, sendJSON } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    if (req.method === 'GET') {
        const config = await getConfig();
        sendJSON(res, 200, { success: true, config: config });
        return;
    }
    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
