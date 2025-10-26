import React, { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { getMyProfile, isProfileComplete } from '../services/profiles'

export default function RequireProfile({ children }: { children: JSX.Element }) {
  const { user, loading } = useAuth()
  const [checking, setChecking] = useState(true)
  const [complete, setComplete] = useState(false)

  useEffect(() => {
    let mounted = true
    const run = async () => {
      if (!user) return
      const p = await getMyProfile(user.id)
      if (!mounted) return
      setComplete(isProfileComplete(p))
      setChecking(false)
    }
    if (user) run()
    else setChecking(false)
    return () => { mounted = false }
  }, [user])

  if (loading || checking) return <div />
  if (!user) return <Navigate to="/login" replace />
  if (!complete) return <Navigate to="/profile/setup/1" replace />
  return children
}


