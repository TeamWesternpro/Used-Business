const { getListings, getBookings, saveBookings, readBody, sendJSON } = require('./utils');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    if (req.method === 'GET') {
        const bookings = await getBookings();
        sendJSON(res, 200, { success: true, bookings: bookings });
        return;
    }

    if (req.method === 'POST') {
        const body = await readBody(req);
        if (!body || !body.username || !body.business) {
            sendJSON(res, 400, { success: false, error: 'Name and business are required.' });
            return;
        }

        const listings = await getListings();
        const listing = listings.find(function(l) { return l.id === body.listingId; }) || {};

        const booking = {
            id: Date.now().toString(),
            listingId: body.listingId || '',
            business: body.business || 'Unknown Business',
            type: (listing.type || 'N/A'),
            username: body.username || '',
            phone: body.phone || 'N/A',
            date: body.date || 'N/A',
            time: body.time || 'N/A',
            notes: body.notes || '',
            createdAt: new Date().toISOString()
        };

        const bookings = await getBookings();
        bookings.unshift(booking);
        await saveBookings(bookings);

        sendJSON(res, 200, { success: true, booking: booking });
        return;
    }

    sendJSON(res, 405, { success: false, error: 'Method not allowed' });
};
