import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import AdminLogin from '../admin-components/AdminLogin'
import AdminDashboard from '../admin-components/AdminDashboard'

export default function AdminDashboardPage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const nav = useNavigate()

  const handleLogin = (credentials: { username: string; password: string }) => {
    // Simple demo authentication - in real app, this would validate against backend
    if (credentials.username === 'admin' && credentials.password === 'admin@123') {
      setIsAuthenticated(true)
    } else {
      alert('Invalid credentials. Please use admin/admin@123 for demo.')
    }
  }

  const handleLogout = () => {
    setIsAuthenticated(false)
    nav('/login')
  }

  return (
    <div className="min-h-screen">
      {!isAuthenticated ? (
        <AdminLogin onLogin={handleLogin} />
      ) : (
        <AdminDashboard onLogout={handleLogout} />
      )}
    </div>
  )
}
