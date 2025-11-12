import React, { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { supabase } from '../../supabaseClient'
import { validateEmail } from '../../utils/emailValidation'

export default function SignUp() {
  const loc = useLocation()
  const params = new URLSearchParams(loc.search)
  const presetEmail = (params.get('email') || '').trim()
  const [email, setEmail] = useState(presetEmail)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !password) return alert('Enter email and password')
    
    // Validate email format and prevent invalid emails
    const emailValidation = validateEmail(email)
    if (!emailValidation.valid) {
      return alert(`Invalid email: ${emailValidation.error}`)
    }
    
    if (password.length < 6) return alert('Password must be at least 6 characters')
    if (password !== confirm) return alert('Passwords do not match')
    setLoading(true)
    try {
      // Create user; Supabase will send verification email depending on project settings
      const { data, error } = await supabase.auth.signUp({ email, password })
      if (error) throw error
      // Navigate to verification page where user can enter 6-digit code if required
      navigate('/auth/verify-email', { state: { email } })
    } catch (e: any) {
      console.error(e)
      alert('Sign up failed: ' + (e.message || e.toString()))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-8">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Create account</h2>
            <p className="text-light-white">Set a password to continue</p>
          </div>
          <form onSubmit={submit} className="space-y-4">
            <input className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
            <input type="password" className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} />
            <input type="password" className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="Confirm password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
            <button className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold" disabled={loading}>Create account</button>
          </form>
        </div>
      </div>
    </div>
  )
}


