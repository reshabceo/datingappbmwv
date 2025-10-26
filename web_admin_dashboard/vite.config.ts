import { defineConfig } from 'vite'
import path from 'path'

export default defineConfig(async () => {
  const reactPlugin = (await import('@vitejs/plugin-react')).default
  return {
    plugins: [reactPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    build: {
      rollupOptions: {
        output: {
          manualChunks: undefined,
        },
      },
    },
    server: {
      historyApiFallback: true,
    },
    preview: {
      historyApiFallback: true,
    },
  }
})