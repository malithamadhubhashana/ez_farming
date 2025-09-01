// EZ Farming UI JavaScript
let currentMenuType = null;
let currentMenuData = null;
let currentShopTab = 'buy';
let quantityCallback = null;

// Initialize the UI
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // ESC key to close menus
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });

    // Quantity input validation
    const quantityInput = document.getElementById('quantity-input');
    if (quantityInput) {
        quantityInput.addEventListener('input', function() {
            let value = parseInt(this.value);
            if (isNaN(value) || value < 1) {
                this.value = 1;
            } else if (value > 100) {
                this.value = 100;
            }
        });
    }
}

// Message handler from FiveM
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openMenu':
            openFarmingMenu(data.data);
            break;
        case 'openShop':
            openShopMenu(data.data);
            break;
        case 'openAdmin':
            openAdminMenu(data.data);
            break;
        case 'showInfo':
            showPlantInfo(data.data);
            break;
        case 'notification':
            showNotification(data.data);
            break;
        case 'hideUI':
            hideUI();
            break;
        default:
            console.log('Unknown message type:', data.type);
    }
});

// Open farming menu
function openFarmingMenu(menuData) {
    currentMenuType = 'farming';
    currentMenuData = menuData;
    
    document.getElementById('main-container').style.display = 'flex';
    document.getElementById('farming-menu').style.display = 'block';
    document.getElementById('shop-menu').style.display = 'none';
    document.getElementById('admin-menu').style.display = 'none';
    
    document.getElementById('menu-title').innerHTML = 
        `<i class="fas fa-seedling"></i> ${menuData.title}`;
    
    populateCropOptions(menuData.elements);
    populateZoneInfo(menuData.zoneIndex);
}

// Open shop menu
function openShopMenu(shopData) {
    currentMenuType = 'shop';
    currentMenuData = shopData;
    
    document.getElementById('main-container').style.display = 'flex';
    document.getElementById('farming-menu').style.display = 'none';
    document.getElementById('shop-menu').style.display = 'block';
    document.getElementById('admin-menu').style.display = 'none';
    
    document.getElementById('shop-title').innerHTML = 
        `<i class="fas fa-store"></i> ${shopData.title}`;
    
    switchTab(shopData.sellOnly ? 'sell' : 'buy');
}

// Open admin menu
function openAdminMenu(adminData) {
    currentMenuType = 'admin';
    currentMenuData = adminData;
    
    document.getElementById('main-container').style.display = 'flex';
    document.getElementById('farming-menu').style.display = 'none';
    document.getElementById('shop-menu').style.display = 'none';
    document.getElementById('admin-menu').style.display = 'block';
    
    document.getElementById('admin-title').innerHTML = 
        `<i class="fas fa-cog"></i> ${adminData.title}`;
}

// Populate crop options
function populateCropOptions(elements) {
    const container = document.getElementById('crop-options');
    container.innerHTML = '';
    
    elements.forEach(element => {
        const cropDiv = document.createElement('div');
        cropDiv.className = 'crop-option';
        
        if (element.disabled) {
            cropDiv.className += ' disabled';
        }
        
        const iconMap = {
            'wheat': 'fas fa-wheat',
            'corn': 'fas fa-corn',
            'tomato': 'fas fa-apple-alt',
            'potato': 'fas fa-egg',
            'carrot': 'fas fa-carrot',
            'lettuce': 'fas fa-leaf',
            'strawberry': 'fas fa-berry'
        };
        
        const cropType = element.cropType || '';
        const icon = iconMap[cropType] || 'fas fa-seedling';
        
        cropDiv.innerHTML = `
            <div class="crop-icon">
                <i class="${icon}"></i>
            </div>
            <div class="crop-name">${element.label}</div>
            <div class="crop-info">${element.info || 'Click to plant'}</div>
        `;
        
        if (!element.disabled) {
            cropDiv.onclick = () => handleCropSelection(element);
        }
        
        container.appendChild(cropDiv);
    });
}

// Populate zone information
function populateZoneInfo(zoneIndex) {
    const container = document.getElementById('zone-info');
    
    // This would be populated with actual zone data
    container.innerHTML = `
        <p><strong>Zone:</strong> Farming Zone ${zoneIndex}</p>
        <p><strong>Available Plots:</strong> 15/20</p>
        <p><strong>Current Season:</strong> Spring</p>
        <p><strong>Weather:</strong> Sunny</p>
        <p><strong>Growth Bonus:</strong> +5%</p>
    `;
}

// Handle crop selection
function handleCropSelection(element) {
    if (element.value === 'zone_info') {
        // Show detailed zone info
        return;
    }
    
    // Send action to client
    fetch(`https://${GetParentResourceName()}/menuAction`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            action: element.value,
            value: element.cropType
        })
    });
}

// Switch shop tabs
function switchTab(tab) {
    currentShopTab = tab;
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    document.querySelector(`[onclick="switchTab('${tab}')"]`).classList.add('active');
    
    // Populate shop items
    populateShopItems(tab);
}

