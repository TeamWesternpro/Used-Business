const fs = require('fs');
const path = require('path');

const DATA_DIR = '/tmp/usedbusiness';
const LISTINGS_FILE = path.join(DATA_DIR, 'listings.json');
const CONFIG_FILE = path.join(DATA_DIR, 'config.json');

function ensureDir() {
    try { fs.mkdirSync(DATA_DIR, { recursive: true }); } catch (e) {}
}

function readJSON(file, fallback) {
    try {
        const data = fs.readFileSync(file, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return fallback;
    }
}

function saveJSON(file, data) {
    ensureDir();
    fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function getListings() {
    return readJSON(LISTINGS_FILE, []);
}

function saveListings(listings) {
    saveJSON(LISTINGS_FILE, listings);
}

function getConfig() {
    const data = readJSON(CONFIG_FILE, null);
    if (data) return data;
    return {
        businessTypes: ['Dealership', 'Mechanic', 'Shops', 'Houses'],
        tagOptions: ['Available', 'Not Available'],
        listingsWebhook: '',
        bookingsWebhook: ''
    };
}

function saveConfig(config) {
    saveJSON(CONFIG_FILE, config);
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

function sendJSON(res, status, data) {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
}

module.exports = { getListings, saveListings, getConfig, saveConfig, generateId, readBody, sendJSON };
