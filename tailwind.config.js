module.exports = {
  content: [
    './app/views/**/*.{html,erb}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#f59e0b',      // main brand color (used for buttons, accents)
        secondary: '#2563eb',    // secondary brand color (used for links, hovers)
        danger: '#dc2626',       // error / destructive actions
        surface: '#111111',      // main dark background
        neutral: '#f9fafb'       // light backgrounds / soft contrast
      }
    }
  },
  plugins: []
}
