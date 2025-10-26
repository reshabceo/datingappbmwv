import React, { useState } from 'react'
import WizardShell from './WizardShell'
import { useAuth } from '../../context/AuthContext'
import { upsertMyProfile } from '../../services/profiles'
import { useNavigate } from 'react-router-dom'

export default function Step6Location() {
  const { user } = useAuth()
  const nav = useNavigate()
  const [lat, setLat] = useState<number | null>(null)
  const [lon, setLon] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)
  const enable = () => {
    setError(null)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude)
        setLon(pos.coords.longitude)
      },
      (err) => setError(err.message),
      { enableHighAccuracy: true }
    )
  }
  const complete = async () => {
    if (!user) return
    const locText = lat && lon ? `${lat},${lon}` : null
    try {
      await upsertMyProfile({ id: user.id, location: locText } as any)
    } catch (e: any) {
      console.error('[Step6Location] save error', e)
    }
    nav('/browse')
  }
  return (
    <WizardShell step={6}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold">Your location</div>
        <div className="rounded-xl border border-border-white-10 bg-white/10 p-6 text-light-white">
          We’ll use your location to show you people nearby.
          <div className="mt-3">
            <button onClick={enable} className="px-4 py-2 rounded-xl border border-border-white-10 text-white">Enable location</button>
          </div>
          {lat && lon && <div className="mt-3">Enabled ✓</div>}
          {error && <div className="mt-3 text-red-300">{error}</div>}
        </div>
        <div className="flex justify-between pt-4">
          <button onClick={()=>nav('/profile/setup/5')} className="px-6 py-3 rounded-full border border-border-white-10 text-white">Back</button>
          <button onClick={complete} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold">Complete</button>
        </div>
      </div>
    </WizardShell>
  )
}


