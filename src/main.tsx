import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import posthog from 'posthog-js'
import './index.css'
import App from './App.tsx'

posthog.init('REPLACE_WITH_POSTHOG_KEY', {
  api_host: 'https://app.posthog.com',
  capture_pageview: false,
  loaded: (ph) => {
    if (import.meta.env.DEV) ph.opt_out_capturing();
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
