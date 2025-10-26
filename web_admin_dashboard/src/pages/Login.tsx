import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const { signInWithOAuth } = useAuth()
  const nav = useNavigate()
  const isAdminEmail = email.trim().toLowerCase() === 'admin@datingapp.com'

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      // Admin entry: if user typed "admin@datingapp.com", route directly to admin dashboard
      if (isAdminEmail) {
        nav(`/admin/dashboard?email=${encodeURIComponent(email)}`, { replace: true })
        return
      }
      const { supabase } = await import('../supabaseClient')
      const { error } = await supabase.auth.signInWithOtp({ email, options: { shouldCreateUser: false } })
      if (error) nav(`/signup?email=${encodeURIComponent(email)}`)
      else nav(`/signin?email=${encodeURIComponent(email)}`)
    } catch (_) {
      // Network or unexpected error — prefer signup to avoid blocking new users
      nav(`/signup?email=${encodeURIComponent(email)}`)
    } finally {
      setLoading(false)
    }
  }

  const oauth = async (provider: 'google' | 'apple') => {
    try {
      await signInWithOAuth(provider)
    } catch (e) {
      console.error(e)
      alert('OAuth failed')
    }
  }

  return (
    <div className="min-h-[calc(100vh-80px)] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-8">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Log in or sign up</h2>
            <p className="text-light-white">Continue with your email to proceed</p>
          </div>

          <form onSubmit={submit} className="space-y-4">
            <div>
              <input
                className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent transition-all"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                type="text"
              />
            </div>
            <button 
              className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 disabled:opacity-50 disabled:transform-none" 
              disabled={loading}
            >
              {loading ? 'Please wait...' : (isAdminEmail ? 'Continue to Admin' : 'Continue')}
            </button>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-border-white-10"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-transparent text-light-white">Or continue with</span>
              </div>
            </div>

            <div className="mt-6 grid grid-cols-2 gap-3">
              <button 
                onClick={() => oauth('google')} 
                className="w-full inline-flex justify-center py-3 px-4 border border-border-white-10 rounded-xl bg-white/90 text-sm font-medium text-gray-700 hover:bg-white transition-colors"
              >
                <img src="/assets/icons/google_logo.png" alt="Google" className="h-5 w-5 mr-2" />
                Google
              </button>
              <button 
                onClick={() => oauth('apple')} 
                className="w-full inline-flex justify-center py-3 px-4 border border-border-white-10 rounded-xl bg-white/90 text-sm font-medium text-gray-700 hover:bg-white transition-colors"
              >
                <img src="/assets/icons/apple_logo.png" alt="Apple" className="h-5 w-5 mr-2" />
                Apple
              </button>
            </div>
          </div>

          <div className="mt-6 text-center space-y-2">
            <div>
              <span className="text-light-white text-sm">Don't have an account? </span>
              <Link to={`/signup?email=${encodeURIComponent(email)}`} className="text-white font-semibold">
                Create one
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}