// Populate shop items
function populateShopItems(tab) {
    const container = document.getElementById('shop-items');
    container.innerHTML = '';
    
    if (!currentMenuData || !currentMenuData.elements) return;
    
    currentMenuData.elements.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'shop-item';
        
        const stockInfo = item.stock ? `<div class="item-stock">Stock: ${item.stock}</div>` : '';
        const actionBtn = tab === 'buy' ? 
            `<button class="btn primary" onclick="handleShopAction('buy', '${item.value}')">
                <i class="fas fa-shopping-cart"></i> Buy
            </button>` :
            `<button class="btn secondary" onclick="handleShopAction('sell', '${item.value}')">
                <i class="fas fa-dollar-sign"></i> Sell
            </button>`;
        
        itemDiv.innerHTML = `
            <div class="item-header">
                <div class="item-name">${item.label.split(' - ')[0]}</div>
                <div class="item-price">$${item.price}</div>
            </div>
            ${stockInfo}
            <div class="item-actions">
                ${actionBtn}
            </div>
        `;
        
        container.appendChild(itemDiv);
    });
}

// Handle shop actions
function handleShopAction(action, item) {
    showQuantityModal(action, item);
}

// Show quantity selection modal
function showQuantityModal(action, item) {
    document.getElementById('quantity-modal').style.display = 'flex';
    document.getElementById('quantity-input').value = 1;
    
    quantityCallback = (quantity) => {
        fetch(`https://${GetParentResourceName()}/shopAction`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: action,
                item: item,
                amount: quantity,
                shopIndex: currentMenuData.shopIndex
            })
        });
    };
}

// Adjust quantity
function adjustQuantity(amount) {
    const input = document.getElementById('quantity-input');
    let currentValue = parseInt(input.value) || 1;
    let newValue = currentValue + amount;
    
    if (newValue < 1) newValue = 1;
    if (newValue > 100) newValue = 100;
    
    input.value = newValue;
}

// Confirm quantity
function confirmQuantity() {
    const quantity = parseInt(document.getElementById('quantity-input').value) || 1;
    
    if (quantityCallback) {
        quantityCallback(quantity);
        quantityCallback = null;
    }
    
    closeQuantityModal();
}

// Close quantity modal
function closeQuantityModal() {
    document.getElementById('quantity-modal').style.display = 'none';
    quantityCallback = null;
}

// Admin functions
function adminAction(action) {
    let value = null;
    
    switch(action) {
        case 'set_season':
            value = document.getElementById('season-select').value;
            break;
        case 'set_weather':
            value = document.getElementById('weather-select').value;
            break;
        case 'player_stats':
            value = document.getElementById('player-id').value;
            if (!value || isNaN(parseInt(value))) {
                showNotification({
                    message: 'Please enter a valid player ID',
                    type: 'error',
                    duration: 3000
                });
                return;
            }
            break;
    }
    
    fetch(`https://${GetParentResourceName()}/adminAction`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            action: action,
            value: value
        })
    });
}

// Show plant information
function showPlantInfo(data) {
    const modal = document.getElementById('plant-info');
    const content = document.getElementById('plant-details');
    
    content.innerHTML = data.html;
    modal.style.display = 'flex';
    
    if (data.duration) {
        setTimeout(() => {
            closePlantInfo();
        }, data.duration);
    }
}

// Close plant info
function closePlantInfo() {
    document.getElementById('plant-info').style.display = 'none';
}

// Show notification
function showNotification(data) {
    const container = document.getElementById('notifications');
    
    const notification = document.createElement('div');
    notification.className = `notification ${data.type || 'info'}`;
    
    const iconMap = {
        'success': 'fas fa-check-circle',
        'error': 'fas fa-exclamation-circle',
        'warning': 'fas fa-exclamation-triangle',
        'info': 'fas fa-info-circle'
    };
    
    const icon = iconMap[data.type] || iconMap.info;
    
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="${icon}"></i>
        </div>
        <div class="notification-content">
            <h4>${data.title || 'Notification'}</h4>
            <p>${data.message}</p>
        </div>
    `;
    
    container.appendChild(notification);
    
    // Auto remove after duration
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, data.duration || 5000);
}

// Close current menu
function closeMenu() {
    document.getElementById('main-container').style.display = 'none';
    
    // Reset states
    currentMenuType = null;
    currentMenuData = null;
    
    // Close all modals
    document.getElementById('plant-info').style.display = 'none';
    document.getElementById('quantity-modal').style.display = 'none';
    
    // Notify FiveM that menu is closed
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Hide entire UI
function hideUI() {
    document.getElementById('main-container').style.display = 'none';
}

// Show loading overlay
function showLoading() {
    document.getElementById('loading-overlay').style.display = 'flex';
}

// Hide loading overlay
function hideLoading() {
    document.getElementById('loading-overlay').style.display = 'none';
}

// Utility function to get resource name
function GetParentResourceName() {
    return window.location.hostname === '' ? 'ez_farming' : window.location.hostname;
}

// Development helpers
if (window.location.protocol === 'file:') {
    console.log('Development mode detected');
    
    // Mock data for testing
    setTimeout(() => {
        openFarmingMenu({
            title: 'Grapeseed Farm',
            zoneIndex: 1,
            elements: [
                {label: 'Plant Wheat', value: 'plant_wheat', cropType: 'wheat'},
                {label: 'Plant Corn', value: 'plant_corn', cropType: 'corn'},
                {label: 'Plant Tomato', value: 'plant_tomato', cropType: 'tomato', disabled: true},
                {label: 'Zone Info', value: 'zone_info'}
            ]
        });
    }, 1000);
}
