// Helper function to trigger hidden file inputs
window.triggerFileInput = function(elementId) {
    try {
        // Try multiple selectors to find the input
        let input = null;
        
        // Method 1: Direct ID
        const container = document.getElementById(elementId);
        if (container) {
            input = container.querySelector('input[type="file"]');
        }
        
        // Method 2: Find by ID with Blazor's generated structure
        if (!input) {
            input = document.querySelector(`#${elementId} input`);
        }
        
        // Method 3: Find any file input near the element
        if (!input) {
            const allInputs = document.querySelectorAll('input[type="file"]');
            for (let i = 0; i < allInputs.length; i++) {
                const parent = allInputs[i].closest('[id]');
                if (parent && parent.id === elementId) {
                    input = allInputs[i];
                    break;
                }
            }
        }
        
        if (input) {
            input.click();
            return true;
        } else {
            console.error(`File input not found for element: ${elementId}`);
            console.log('Available file inputs:', document.querySelectorAll('input[type="file"]'));
            return false;
        }
    } catch (error) {
        console.error('Error triggering file input:', error);
        return false;
    }
};
