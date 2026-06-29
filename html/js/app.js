let allListings = [];
let currentFilter = 'all';
let currentSearch = '';
let tabletIsAdmin = false;
let isAuthenticated = false;

const ADMIN_USER = '';
const ADMIN_PASS = '';

function callNui(name, data) {
    return new Promise((resolve) => {
        if (typeof GetParentResourceName !== 'function') {
            resolve({});
            return;
        }
        try {
            fetch('https://' + GetParentResourceName() + '/' + name, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data || {})
            }).then(r => r.json()).then(resolve).catch(() => resolve({}));
        } catch (e) { resolve({}); }
    });
}

function FetchListings() {
    return callNui('requestSync').then(() => window._lastListings || []);
}

function FetchConfig() {
    return callNui('requestSync').then(() => window._lastConfig || {});
}

function SaveListingAPI(data) {
    const method = data.id ? 'editListing' : 'addListing';
    return callNui(method, data);
}

function DeleteListingAPI(id) {
    return callNui('deleteListing', { id: id });
}

function GetTypeIcon(type) {
    switch (type) {
        case 'Dealership': return '&#128663;';
        case 'Mechanic': return '&#128295;';
        case 'Shops': return '&#128722;';
        case 'Houses': return '&#127968;';
        default: return '&#128188;';
    }
}

function FormatPrice(price) {
    return '$' + Number(price).toLocaleString();
}

function BuildFilterButtons(containerId, types, callback) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const slugify = function(s) {
        return s.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    };

    let html = '<button class="filter-btn active" data-filter="all" onclick="' + callback + '(\'all\', this)">All</button>';
    types.forEach(function(t) {
        const cls = 'filter-type-' + slugify(t);
        html += '<button class="filter-btn ' + cls + '" data-filter="' + t + '" onclick="' + callback + '(\'' + t + '\', this)">' + GetTypeIcon(t) + ' ' + t + '</button>';
    });
    container.innerHTML = html;
}

function CreateCardHTML(listing, showActions) {
    const tagClass = listing.tags === 'Available' ? 'available' : 'not-available';
    const tagText = listing.tags || 'Available';
    const typeIcon = GetTypeIcon(listing.type);
    const price = FormatPrice(listing.price || 0);
    let thumbnail;
    if (listing.thumbnail && listing.thumbnail.trim() !== '') {
        thumbnail = '<img class="card-thumbnail" src="' + listing.thumbnail.trim() + '" alt="' + (listing.title || '') + '" onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'flex\'">' +
            '<div class="card-thumbnail-placeholder" style="display:none">' + typeIcon + '</div>';
    } else {
        thumbnail = '<div class="card-thumbnail-placeholder">' + typeIcon + '</div>';
    }

    let actionsHTML = '';
    actionsHTML = '<div class="card-actions">' +
        '<button class="btn btn-book" onclick="openBookingModal(\'' + listing.id + '\', \'' + (listing.title || '').replace(/'/g, "\\'") + '\')">&#128197; Book</button>' +
        '</div>';

    if (showActions) {
        actionsHTML += '<div class="card-actions">' +
            '<button class="btn btn-primary" onclick="editListing(\'' + listing.id + '\')">&#9998; Edit</button>' +
            '<button class="btn btn-danger" onclick="deleteListingConfirm(\'' + listing.id + '\')">&#128465; Delete</button>' +
            '</div>';
    }

    let postalHTML = '';
    if (listing.postal && listing.postal.trim() !== '') {
        postalHTML = '<div class="card-postal">&#128205; ' + listing.postal + '</div>';
    }

    return '<div class="card" data-type="' + listing.type + '" data-id="' + listing.id + '">' +
        thumbnail +
        '<div class="card-body">' +
        '<div class="card-header">' +
        '<div class="card-title">' + (listing.title || 'Untitled') + '</div>' +
        '<span class="card-tag ' + tagClass + '">' + tagText + '</span>' +
        '</div>' +
        postalHTML +
        '<div class="card-description">' + (listing.description || 'No description available.') + '</div>' +
        '<div class="card-footer">' +
        '<div class="card-type">' +
        '<span class="card-type-icon">' + typeIcon + '</span>' +
        '<span>' + (listing.type || 'Unknown') + '</span>' +
        '</div>' +
        '<div class="card-price">' + price + '</div>' +
        '</div>' +
        actionsHTML +
        '</div>' +
        '</div>';
}

function FilteredListings(listings) {
    let filtered = listings;
    if (currentFilter !== 'all') {
        filtered = filtered.filter(function(l) { return l.type === currentFilter; });
    }
    if (currentSearch) {
        const search = currentSearch.toLowerCase();
        filtered = filtered.filter(function(l) {
            return (l.title && l.title.toLowerCase().indexOf(search) !== -1) ||
                   (l.description && l.description.toLowerCase().indexOf(search) !== -1) ||
                   (l.type && l.type.toLowerCase().indexOf(search) !== -1);
        });
    }
    return filtered;
}

function RenderCards(containerId, emptyId, listings, showActions) {
    const container = document.getElementById(containerId);
    const emptyState = document.getElementById(emptyId);
    if (!container) return;

    const filtered = FilteredListings(listings);

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
        html += CreateCardHTML(filtered[i], showActions);
    }
    container.innerHTML = html;
}

