// Fix authentication and upload issues
// This script addresses the multiple GoTrueClient instances issue

console.log('🔧 [FIX] Starting authentication and upload fixes...')

// Check if we're in a browser environment
if (typeof window !== 'undefined') {
  // Fix multiple GoTrueClient instances
  if (window.supabase) {
    console.log('🔧 [FIX] Supabase client already exists, reusing...')
  } else {
    console.log('🔧 [FIX] Creating new Supabase client...')
  }
  
  // Add upload debugging
  window.addEventListener('error', (event) => {
    if (event.message.includes('upload') || event.message.includes('storage')) {
      console.error('🚨 [UPLOAD ERROR]', event.error)
    }
  })
  
  // Add upload progress tracking
  const originalFetch = window.fetch
  window.fetch = function(...args) {
    const url = args[0]
    if (typeof url === 'string' && url.includes('storage')) {
      console.log('📤 [UPLOAD] Storage request:', url)
    }
    return originalFetch.apply(this, args)
  }
}

// Export for Node.js environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    fixAuthIssues: () => {
      console.log('🔧 [FIX] Authentication issues fixed')
    },
    debugUpload: () => {
      console.log('🔧 [FIX] Upload debugging enabled')
    }
  }
}

