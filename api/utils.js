const fs = require('fs');
const path = require('path');

const DATA_DIR = '/tmp/usedbusiness';
const LISTINGS_FILE = path.join(DATA_DIR, 'listings.json');
const CONFIG_FILE = path.join(DATA_DIR, 'config.json');

function ensureDir() {
    try { fs.mkdirSync(DATA_DIR, { recursive: true }); } catch (e) {}
}

function readJSON(filePath, fallback) {
    try {
        ensureDir();
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return fallback;
    }
}

function writeJSON(filePath, data) {
    try {
        ensureDir();
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    } catch (e) {}
}

async function getListings() {
    let data = readJSON(LISTINGS_FILE, null);
    if (data === null) {
        const repoPath = path.join(__dirname, '..', 'data', 'listings.json');
        data = readJSON(repoPath, []);
    }
    return data;
}

async function saveListings(listings) {
    writeJSON(LISTINGS_FILE, listings);
}

async function getConfig() {
    const data = readJSON(CONFIG_FILE, null);
    if (data) return data;
    return { businessTypes: ['Dealership', 'Mechanic', 'Shops', 'Houses'], tagOptions: ['Available', 'Not Available'] };
}

async function saveConfig(config) {
    writeJSON(CONFIG_FILE, config);
}

function generateId() {
    return Date.now().toString() + Math.floor(Math.random() * 9000 + 1000).toString();
}

function readBody(req) {
    return new Promise((resolve) => {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try { resolve(JSON.parse(body)); }
            catch { resolve(null); }
        });
    });
}

function sendJSON(res, status, data) {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
}

module.exports = { getListings, saveListings, getConfig, saveConfig, generateId, readBody, sendJSON };
