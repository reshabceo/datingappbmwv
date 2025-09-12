import React, { useMemo, useState } from 'react'
import { useLocation, useNavigate, Link } from 'react-router-dom'
import { supabase } from '../../supabaseClient'

export default function SignIn() {
  const nav = useNavigate()
  const loc = useLocation()
  const params = new URLSearchParams(loc.search)
  const initialEmail = (params.get('email') || (loc.state as any)?.email || '').trim()
  const adminMode = params.get('admin') === '1'
  const [email] = useState(initialEmail)
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const disabled = useMemo(() => !email || password.length < 6, [email, password])

  const signIn = async (e: React.FormEvent) => {
    e.preventDefault()
    if (disabled) return
    setLoading(true)
    try {
      if (adminMode && email.toLowerCase() === 'admin') {
        if (password === 'admin@123') {
          nav('/admin/dashboard', { replace: true })
          return
        } else {
          throw new Error('Invalid admin password')
        }
      }
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error
      nav('/browse', { replace: true })
    } catch (err: any) {
      alert(err?.message || 'Sign in failed')
    } finally {
      setLoading(false)
    }
  }

  const sendCode = async () => {
    try {
      await supabase.auth.signInWithOtp({ email, options: { shouldCreateUser: false } })
      nav('/auth/verify-email', { state: { email } })
    } catch (e: any) {
      alert(e?.message || 'Could not send code')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-8">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Log in or sign up</h2>
            <p className="text-light-white">Continue with your email to proceed</p>
          </div>

          <form onSubmit={signIn} className="space-y-4">
            <div>
              <input
                className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent transition-all"
                value={email}
                readOnly
              />
            </div>
            <div>
              <input
                type="password"
                className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent transition-all"
                placeholder={adminMode ? 'Admin password' : 'Password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            <button
              className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 disabled:opacity-50 disabled:transform-none"
              disabled={loading || disabled}
            >
              {loading ? 'Signing in...' : 'Sign In'}
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
                onClick={() => (window.location.href = '#')}
                className="w-full inline-flex justify-center py-3 px-4 border border-border-white-10 rounded-xl bg-white/90 text-sm font-medium text-gray-700 hover:bg-white transition-colors"
              >
                <img src="/assets/icons/google_logo.png" alt="Google" className="h-5 w-5 mr-2" />
                Google
              </button>
              <button
                onClick={() => (window.location.href = '#')}
                className="w-full inline-flex justify-center py-3 px-4 border border-border-white-10 rounded-xl bg-white/90 text-sm font-medium text-gray-700 hover:bg-white transition-colors"
              >
                <img src="/assets/icons/apple_logo.png" alt="Apple" className="h-5 w-5 mr-2" />
                Apple
              </button>
            </div>
          </div>

          <div className="mt-6 text-center space-y-2">
            <Link to="/auth/phone" className="text-light-white hover:text-white transition-colors text-sm font-medium">
              Sign in with phone number
            </Link>
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


