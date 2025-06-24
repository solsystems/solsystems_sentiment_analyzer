import Chart from 'chart.js/auto'

document.addEventListener('DOMContentLoaded', function() {
  const chartCanvas = document.getElementById('sentimentChart');
  
  if (!chartCanvas) return;

  // Get sentiment data from the page
  const sentimentData = JSON.parse(chartCanvas.dataset.sentimentData || '{}');
  
  // Prepare chart data
  const labels = Object.keys(sentimentData);
  const data = Object.values(sentimentData);
  
  // Define colors for each sentiment
  const colors = {
    'positive': '#10b981',
    'negative': '#ef4444', 
    'neutral': '#f59e0b',
    'unclear': '#6b7280'
  };
  
  const backgroundColor = labels.map(label => colors[label] || '#6b7280');
  const borderColor = labels.map(label => colors[label] || '#6b7280');

  // Create the chart
  const ctx = chartCanvas.getContext('2d');
  const chart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels.map(label => label.charAt(0).toUpperCase() + label.slice(1)),
      datasets: [{
        label: 'Number of URLs',
        data: data,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: 2,
        borderRadius: 8,
        borderSkipped: false,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          backgroundColor: 'rgba(0, 0, 0, 0.8)',
          titleColor: 'white',
          bodyColor: 'white',
          borderColor: 'rgba(255, 255, 255, 0.1)',
          borderWidth: 1,
          cornerRadius: 8,
          displayColors: false,
          callbacks: {
            title: function(context) {
              return context[0].label;
            },
            label: function(context) {
              return `${context.parsed.y} URLs analyzed`;
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: {
            color: 'rgba(0, 0, 0, 0.1)',
            drawBorder: false
          },
          ticks: {
            color: '#6b7280',
            font: {
              size: 12
            }
          }
        },
        x: {
          grid: {
            display: false
          },
          ticks: {
            color: '#6b7280',
            font: {
              size: 14,
              weight: 'bold'
            }
          }
        }
      },
      onClick: function(event, elements) {
        if (elements.length > 0) {
          const index = elements[0].index;
          const label = labels[index];
          const value = data[index];
          
          showChartInfo(label, value);
        }
      },
      onHover: function(event, elements) {
        event.native.target.style.cursor = elements.length ? 'pointer' : 'default';
      }
    }
  });

  // Function to show detailed info when a bar is clicked
  function showChartInfo(sentiment, count) {
    const chartInfo = document.getElementById('chartInfo');
    const chartTitle = document.getElementById('chartTitle');
    const chartDescription = document.getElementById('chartDescription');
    
    const sentimentInfo = {
      'positive': {
        title: 'Positive Sentiment',
        description: `${count} URLs were analyzed as having positive sentiment. These URLs likely contain favorable content about solar energy, such as benefits, success stories, or positive market trends.`
      },
      'negative': {
        title: 'Negative Sentiment', 
        description: `${count} URLs were analyzed as having negative sentiment. These URLs may contain concerns, criticisms, or challenges related to solar energy adoption or implementation.`
      },
      'neutral': {
        title: 'Neutral Sentiment',
        description: `${count} URLs were analyzed as having neutral sentiment. These URLs likely contain factual information, technical details, or balanced discussions about solar energy topics.`
      },
      'unclear': {
        title: 'Unclear Sentiment',
        description: `${count} URLs had unclear sentiment analysis results. This may be due to mixed content, technical language, or insufficient context for accurate sentiment determination.`
      }
    };
    
    const info = sentimentInfo[sentiment] || {
      title: `${sentiment.charAt(0).toUpperCase() + sentiment.slice(1)} Sentiment`,
      description: `${count} URLs were analyzed with this sentiment classification.`
    };
    
    chartTitle.textContent = info.title;
    chartDescription.textContent = info.description;
    chartInfo.classList.remove('hidden');
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      chartInfo.classList.add('hidden');
    }, 5000);
  }
}); 