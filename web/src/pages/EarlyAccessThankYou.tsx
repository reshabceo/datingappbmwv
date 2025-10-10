import React, { useEffect } from 'react'
import { Link } from 'react-router-dom'

export default function EarlyAccessThankYou() {
  useEffect(() => {
    try {
      // Google Tag Manager event
      // @ts-ignore
      window.dataLayer = window.dataLayer || []
      // @ts-ignore
      window.dataLayer.push({
        event: 'early_access_submitted'
      })
    } catch {}

    try {
      // Meta Pixel event
      // @ts-ignore
      if (window.fbq) {
        // @ts-ignore
        window.fbq('track', 'Lead')
      }
    } catch {}
  }, [])

  return (
    <div className="min-h-[60vh] flex items-center justify-center">
      <div className="max-w-xl text-center">
        <div className="text-4xl mb-4">🎉</div>
        <h1 className="text-3xl font-bold text-white mb-3">Thank You!</h1>
        <p className="text-light-white mb-6">
          You’re on the Early Access list. We’ll email you as soon as we open the doors.
        </p>
        <Link to="/" className="inline-block px-6 py-3 rounded-xl bg-white/10 border border-border-white-10 text-white hover:bg-white/15">
          Back to Home
        </Link>
      </div>
    </div>
  )
}


