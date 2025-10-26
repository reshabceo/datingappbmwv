import React, { useState } from 'react'
import { useAuth } from '../../context/AuthContext'

export default function PhoneOtp() {
  const { signInWithPhone } = useAuth()
  const [phone, setPhone] = useState('')
  const [sent, setSent] = useState(false)

  const send = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await signInWithPhone(phone)
      setSent(true)
      alert('OTP sent — check your SMS')
    } catch (e) {
      console.error(e)
      alert('Failed to send OTP')
    }
  }

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-6">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Phone sign-in</h2>
            <p className="text-light-white">We’ll send you a verification code</p>
          </div>
          <form onSubmit={send} className="space-y-4">
            <input
              className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl"
              placeholder="+1234567890"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />
            <button className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold">Send OTP</button>
          </form>
          {sent && <div className="mt-4 text-sm text-light-white">OTP sent. Follow the instructions in SMS to sign in.</div>}
        </div>
      </div>
    </div>
  )
}


