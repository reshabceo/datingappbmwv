module.exports = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Flutter app exact colors
        primary: '#133E87',
        'primary-dark': '#000000',
        secondary: '#3B82F6',
        'secondary-dark': '#4D0A1F44',
        pink: '#FF5A87',
        purple: '#8A2BE2',
        
        // App bar gradients
        'appbar-1': '#0F172A',
        'appbar-2': '#1E3A8A', 
        'appbar-3': '#172554',
        
        // Border colors
        'border-white-30': 'rgba(255, 255, 255, 0.3)',
        'border-white-10': 'rgba(255, 255, 255, 0.1)',
        'border-black-30': 'rgba(0, 0, 0, 0.38)',
        'border-black-10': 'rgba(0, 0, 0, 0.12)',
        'border-blue': '#3B82F6',
        
        // Dialog colors
        'dialog-bg-1': '#1A1A2E',
        'dialog-bg-2': '#16213E',
        
        // User message colors
        'other-user-1': '#374151',
        'other-user-2': '#1F2937',
        'my-user-1': '#3B82F6',
        'my-user-2': '#60A5FA',
        
        // Background gradients
        'bg-gradient-1': '#1E3A8A',
        
        // Additional colors
        'light-pink': '#FF5A87',
        'unselected': '#9CA3AF',
        'light-white': 'rgba(255, 255, 255, 0.5)',
        
        // Light theme
        'light-bg': '#F0F1F3',
        'light-card': '#FFFFFF',
        
        // Dark theme  
        'dark-card': '#1E1E1E',
      },
      fontFamily: {
        'app': ['AppFont', 'system-ui', 'sans-serif'],
        'sans': ['AppFont', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'gradient-appbar': 'linear-gradient(135deg, #0F172A 0%, #1E3A8A 50%, #172554 100%)',
        'gradient-user-other': 'linear-gradient(135deg, #374151 0%, #1F2937 100%)',
        'gradient-user-my': 'linear-gradient(135deg, #3B82F6 0%, #60A5FA 100%)',
        'gradient-dialog': 'linear-gradient(135deg, #1A1A2E 0%, #16213E 100%)',
        // App pink CTA and card gradients
        'gradient-cta': 'linear-gradient(90deg, #FF5A87 0%, #8A2BE2 100%)',
        'gradient-card-pink': 'linear-gradient(135deg, rgba(255,90,135,0.15) 0%, rgba(138,43,226,0.10) 100%)',
        // Header should match page background feel
        'gradient-header': 'linear-gradient(180deg, #000000 0%, #1E3A8A 50%, #000000 100%)',
      },
      boxShadow: {
        'card-soft': '0 2px 8px rgba(255,90,135,0.10)',
      },
      borderColor: {
        'pink-30': 'rgba(255,90,135,0.30)',
      },
    },
  },
  plugins: [],
}


