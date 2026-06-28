const { getListings, saveListings, readBody, sendJSON, generateId } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    if (req.method === 'GET') {
        const urlParts = req.url.split('?');
        const pathname = urlParts[0];
        const id = pathname.replace('/api/listings/', '').replace('/api/listings', '') || null;

        const listings = await getListings();
        if (id) {
            const listing = listings.find(function(l) { return l.id === id; });
            sendJSON(res, 200, { success: true, listing: listing || null });
        } else {
            sendJSON(res, 200, { success: true, listings: listings });
        }
        return;
    }

    if (req.method === 'POST') {
        const body = await readBody(req);
        if (!body || !body.title || !body.type) {
            sendJSON(res, 400, { success: false, error: 'Title and type are required.' });
            return;
        }
        const newListing = {
            id: generateId(),
            title: body.title || 'Untitled',
            description: body.description || '',
            tags: body.tags || 'Available',
            type: body.type || 'Dealership',
            price: Number(body.price) || 0,
            postal: body.postal || '',
            thumbnail: body.thumbnail || '',
            createdAt: Date.now(),
            updatedAt: Date.now()
        };
        const listings = await getListings();
        listings.push(newListing);
        await saveListings(listings);
        sendJSON(res, 201, { success: true, listing: newListing });
        return;
    }

    if (req.method === 'PUT') {
        const body = await readBody(req);
        if (!body || !body.id) {
            sendJSON(res, 400, { success: false, error: 'Listing ID is required.' });
            return;
        }
        const listings = await getListings();
        for (let i = 0; i < listings.length; i++) {
            if (listings[i].id === body.id) {
                listings[i].title = body.title || listings[i].title;
                listings[i].description = body.description || listings[i].description;
                listings[i].tags = body.tags || listings[i].tags;
                listings[i].type = body.type || listings[i].type;
                listings[i].price = Number(body.price) || listings[i].price;
                listings[i].postal = body.postal !== undefined ? body.postal : listings[i].postal;
                listings[i].thumbnail = body.thumbnail || listings[i].thumbnail;
                listings[i].updatedAt = Date.now();
                await saveListings(listings);
                sendJSON(res, 200, { success: true, listing: listings[i] });
                return;
            }
        }
        sendJSON(res, 404, { success: false, error: 'Listing not found.' });
        return;
    }

    if (req.method === 'DELETE') {
        const body = await readBody(req);
        if (!body || !body.id) {
            sendJSON(res, 400, { success: false, error: 'Listing ID is required.' });
            return;
        }
        const listings = await getListings();
        for (let i = 0; i < listings.length; i++) {
            if (listings[i].id === body.id) {
                listings.splice(i, 1);
                await saveListings(listings);
                sendJSON(res, 200, { success: true });
                return;
            }
        }
        sendJSON(res, 404, { success: false, error: 'Listing not found.' });
        return;
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
