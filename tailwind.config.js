const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js"
  ],
  theme: {
    extend: {
      // A field-guide palette: lichen greens for a confident identification,
      // ochre for "the guide has no entry for this", on warm paper.
      colors: {
        paper: "#f7f2e8",
        ink: "#23271f",
        moss: {
          50: "#eef3ea",
          100: "#dce7d4",
          200: "#bfd3b2",
          500: "#557f4b",
          600: "#436b3b",
          700: "#34552f",
          800: "#294325",
          900: "#1d2f1b"
        },
        ochre: {
          50: "#fbf4e4",
          100: "#f6e7c3",
          200: "#efd59c",
          600: "#a76e14",
          700: "#85570f",
          900: "#4b310a"
        }
      },
      fontFamily: {
        display: ["\"Iowan Old Style\"", "\"Palatino Linotype\"", "Palatino", "\"Book Antiqua\"", "Georgia", ...defaultTheme.fontFamily.serif],
        sans: defaultTheme.fontFamily.sans
      }
    }
  }
};
