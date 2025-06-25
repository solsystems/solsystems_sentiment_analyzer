import { createConsumer } from "@rails/actioncable"

console.log('=== BULK ANALYSIS JAVASCRIPT LOADED ===');

// Test function to check if JavaScript is loaded
window.testBulkAnalysis = function() {
  console.log('Bulk analysis test function called');
  return 'Bulk analysis JavaScript is loaded!';
};

document.addEventListener('DOMContentLoaded', function() {
  console.log('Bulk analysis JavaScript loaded');
  
  // Simple ActionCable setup
  const consumer = createConsumer('/cable');
  console.log('ActionCable consumer created');
  
  const subscription = consumer.subscriptions.create("BulkAnalysisChannel", {
    connected() {
      console.log('Connected to BulkAnalysisChannel');
    },
    
    disconnected() {
      console.log('Disconnected from BulkAnalysisChannel');
    },
    
    received(data) {
      console.log('Received data:', data);
      
      if (data.type === 'progress') {
        updateAnalysisStatus(data);
      } else if (data.type === 'complete') {
        showCompletionStatus(data);
        setTimeout(() => {
          window.location.reload();
        }, 2000);
      }
    }
  });
  
  // Function to update the analysis status with progress
  function updateAnalysisStatus(data) {
    console.log('Updating analysis status:', data);
    
    const statusDiv = document.getElementById('bulk-analysis-status');
    const progressText = document.getElementById('analysis-progress-text');
    const progressFill = document.getElementById('analysis-progress-fill');
    const percentageText = document.getElementById('analysis-percentage');
    
    if (statusDiv && progressText && progressFill && percentageText) {
      const processed = data.processed || 0;
      const total = data.total || 0;
      const percentage = data.percentage || 0;
      
      // Show the status div when updating
      statusDiv.style.display = 'block';
      
      // Update the progress text - only show counts
      progressText.textContent = `Analyzing ${processed} of ${total} URLs`;
      
      // Update the progress bar
      progressFill.style.width = `${percentage}%`;
      
      // Update the percentage text
      percentageText.textContent = `${percentage}%`;
      
      console.log(`Updated status: ${processed}/${total} (${percentage}%)`);
    }
  }
  
  // Function to show completion status
  function showCompletionStatus(data) {
    const statusDiv = document.getElementById('bulk-analysis-status');
    
    if (statusDiv) {
      statusDiv.innerHTML = `
        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <div class="bg-green-100 rounded-full p-2 mr-3">
                <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
              </div>
              <div>
                <h3 class="text-lg font-semibold text-green-900">Analysis Complete!</h3>
                <p class="text-sm text-green-700">${data.message || 'Bulk analysis completed successfully.'}</p>
              </div>
            </div>
            <div class="text-right">
              <div class="w-32 bg-green-200 rounded-full h-2 mb-2">
                <div class="bg-green-500 h-2 rounded-full transition-all duration-300" style="width: 100%"></div>
              </div>
              <p class="text-xs text-green-600">100%</p>
            </div>
          </div>
        </div>
      `;
      
      console.log('Showed completion status');
    }
  }
}); 