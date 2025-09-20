import React, { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { supabase } from '../../supabaseClient'
import { getMyProfile, isProfileComplete } from '../../services/profiles'

export default function EmailCodeVerify() {
  const nav = useNavigate()
  const loc = useLocation()
  const email = (loc.state as any)?.email ?? ''
  const [code, setCode] = useState('')
  const [loading, setLoading] = useState(false)

  const verify = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!code || !email) return alert('Enter code')
    setLoading(true)
    try {
      // Try to verify OTP via Supabase JS
      // supabase.auth.verifyOtp may exist depending on client version
      // We'll attempt the call and fallback to checking session
      // @ts-ignore
      const res = await supabase.auth.verifyOtp({ email, token: code, type: 'email' })
      if (res?.error) throw res.error
      // If verification succeeded, get session and route based on profile completeness
      const { data } = await supabase.auth.getSession()
      const session = data.session
      if (!session) {
        alert('Verified. Please sign in to continue.')
        nav('/login', { replace: true })
        return
      }
      const userId = session.user.id
      const profile = await getMyProfile(userId)
      const complete = isProfileComplete(profile)
      nav(complete ? '/browse' : '/profile/setup/1', { replace: true })
    } catch (e: any) {
      console.error(e)
      alert('Verification failed: ' + (e.message || e.toString()))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-6">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Verify your email</h2>
            <p className="text-light-white">Code sent to {email}</p>
          </div>
          <form onSubmit={verify} className="space-y-4">
            <input className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="6-digit code" value={code} onChange={(e) => setCode(e.target.value)} />
            <button className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold" disabled={loading}>Verify Code</button>
          </form>
        </div>
      </div>
    </div>
  )
}


