import React, { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

export default function ProtectedRoute({ children, adminRequired = false }: { children: JSX.Element; adminRequired?: boolean }) {
  const { user, loading } = useAuth()
  const [checkingAdmin, setCheckingAdmin] = useState(false)
  const [isAdmin, setIsAdmin] = useState(false)

  useEffect(() => {
    let mounted = true
    const check = async () => {
      if (!adminRequired) return
      if (!user) return
      setCheckingAdmin(true)
      try {
        const admin = await api.isUserAdmin(user.id)
        if (!mounted) return
        setIsAdmin(Boolean(admin))
      } catch (_) {
        // ignore
      } finally {
        if (mounted) setCheckingAdmin(false)
      }
    }
    check()
    return () => { mounted = false }
  }, [adminRequired, user])

  if (loading || checkingAdmin) return <div>Loading...</div>
  if (!user) return <Navigate to="/login" replace />
  if (adminRequired && !isAdmin) return <div className="p-4">Access denied</div>
  return children
}


