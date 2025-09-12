import React, { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../../supabaseClient'

export default function MagicLinkVerify() {
  const navigate = useNavigate()

  useEffect(() => {
    // Supabase will set session automatically if magic link is used.
    const check = async () => {
      const {
        data: { session },
        error,
      } = await supabase.auth.getSession()
      if (session && !error) {
        navigate('/', { replace: true })
      }
    }
    check()
  }, [navigate])

  return (
    <div className="max-w-md mx-auto mt-8">
      <h2 className="text-2xl font-semibold mb-4">Verifying...</h2>
      <p className="text-gray-600">If you're not redirected automatically, return to the app.</p>
    </div>
  )
}