let notifTimeout = null;

function ShowNotification(type, message) {
    const el = document.getElementById('notification');
    if (!el) return;
    if (notifTimeout) clearTimeout(notifTimeout);
    el.className = 'notification ' + type;
    el.textContent = message;
    el.classList.add('show');
    notifTimeout = setTimeout(function() {
        el.classList.remove('show');
        notifTimeout = null;
    }, 3000);
}

function ShowModal(title, listing) {
    const modal = document.getElementById('add-edit-modal');
    const modalTitle = document.getElementById('modal-title');
    const editId = document.getElementById('edit-id');
    const titleInput = document.getElementById('listing-title');
    const descInput = document.getElementById('listing-description');
    const tagsInput = document.getElementById('listing-tags');
    const typeInput = document.getElementById('listing-type');
    const priceInput = document.getElementById('listing-price');
    const postalInput = document.getElementById('listing-postal');
    const thumbInput = document.getElementById('listing-thumbnail');
    const preview = document.getElementById('thumbnail-preview');
    const previewImg = document.getElementById('preview-img');

    modalTitle.textContent = title;
    thumbInput.value = '';
    delete thumbInput.dataset.existing;

    if (listing && listing.thumbnail) {
        thumbInput.value = listing.thumbnail;
        preview.style.display = 'flex';
        previewImg.src = listing.thumbnail;
        thumbInput.dataset.existing = listing.thumbnail;
    } else {
        preview.style.display = 'none';
        previewImg.src = '';
    }

    if (listing) {
        editId.value = listing.id;
        titleInput.value = listing.title || '';
        descInput.value = listing.description || '';
        tagsInput.value = listing.tags || 'Available';
        typeInput.value = listing.type || 'Dealership';
        priceInput.value = listing.price || '';
        postalInput.value = listing.postal || '';
    } else {
        editId.value = '';
        titleInput.value = '';
        descInput.value = '';
        tagsInput.value = 'Available';
        typeInput.value = 'Dealership';
        priceInput.value = '';
        postalInput.value = '';
        preview.style.display = 'none';
        previewImg.src = '';
        delete thumbInput.dataset.existing;
    }

    modal.classList.add('active');
}

function CloseModal() {
    const modal = document.getElementById('add-edit-modal');
    modal.classList.remove('active');
}

function GetFormData() {
    const thumbInput = document.getElementById('listing-thumbnail');
    let thumbnail = thumbInput.value.trim();
    if (!thumbnail && thumbInput.dataset.existing) {
        thumbnail = thumbInput.dataset.existing;
    }
    return {
        id: document.getElementById('edit-id').value,
        title: document.getElementById('listing-title').value.trim(),
        description: document.getElementById('listing-description').value.trim(),
        tags: document.getElementById('listing-tags').value,
        type: document.getElementById('listing-type').value,
        price: parseInt(document.getElementById('listing-price').value) || 0,
        postal: document.getElementById('listing-postal').value.trim(),
        thumbnail: thumbnail
    };
}

function ValidateForm(data) {
    if (!data.title) {
        ShowNotification('error', 'Please enter a title.');
        return false;
    }
    if (!data.type) {
        ShowNotification('error', 'Please select a type.');
        return false;
    }
    return true;
}

function closeAll() {
    document.getElementById('tablet-view').style.display = 'none';
    document.getElementById('login-view').style.display = 'none';
    document.getElementById('dashboard-view').style.display = 'none';
    document.getElementById('bookings-modal').classList.remove('active');
    callNui('closeTablet');
}

