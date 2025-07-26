module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        'dark': {
          300: '#1f1f1f',
          400: '#0a0a0a'
        },
        'gold': {
          400: '#fbbf24',
          500: '#fbbf24',
          600: '#f59e0b',
          700: '#d97706'
        },
        'purple': {
          600: '#8b5cf6'
        },
        'primary': '#fbbf24',
        'surface': '#0a0a0a',
        'content': '#ffffff',
        'muted': 'rgba(255, 255, 255, 0.7)',
        'accent': '#8b5cf6'
      },
      fontFamily: {
        'display': ['Inter', 'system-ui', 'sans-serif'],
        'body': ['Inter', 'system-ui', 'sans-serif']
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-glow': 'pulseGlow 2s infinite'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        },
        pulseGlow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(251, 191, 36, 0.3)' },
          '50%': { boxShadow: '0 0 30px rgba(251, 191, 36, 0.6)' }
        }
      },
      backdropBlur: {
        'xs': '2px',
        'sm': '4px',
        'md': '8px',
        'lg': '12px',
        'xl': '16px'
      }
    }
  },
  plugins: [
    function({ addUtilities }) {
      const newUtilities = {
        '.glass-effect': {
          'background': 'rgba(255, 255, 255, 0.05)',
          'backdrop-filter': 'blur(12px)',
          'border': '1px solid rgba(255, 255, 255, 0.1)',
          'box-shadow': '0 8px 32px rgba(0, 0, 0, 0.3)'
        },
        '.glass-subtle': {
          'background': 'rgba(255, 255, 255, 0.02)',
          'backdrop-filter': 'blur(8px)',
          'border': '1px solid rgba(255, 255, 255, 0.05)',
          'box-shadow': '0 4px 16px rgba(0, 0, 0, 0.2)'
        },
        '.nav-blur': {
          'background': 'rgba(10, 10, 10, 0.8)',
          'backdrop-filter': 'blur(12px)',
          'border-bottom': '1px solid rgba(255, 255, 255, 0.1)'
        },
        '.gradient-text': {
          'background': 'linear-gradient(135deg, #fbbf24, #f59e0b)',
          'background-clip': 'text',
          '-webkit-background-clip': 'text',
          '-webkit-text-fill-color': 'transparent'
        },
        '.card-hover': {
          'transition': 'all 0.3s ease',
          '&:hover': {
            'transform': 'translateY(-4px)',
            'box-shadow': '0 12px 40px rgba(0, 0, 0, 0.4)'
          }
        },
        '.btn-primary': {
          'padding': '0.75rem 1rem',
          'background': 'linear-gradient(135deg, #fbbf24, #f59e0b)',
          'color': '#ffffff',
          'border-radius': '0.75rem',
          'font-weight': '500',
          'transition': 'all 0.3s ease',
          'width': '100%',
          'font-size': '0.875rem',
          '&:hover': {
            'background': 'linear-gradient(135deg, #f59e0b, #d97706)',
            'transform': 'translateY(-1px)'
          }
        },
        '.btn-secondary': {
          'padding': '0.75rem 1.5rem',
          'background': 'rgba(255, 255, 255, 0.1)',
          'color': '#ffffff',
          'border-radius': '0.75rem',
          'font-weight': '500',
          'transition': 'all 0.3s ease',
          'text-decoration': 'none',
          'display': 'inline-flex',
          'align-items': 'center',
          '&:hover': {
            'background': 'rgba(255, 255, 255, 0.2)',
            'transform': 'translateY(-1px)'
          }
        },
        '.container-app': {
          'max-width': '1280px',
          'margin': '0 auto',
          'padding': '0 1rem'
        }
      }
      addUtilities(newUtilities)
    }
  ]
}