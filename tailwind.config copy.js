export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      keyframes: {
        lineGrow: {
          '0%': { transform: 'scaleX(0)' },
          '100%': { transform: 'scaleX(1)' },
        },
        dotPulse: {
          '0%': { transform: 'scale(1)', opacity: 0.8 },
          '50%': { transform: 'scale(1.25)', opacity: 1 },
          '100%': { transform: 'scale(1)', opacity: 0.8 },
        },
      },
      animation: {
        'line-grow': 'lineGrow 1.2s ease-out forwards',
        'dot-pulse': 'dotPulse 1.6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
