// Sample file to test the Todo Manager extension

function calculateTotal(items) {
    // TODO: Add input validation for items array
    let total = 0;

    for (const item of items) {
        // todo: Handle negative prices
        total += item.price * item.quantity;
    }

    return total;
}

class ShoppingCart {
    constructor() {
        this.items = [];
        // TODO: Implement cart persistence
    }

    addItem(item) {
        // To-Do: Check for duplicate items and merge quantities
        this.items.push(item);
    }

    removeItem(itemId) {
        /* TODO: Add error handling for invalid itemId */
        this.items = this.items.filter(item => item.id !== itemId);
    }

    checkout() {
        // TODO: Integrate with payment system
        // TODO: Send confirmation email
        console.log('Checkout complete');
    }
}

// Export the classes
module.exports = { calculateTotal, ShoppingCart };
