let dashListings = [];
let dashFilter = 'all';
let dashSearch = '';

function loadDashListings() {
    dashListings = tabletListings;
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
    const btns = document.querySelectorAll('#dashboard-view .filter-btn');
    btns.forEach(function(b) { b.classList.remove('active'); });
    btn.classList.add('active');
    RenderDashCards();
}

function searchDashListings(value) {
    dashSearch = value;
    RenderDashCards();
}

function RenderDashCards() {
    currentFilter = dashFilter;
    currentSearch = dashSearch;
    const filtered = FilteredListings(dashListings);
    const container = document.getElementById('dashboard-cards');
    const emptyState = document.getElementById('dash-empty-state');

    if (filtered.length === 0) {
        container.innerHTML = '';
        if (emptyState) {
            container.appendChild(emptyState);
            emptyState.style.display = 'block';
        }
        return;
    }

    if (emptyState) emptyState.style.display = 'none';

    let html = '';
    for (let i = 0; i < filtered.length; i++) {
        html += CreateCardHTML(filtered[i], true);
    }
    container.innerHTML = html;
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
        if (result) {
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
        if (result) {
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
    if (result) {
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

function showBookings() {
    document.getElementById('bookings-modal').classList.add('active');
    loadBookings();
}

function closeBookingsModal() {
    document.getElementById('bookings-modal').classList.remove('active');
}

function loadBookings() {
    callNui('requestBookings');
}

function renderBookings(data) {
    const tbody = document.getElementById('bookings-tbody');
    const empty = document.getElementById('bookings-empty');
    if (!data || data.length === 0) {
        tbody.innerHTML = '';
        document.getElementById('bookings-table').style.display = 'none';
        empty.style.display = 'block';
        return;
    }
    empty.style.display = 'none';
    document.getElementById('bookings-table').style.display = '';
    let html = '';
    for (let i = 0; i < data.length; i++) {
        const b = data[i];
        html += '<tr>' +
            '<td>' + (b.business || '-') + '</td>' +
            '<td>' + (b.username || '-') + '</td>' +
            '<td>' + (b.phone || '-') + '</td>' +
            '<td>' + (b.date || '-') + '</td>' +
            '<td>' + (b.time || '-') + '</td>' +
            '<td>' + (b.notes || '-') + '</td>' +
            '</tr>';
    }
    tbody.innerHTML = html;
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && document.getElementById('login-overlay').style.display !== 'none') {
        handleLogin();
    }
});
