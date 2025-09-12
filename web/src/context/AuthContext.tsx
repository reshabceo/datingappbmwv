import React, { createContext, useContext, useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'

type AuthContextValue = {
  user: any | null
  loading: boolean
  signOut: () => Promise<void>
  signInWithEmail: (email: string) => Promise<void>
  signInWithPhone: (phone: string) => Promise<void>
  signInWithOAuth: (provider: 'google' | 'apple') => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<any | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true
    const init = async () => {
      const {
        data: { session },
      } = await supabase.auth.getSession()
      if (!mounted) return
      setUser(session?.user ?? null)
      setLoading(false)
      const { data } = supabase.auth.onAuthStateChange((_event, sess) => {
        setUser(sess?.user ?? null)
      })
      // cleanup subscription on unmount
      return () => {
        try { data.subscription.unsubscribe() } catch (_) {}
      }
    }
    init()
    return () => {
      mounted = false
    }
  }, [])

  const signOut = async () => {
    await supabase.auth.signOut()
    setUser(null)
  }

  const signInWithEmail = async (email: string) => {
    await supabase.auth.signInWithOtp({ email })
  }

  const signInWithPhone = async (phone: string) => {
    await supabase.auth.signInWithOtp({ phone })
  }

  const signInWithOAuth = async (provider: 'google' | 'apple') => {
    await supabase.auth.signInWithOAuth({ provider })
  }

  return (
    <AuthContext.Provider value={{ user, loading, signOut, signInWithEmail, signInWithPhone, signInWithOAuth }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}


