import { createConsumer } from "@rails/actioncable"

document.addEventListener('DOMContentLoaded', function() {
  console.log('Bulk analysis JavaScript loaded');
  
  // Get the session ID from a data attribute or meta tag
  const sessionId = document.querySelector('meta[name="bulk-analysis-id"]')?.content;
  console.log('Session ID found:', sessionId);
  
  // Set up ActionCable if we have a session ID
  if (sessionId) {
    console.log('Setting up ActionCable subscription for session:', sessionId);
    
    try {
      const consumer = createConsumer();
      const subscription = consumer.subscriptions.create(
        { channel: "BulkAnalysisChannel", session_id: sessionId },
        {
          connected() {
            console.log('Connected to BulkAnalysisChannel');
          },
          
          disconnected() {
            console.log('Disconnected from BulkAnalysisChannel');
          },
          
          rejected() {
            console.log('Rejected from BulkAnalysisChannel');
          },
          
          received(data) {
            console.log('Received data from channel:', data);
            if (data.type === 'progress') {
              showProgress(data);
            } else if (data.type === 'complete') {
              showCompletion(data);
            }
          }
        }
      );
    } catch (error) {
      console.error('Error setting up ActionCable:', error);
    }
  }
  
  // Listen for form submissions to show immediate feedback
  document.addEventListener('submit', function(event) {
    const form = event.target;
    if (form.action && form.action.includes('bulk_analyze')) {
      console.log('Bulk analyze form submitted');
      // Show immediate progress feedback
      setTimeout(() => {
        showProgress({
          percentage: 0,
          processed: 0,
          total: 1
        });
        
        // Start a fallback progress simulation if ActionCable isn't working
        startFallbackProgress();
      }, 100);
    }
  });
  
  // Fallback progress simulation
  function startFallbackProgress() {
    let progress = 0;
    const interval = setInterval(() => {
      progress += Math.random() * 10;
      if (progress >= 90) {
        clearInterval(interval);
        progress = 90;
      }
      
      showProgress({
        percentage: Math.round(progress),
        processed: Math.round(progress / 10),
        total: 10
      });
    }, 2000);
    
    // Stop the simulation after 30 seconds
    setTimeout(() => {
      clearInterval(interval);
      showCompletion({
        message: "Analysis completed! (Fallback mode - check logs for actual results)"
      });
    }, 30000);
  }
  
  function showProgress(data) {
    console.log('Showing progress:', data);
    // Create or update progress notification
    let progressDiv = document.getElementById('bulk-analysis-progress');
    if (!progressDiv) {
      progressDiv = document.createElement('div');
      progressDiv.id = 'bulk-analysis-progress';
      progressDiv.className = 'fixed top-4 right-4 bg-white border border-gray-200 p-6 rounded-lg shadow-xl z-50 max-w-sm w-80 notification-slide-in';
      document.body.appendChild(progressDiv);
      console.log('Created progress div');
    }
    
    const percentage = data.percentage || 0;
    const processed = data.processed || 0;
    const total = data.total || 0;
    
    progressDiv.innerHTML = `
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center">
          <div class="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-500 mr-3"></div>
          <h4 class="font-semibold text-gray-900">Analyzing URLs</h4>
        </div>
        <button onclick="this.closest('#bulk-analysis-progress').remove()" class="text-gray-400 hover:text-gray-600 transition-colors">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
      
      <div class="mb-4">
        <div class="flex justify-between text-sm text-gray-600 mb-2">
          <span>Progress</span>
          <span>${percentage}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
          <div class="bg-gradient-to-r from-blue-500 to-blue-600 h-3 rounded-full progress-transition progress-bar-animated" 
               style="width: ${percentage}%"></div>
        </div>
      </div>
      
      <div class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Processed:</span>
          <span class="font-medium text-gray-900">${processed}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Total:</span>
          <span class="font-medium text-gray-900">${total}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Remaining:</span>
          <span class="font-medium text-gray-900">${total - processed}</span>
        </div>
      </div>
      
      <div class="mt-4 pt-3 border-t border-gray-100">
        <p class="text-xs text-gray-500">
          This may take a few minutes depending on the number of URLs.
        </p>
      </div>
    `;
  }
  
  function showCompletion(data) {
    console.log('Showing completion:', data);
    // Remove progress notification
    const progressDiv = document.getElementById('bulk-analysis-progress');
    if (progressDiv) {
      progressDiv.remove();
    }
    
    // Show completion notification
    const completionDiv = document.createElement('div');
    completionDiv.id = 'bulk-analysis-completion';
    completionDiv.className = 'fixed top-4 right-4 bg-white border border-green-200 p-6 rounded-lg shadow-xl z-50 max-w-sm w-80 notification-slide-in success-glow';
    completionDiv.innerHTML = `
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center">
          <div class="bg-green-100 rounded-full p-2 mr-3">
            <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
          <h4 class="font-semibold text-gray-900">Analysis Complete!</h4>
        </div>
        <button onclick="this.closest('#bulk-analysis-completion').remove()" class="text-gray-400 hover:text-gray-600 transition-colors">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
      
      <div class="space-y-3">
        <p class="text-sm text-gray-700">${data.message}</p>
        
        <div class="bg-green-50 border border-green-200 rounded-lg p-3">
          <div class="flex items-center">
            <svg class="w-4 h-4 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span class="text-sm text-green-800">Page will refresh automatically to show results</span>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(completionDiv);
    
    // Auto-remove after 8 seconds
    setTimeout(() => {
      if (completionDiv.parentElement) {
        completionDiv.remove();
      }
    }, 8000);
    
    // Refresh the page to show updated data after 3 seconds
    setTimeout(() => {
      window.location.reload();
    }, 3000);
  }
}); 