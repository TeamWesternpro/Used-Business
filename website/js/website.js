let websiteListings = [];
let websiteFilter = 'all';
let websiteSearch = '';

async function loadListings() {
    websiteListings = await FetchListings();
    renderCards();
}

async function loadConfig() {
    const config = await FetchConfig();
    updateDropdowns(config);
}

function refreshListings() {
    ShowNotification('info', 'Refreshing listings...');
    loadListings();
}

function renderCards() {
    RenderCards('cards-grid', 'empty-state', websiteListings, false, websiteFilter, websiteSearch);
}

function filterListings(filter, btn) {
    websiteFilter = filter;
    const btns = document.querySelectorAll('.filter-bar .filter-btn');
    btns.forEach(function(b) { b.classList.remove('active'); });
    btn.classList.add('active');
    renderCards();
}

function searchListings(value) {
    websiteSearch = value;
    renderCards();
}

loadListings();
loadConfig();

setInterval(function() {
    loadListings();
}, 10000);
