import { LightningElement, wire } from 'lwc';
// Import the Apex method reference
import searchProducts from '@salesforce/apex/SalesSimulatorController.searchProducts';

export default class ProductSearch extends LightningElement {
    searchTerm = '';
    
    // Wire Service: Automatically calls Apex when 'searchTerm' changes (reactive)
    @wire(searchProducts, { searchTerm: '$searchTerm' })
    products; 

    handleSearchChange(event) {
        // Simple Debouncing: Wait 300ms before searching to save API calls
        window.clearTimeout(this.delayTimeout);
        const term = event.target.value;
        
        this.delayTimeout = setTimeout(() => {
            this.searchTerm = term;
        }, 300);
    }

    handleAddClick(event) {
        // Extract data from the clicked button
        const dataset = event.target.dataset;
        
        // ARCHITECTURE PATTERN: Dispatch Custom Event
        // We do not modify the cart here. We tell the Parent to do it.
        // This keeps this component reusable and decoupled.
        const addEvent = new CustomEvent('addproduct', {
            detail: {
                id: dataset.id,
                name: dataset.name,
                price: parseFloat(dataset.price)
            }
        });

        this.dispatchEvent(addEvent);
    }
}