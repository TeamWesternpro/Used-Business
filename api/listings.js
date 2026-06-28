const { getListings, saveListings, readBody, sendJSON, generateId } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const idMatch = req.url.match(/^\/api\/listings\/(.+)$/);
    let id = idMatch ? idMatch[1] : null;
    if (!id) {
        try {
            const u = new URL(req.url, 'http://localhost');
            id = u.searchParams.get('id');
        } catch (e) {}
    }
    const listings = await getListings();

    if (!id) {
        if (req.method === 'GET') {
            sendJSON(res, 200, { success: true, listings: listings });
            return;
        }
        if (req.method === 'POST') {
            const body = await readBody(req);
            if (!body || !body.title || !body.type) {
                sendJSON(res, 400, { success: false, error: 'Title and type are required.' });
                return;
            }
            const newListing = {
                id: generateId(), title: body.title || 'Untitled', description: body.description || '',
                tags: body.tags || 'Available', type: body.type || 'Dealership', price: Number(body.price) || 0,
                postal: body.postal || '', thumbnail: body.thumbnail || '',
                createdAt: Date.now(), updatedAt: Date.now()
            };
            listings.push(newListing);
            await saveListings(listings);
            sendJSON(res, 201, { success: true, listing: newListing });
            return;
        }
    } else {
        const index = listings.findIndex(function(l) { return l.id === id; });
        if (index === -1) {
            sendJSON(res, 404, { success: false, error: 'Listing not found.' });
            return;
        }
        if (req.method === 'GET') {
            sendJSON(res, 200, { success: true, listing: listings[index] });
            return;
        }
        if (req.method === 'PUT') {
            const body = await readBody(req);
            if (!body) { sendJSON(res, 400, { success: false, error: 'Invalid data.' }); return; }
            const l = listings[index];
            l.title = body.title || l.title; l.description = body.description || l.description;
            l.tags = body.tags || l.tags; l.type = body.type || l.type;
            l.price = Number(body.price) || l.price; l.postal = body.postal !== undefined ? body.postal : l.postal;
            l.thumbnail = body.thumbnail || l.thumbnail; l.updatedAt = Date.now();
            await saveListings(listings);
            sendJSON(res, 200, { success: true, listing: l });
            return;
        }
        if (req.method === 'DELETE') {
            listings.splice(index, 1);
            await saveListings(listings);
            sendJSON(res, 200, { success: true });
            return;
        }
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
