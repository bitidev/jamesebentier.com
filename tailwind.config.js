module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        'sans-serif': ['Montserrat', 'sans-serif'],
        'resume': ["Helvetica Neue", "Helvetica", "Arial", "Lucida Grande", "sans-serif"],
      },
      listStyleType: {
        square: 'square',
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("daisyui")
  ],
  daisyui: {
    themes: ["light", "dark"],
  },
}
