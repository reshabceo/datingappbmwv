import React, { useState, useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import AdminLogin from '../admin-components/AdminLogin'
import AdminDashboard from '../admin-components/AdminDashboard'

export default function AdminDashboardPage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const nav = useNavigate()
  const [searchParams] = useSearchParams()
  const preFilledEmail = searchParams.get('email') || ''

  // Check for existing admin session on component mount
  useEffect(() => {
    console.log('=== ADMIN SESSION CHECK ===');
    const adminSession = localStorage.getItem('adminSession')
    console.log('Admin session from localStorage:', adminSession)
    
    if (adminSession) {
      try {
        const sessionData = JSON.parse(adminSession)
        console.log('Parsed session data:', sessionData)
        
        // Check if session is not too old (24 hours)
        const loginTime = new Date(sessionData.loginTime)
        const now = new Date()
        const hoursDiff = (now.getTime() - loginTime.getTime()) / (1000 * 60 * 60)
        
        console.log('Login time:', loginTime)
        console.log('Current time:', now)
        console.log('Hours difference:', hoursDiff)
        
        if (hoursDiff < 24) {
          console.log('✅ Valid session found, setting authenticated to true')
          
          // Restore Supabase session if available
          if (sessionData.supabaseSession) {
            console.log('Restoring Supabase session...')
            // The session will be automatically restored by Supabase client
          }
          
          setIsAuthenticated(true)
        } else {
          console.log('❌ Session expired, removing from localStorage')
          localStorage.removeItem('adminSession')
        }
      } catch (error) {
        console.error('❌ Error parsing admin session:', error)
        localStorage.removeItem('adminSession')
      }
    } else {
      console.log('❌ No admin session found in localStorage')
    }
    console.log('=== END ADMIN SESSION CHECK ===')
  }, [])

  const handleLogin = (adminData: { id: string; email: string; full_name: string; role: string }) => {
    // Admin login successful
    setIsAuthenticated(true)
  }

  const handleLogout = () => {
    localStorage.removeItem('adminSession')
    setIsAuthenticated(false)
    nav('/login')
  }

  return (
    <div className="min-h-screen">
      {!isAuthenticated ? (
        <AdminLogin onLogin={handleLogin} preFilledEmail={preFilledEmail} />
      ) : (
        <AdminDashboard onLogout={handleLogout} />
      )}
    </div>
  )
}
