let tabletListings = [];
let tabletFilter = 'all';
let tabletSearch = '';

function updateClock() {
    const now = new Date();
    const time = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    const el1 = document.getElementById('tablet-time');
    const el2 = document.getElementById('dashboard-time');
    if (el1) el1.textContent = time;
    if (el2) el2.textContent = time;
}

setInterval(updateClock, 1000);
updateClock();

function refreshListings() {
    ShowNotification('info', 'Refreshing listings...');
    callNui('requestSync');
}

function filterListings(filter, btn) {
    tabletFilter = filter;
    currentFilter = filter;

    const btns = document.querySelectorAll('#tablet-view .filter-btn');
    btns.forEach(function(b) { b.classList.remove('active'); });
    btn.classList.add('active');

    RenderTabletCards();
}

function searchListings(value) {
    tabletSearch = value;
    currentSearch = value;
    RenderTabletCards();
}

function RenderTabletCards() {
    currentFilter = tabletFilter;
    currentSearch = tabletSearch;
    var availableOnly = tabletListings.filter(function(l) { return l.tags === 'Available'; });
    RenderCards('cards-grid', 'empty-state', availableOnly, false, tabletFilter, tabletSearch);
}

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'openTablet':
            showTablet();
            break;

        case 'closeTablet':
            document.getElementById('tablet-view').style.display = 'none';
            document.getElementById('login-view').style.display = 'none';
            document.getElementById('dashboard-view').style.display = 'none';
            break;

        case 'updateListings':
            console.log('[UsedDealership NUI] updateListings received:', data.listings);
            tabletListings = data.listings || [];
            window._lastListings = tabletListings;
            if (typeof dashListings !== 'undefined') dashListings = tabletListings;
            RenderTabletCards();
            if (isAuthenticated) {
                RenderDashCards();
                updateStats();
            }
            break;

        case 'notify':
            ShowNotification(data.notifyType || 'info', data.message || '');
            break;

        case 'setAdmin':
            tabletIsAdmin = data.isAdmin || false;
            updateDashboardButton();
            break;

        case 'openDashboard':
            isAuthenticated = true;
            showDashboard();
            ShowNotification('success', 'Logged in successfully!');
            break;

        case 'updateConfig':
            window._lastConfig = data.config || {};
            updateDropdowns(window._lastConfig);
            break;
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeAll();
    }
});