function showTablet() {
    document.getElementById('tablet-view').style.display = 'block';
    document.getElementById('login-view').style.display = 'none';
    document.getElementById('dashboard-view').style.display = 'none';
}

function showLogin() {
    document.getElementById('tablet-view').style.display = 'none';
    document.getElementById('login-view').style.display = 'flex';
    document.getElementById('dashboard-view').style.display = 'none';
}

function showDashboard() {
    document.getElementById('tablet-view').style.display = 'none';
    document.getElementById('dashboard-view').style.display = 'block';
    loadDashListings();
}

function handleLogin() {
    ShowNotification('info', 'Checking permissions...');
    callNui('openDashboard');
}

function handleLogout() {
    isAuthenticated = false;
    document.getElementById('dashboard-view').style.display = 'none';
    showTablet();
}

function closeModal() {
    CloseModal();
}

function previewThumbnailUrl(url) {
    const preview = document.getElementById('thumbnail-preview');
    const img = document.getElementById('preview-img');
    if (url && url.trim()) {
        preview.style.display = 'flex';
        img.src = url;
    } else {
        preview.style.display = 'none';
        img.src = '';
    }
}

function removeThumbnail() {
    const thumbInput = document.getElementById('listing-thumbnail');
    thumbInput.value = '';
    thumbInput.dataset.existing = '';
    document.getElementById('thumbnail-preview').style.display = 'none';
    document.getElementById('preview-img').src = '';
}

function updateDropdowns(config) {
    if (!config) return;

    if (config.businessTypes) {
        const typeSelect = document.getElementById('listing-type');
        if (typeSelect) {
            const current = typeSelect.value;
            typeSelect.innerHTML = '';
            config.businessTypes.forEach(function(t) {
                const opt = document.createElement('option');
                opt.value = t;
                opt.textContent = t;
                typeSelect.appendChild(opt);
            });
            if (current && config.businessTypes.indexOf(current) !== -1) {
                typeSelect.value = current;
            }
        }

        BuildFilterButtons('tablet-filter-btns', config.businessTypes, 'filterListings');
        BuildFilterButtons('dash-filter-btns', config.businessTypes, 'filterDashListings');
    }

    if (config.tagOptions) {
        const tagsSelect = document.getElementById('listing-tags');
        if (tagsSelect) {
            const current = tagsSelect.value;
            tagsSelect.innerHTML = '';
            config.tagOptions.forEach(function(t) {
                const opt = document.createElement('option');
                opt.value = t;
                opt.textContent = t;
                tagsSelect.appendChild(opt);
            });
            if (current && config.tagOptions.indexOf(current) !== -1) {
                tagsSelect.value = current;
            }
        }
    }
}

function openBookingModal(id, title) {
    document.getElementById('booking-listing-id').value = id;
    document.getElementById('booking-listing-title').value = title;
    document.getElementById('booking-business-name').textContent = title;
    document.getElementById('booking-username').value = '';
    document.getElementById('booking-phone').value = '';
    document.getElementById('booking-date').value = '';
    document.getElementById('booking-time').value = '';
    document.getElementById('booking-notes').value = '';
    document.getElementById('booking-modal').classList.add('active');
}

function closeBookingModal() {
    document.getElementById('booking-modal').classList.remove('active');
}

function submitBooking() {
    const username = document.getElementById('booking-username').value.trim();
    const phone = document.getElementById('booking-phone').value.trim();
    const date = document.getElementById('booking-date').value;
    const time = document.getElementById('booking-time').value;
    const notes = document.getElementById('booking-notes').value.trim();
    const listingId = document.getElementById('booking-listing-id').value;
    const listingTitle = document.getElementById('booking-listing-title').value;

    if (!username) {
        ShowNotification('error', 'Please enter your name.');
        return;
    }
    if (!date || !time) {
        ShowNotification('error', 'Please select a date and time.');
        return;
    }

    const bookingData = {
        listingId: listingId,
        business: listingTitle,
        username: username,
        phone: phone,
        date: date,
        time: time,
        notes: notes
    };

    callNui('submitBooking', bookingData);

    closeBookingModal();
    ShowNotification('success', 'Booking request sent!');
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && document.getElementById('login-view').style.display !== 'none') {
        handleLogin();
    }
});
