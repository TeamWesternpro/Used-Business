const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const DATA_DIR = path.join(__dirname, '..', 'data');
const LISTINGS_FILE = path.join(DATA_DIR, 'listings.json');
const CONFIG_FILE = path.join(DATA_DIR, 'config.json');
const WEBSITE_DIR = __dirname;

const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

function loadListings() {
    try {
        const data = fs.readFileSync(LISTINGS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return [];
    }
}

function saveListings(listings) {
    fs.writeFileSync(LISTINGS_FILE, JSON.stringify(listings, null, 2));
}

function loadConfig() {
    try {
        const data = fs.readFileSync(CONFIG_FILE, 'utf8');
        const parsed = JSON.parse(data);
        return {
            businessTypes: parsed.businessTypes || ['Dealership', 'Mechanic', 'Shops', 'Houses'],
            tagOptions: parsed.tagOptions || ['Available', 'Not Available']
        };
    } catch (e) {
        return { businessTypes: ['Dealership', 'Mechanic', 'Shops', 'Houses'], tagOptions: ['Available', 'Not Available'] };
    }
}

function saveConfig(config) {
    try { fs.mkdirSync(DATA_DIR, { recursive: true }); } catch (e) {}
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

function generateId() {
    return Date.now().toString() + Math.floor(Math.random() * 9000 + 1000).toString();
}

function readBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                resolve(JSON.parse(body));
            } catch (e) {
                resolve(null);
            }
        });
        req.on('error', reject);
    });
}

function sendJSON(res, statusCode, data) {
    res.writeHead(statusCode, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
}

function serveStatic(req, res) {
    let filePath = path.join(WEBSITE_DIR, req.url === '/' ? 'index.html' : req.url);
    filePath = path.normalize(filePath);

    if (!filePath.startsWith(WEBSITE_DIR)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404);
                res.end('Not Found');
            } else {
                res.writeHead(500);
                res.end('Server Error');
            }
            return;
        }
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
}

const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const url = new URL(req.url, `http://localhost:${PORT}`);

    if (url.pathname === '/api/config') {
        const config = loadConfig();
        sendJSON(res, 200, { success: true, config: config });
        return;
    }

    if (url.pathname === '/api/bookings' && req.method === 'POST') {
        const body = await readBody(req);
        if (!body || !body.username || !body.business) {
            sendJSON(res, 400, { success: false, error: 'Name and business are required.' });
            return;
        }

        sendJSON(res, 200, { success: true });
        return;
    }

    if (url.pathname === '/api/listings') {
        const listings = loadListings();

        if (req.method === 'GET') {
            sendJSON(res, 200, { success: true, listings: listings });
        } else if (req.method === 'POST') {
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
            listings.push(newListing);
            saveListings(listings);

            sendJSON(res, 201, { success: true, listing: newListing });
        }
        return;
    }

    const listingMatch = url.pathname.match(/^\/api\/listings\/(.+)$/);
    if (listingMatch) {
        const id = listingMatch[1];
        const listings = loadListings();
        const index = listings.findIndex(l => l.id === id);

        if (req.method === 'GET') {
            if (index === -1) {
                sendJSON(res, 404, { success: false, error: 'Listing not found.' });
                return;
            }
            sendJSON(res, 200, { success: true, listing: listings[index] });
        } else if (req.method === 'PUT') {
            if (index === -1) {
                sendJSON(res, 404, { success: false, error: 'Listing not found.' });
                return;
            }
            const body = await readBody(req);
            if (!body) {
                sendJSON(res, 400, { success: false, error: 'Invalid data.' });
                return;
            }
            listings[index].title = body.title || listings[index].title;
            listings[index].description = body.description || listings[index].description;
            listings[index].tags = body.tags || listings[index].tags;
            listings[index].type = body.type || listings[index].type;
            listings[index].price = Number(body.price) || listings[index].price;
            listings[index].postal = body.postal !== undefined ? body.postal : listings[index].postal;
            listings[index].thumbnail = body.thumbnail || listings[index].thumbnail;
            listings[index].updatedAt = Date.now();
            saveListings(listings);
            sendJSON(res, 200, { success: true, listing: listings[index] });
        } else if (req.method === 'DELETE') {
            if (index === -1) {
                sendJSON(res, 404, { success: false, error: 'Listing not found.' });
                return;
            }
            listings.splice(index, 1);
            saveListings(listings);
            sendJSON(res, 200, { success: true });
        }
        return;
    }

    serveStatic(req, res);
});

server.listen(PORT, () => {
    console.log(`[Used Dealership Website] Running at http://localhost:${PORT}`);
    console.log(`[Used Dealership Website] Admin Dashboard: http://localhost:${PORT}/admin.html`);
    console.log(`[Used Dealership Website] Data file: ${LISTINGS_FILE}`);
});
