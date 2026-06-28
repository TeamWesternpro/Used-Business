let dashListings = [];
let dashFilter = 'all';
let dashSearch = '';
let isAuthenticated = false;

const ADMIN_USER = 'admin';
const ADMIN_PASS = 'admin123';

async function handleLogin() {
    const user = document.getElementById('login-user').value.trim();
    const pass = document.getElementById('login-pass').value.trim();

    if (user === ADMIN_USER && pass === ADMIN_PASS) {
        isAuthenticated = true;
        document.getElementById('login-overlay').style.display = 'none';
        document.getElementById('dashboard-app').style.display = 'block';
        const config = await FetchConfig();
        updateDropdowns(config);
        loadDashListings();
        loadWebhooks();
        ShowNotification('success', 'Logged in successfully!');
    } else {
        ShowNotification('error', 'Invalid credentials.');
    }
}

function handleLogout() {
    isAuthenticated = false;
    document.getElementById('login-overlay').style.display = 'flex';
    document.getElementById('dashboard-app').style.display = 'none';
    document.getElementById('login-user').value = '';
    document.getElementById('login-pass').value = '';
}

async function loadDashListings() {
    dashListings = await FetchListings();
    RenderDashCards();
    updateStats();
}

function updateStats() {
    const total = dashListings.length;
    const available = dashListings.filter(function(l) { return l.tags === 'Available'; }).length;
    const unavailable = total - available;

    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-available').textContent = available;
    document.getElementById('stat-unavailable').textContent = unavailable;
}

function filterDashListings(filter, btn) {
    dashFilter = filter;
    dashSearch = document.getElementById('dash-search-input').value;
    const btns = document.querySelectorAll('#dashboard-app .filter-bar .filter-btn');
    btns.forEach(function(b) { b.classList.remove('active'); });
    btn.classList.add('active');
    RenderDashCards();
}

function searchDashListings(value) {
    dashSearch = value;
    RenderDashCards();
}

function RenderDashCards() {
    RenderCards('dashboard-cards', 'dash-empty-state', dashListings, true, dashFilter, dashSearch);
}

function showAddModal() {
    ShowModal('Add New Listing', null);
    document.getElementById('btn-delete').style.display = 'none';
}

function editListing(id) {
    const listing = dashListings.find(function(l) { return l.id === id; });
    if (listing) {
        ShowModal('Edit Listing', listing);
        document.getElementById('btn-delete').style.display = 'inline-flex';
    }
}

async function deleteListingConfirm(id) {
    if (confirm('Are you sure you want to delete this listing?')) {
        const result = await DeleteListingAPI(id);
        if (result.success) {
            ShowNotification('success', 'Listing deleted!');
            loadDashListings();
        } else {
            ShowNotification('error', 'Failed to delete listing.');
        }
    }
}

async function deleteListing() {
    const id = document.getElementById('edit-id').value;
    if (!id) return;
    if (confirm('Are you sure you want to delete this listing?')) {
        const result = await DeleteListingAPI(id);
        if (result.success) {
            ShowNotification('success', 'Listing deleted!');
            CloseModal();
            loadDashListings();
        } else {
            ShowNotification('error', 'Failed to delete listing.');
        }
    }
}

async function saveDashListing() {
    const data = GetFormData();
    if (!ValidateForm(data)) return;

    const result = await SaveListingAPI(data);
    if (result.success) {
        ShowNotification('success', data.id ? 'Listing updated!' : 'Listing added!');
        CloseModal();
        loadDashListings();
    } else {
        ShowNotification('error', 'Failed to save listing.');
    }
}

function closeModal() {
    CloseModal();
}

function showWebhooksModal() {
    document.getElementById('webhooks-modal').classList.add('active');
}

function closeWebhooksModal() {
    document.getElementById('webhooks-modal').classList.remove('active');
}

async function loadWebhooks() {
    try {
        const res = await fetch('/api/webhooks');
        const data = await res.json();
        if (data.success && data.webhooks) {
            document.getElementById('webhook-listings').value = data.webhooks.listings || '';
            document.getElementById('webhook-bookings').value = data.webhooks.bookings || '';
        }
    } catch (e) {
        console.error('Failed to load webhooks:', e);
    }
}

async function saveWebhooks() {
    const listings = document.getElementById('webhook-listings').value.trim();
    const bookings = document.getElementById('webhook-bookings').value.trim();

    try {
        const res = await fetch('/api/webhooks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ listings: listings, bookings: bookings })
        });
        const data = await res.json();
        if (data.success) {
            ShowNotification('success', 'Webhooks saved!');
            closeWebhooksModal();
        } else {
            ShowNotification('error', data.error || 'Failed to save webhooks.');
        }
    } catch (e) {
        ShowNotification('error', 'Failed to save webhooks.');
    }
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && document.getElementById('login-overlay').style.display !== 'none') {
        handleLogin();
    }
});
