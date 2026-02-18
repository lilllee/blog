const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  darkMode: "class",
  content: [
    "./js/**/*.js",
    "../lib/blog_web.ex",
    "../lib/blog_web/**/*.*ex"
  ],
  safelist: [
    'tracking-wider',
    'min-h-[20px]',
    // Skill category colors
    'text-blue-400', 'bg-blue-500/10', 'border-blue-500/20',
    'text-yellow-400', 'bg-yellow-500/10', 'border-yellow-500/20',
    'text-purple-400', 'bg-purple-500/10', 'border-purple-500/20',
    'text-green-400', 'bg-green-500/10', 'border-green-500/20',
    'text-orange-400', 'bg-orange-500/10', 'border-orange-500/20',
    'text-red-400', 'bg-red-500/10', 'border-red-500/20',
    'text-gray-400', 'bg-gray-500/10', 'border-gray-500/20',
    // Experience/education timeline
    'border-blue-500/30', 'border-blue-500',
    // Header gradient and badges
    'border-green-500/20', 'bg-green-500/10', 'text-green-400',
    // Secondary bg
    'bg-secondary/20', 'bg-secondary/30', 'bg-secondary/40',
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        card: "var(--card)",
        muted: {
          DEFAULT: "var(--muted)",
          foreground: "var(--muted-foreground)",
        },
        border: "var(--border)",
        secondary: {
          DEFAULT: "var(--secondary)",
          foreground: "var(--secondary-foreground)",
        },
        accent: {
          DEFAULT: "var(--accent)",
          foreground: "var(--accent-foreground)",
        },
        primary: {
          DEFAULT: "var(--primary)",
          foreground: "var(--primary-foreground)",
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      borderColor: {
        DEFAULT: "var(--border)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Heroicons via CSS mask-image
    plugin(function({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        let fullDir = iconsDir + dir
        if (fs.existsSync(fullDir)) {
          fs.readdirSync(fullDir).forEach(file => {
            let name = path.basename(file, ".svg") + suffix
            values[name] = { name, fullPath: path.join(fullDir, file) }
          })
        }
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("fontSize.base") || "1.5rem"
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size,
          }
        }
      }, { values })
    }),
    // Phoenix-specific loading states
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
  ]
}
