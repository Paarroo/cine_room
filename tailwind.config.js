module.exports = {
  content: [
    './app/views/**/*.{html,erb}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      // COLORS - STRICT 5 COLORS MAX (jury requirement)
      colors: {
        primary: '#f59e0b',      // Gold - main brand color
        surface: '#0a0a0a',      // Dark - main background
        content: '#ffffff',      // White - primary text
        muted: '#6b7280',        // Gray - secondary text
        accent: '#2563eb'        // Blue - links and secondary actions
      },

      // FONTS - MAX 3 FONTS (jury requirement)
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],     // Primary font
        display: ['Inter', 'system-ui', 'sans-serif'],  // Display font (same family)
        mono: ['JetBrains Mono', 'monospace']           // Optional for prices/code
      },

      // RESPONSIVE BREAKPOINTS - Mobile first approach
      screens: {
        'sm': '640px',   // Tablet portrait
        'md': '768px',   // Tablet landscape
        'lg': '1024px',  // Desktop
        'xl': '1280px',  // Large desktop
        '2xl': '1536px'  // Extra large desktop
      },

      // SPACING SYSTEM - Consistent spacing scale
      spacing: {
        '18': '4.5rem',   // 72px
        '88': '22rem',    // 352px
        '128': '32rem'    // 512px
      },

      // ANIMATIONS - Smooth interactions
      animation: {
        'fade-in-up': 'fadeInUp 0.6s ease-out',
        'fade-in': 'fadeIn 0.8s ease-out',
        'scale-in': 'scaleIn 0.5s ease-out',
        'slide-in': 'slideIn 0.3s ease-out'
      },

      keyframes: {
        fadeInUp: {
          '0%': {
            opacity: '0',
            transform: 'translateY(30px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)'
          }
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        scaleIn: {
          '0%': {
            opacity: '0',
            transform: 'scale(0.9)'
          },
          '100%': {
            opacity: '1',
            transform: 'scale(1)'
          }
        },
        slideIn: {
          '0%': {
            opacity: '0',
            transform: 'translateX(-20px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateX(0)'
          }
        }
      },

      // BACKDROP BLUR - Modern glass effects
      backdropBlur: {
        'xs': '2px',
        'sm': '4px',
        'md': '8px',
        'lg': '12px',
        'xl': '16px',
        '2xl': '24px',
        '3xl': '40px'
      }
    }
  },

  // PLUGINS - Extended functionality iw we need for later implement
  plugins: [
    // Add any additional Tailwind plugins here
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography')
  ]
}
