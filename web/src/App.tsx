import React from 'react'
import { Routes, Route, Link } from 'react-router-dom'
import Login from './pages/Login'
import Profiles from './pages/Profiles'
import Home from './pages/Home'
import Admin from './pages/Admin'
import ProfileDetail from './pages/ProfileDetail'
import PhoneOtp from './pages/Auth/PhoneOtp'
import MagicLinkVerify from './pages/Auth/MagicLinkVerify'
import SignUp from './pages/Auth/SignUp'
import SignIn from './pages/Auth/SignIn'
import EmailCodeVerify from './pages/Auth/EmailCodeVerify'
import Stories from './pages/Stories'
import StoryViewer from './components/StoryViewer'
import StoryDetail from './pages/StoryDetail'
import ProfileEdit from './pages/ProfileEdit'
import Plans from './pages/Plans'
import AdminSubscriptions from './pages/AdminSubscriptions'
import { useAuth } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Footer from './components/Footer'
import RequireProfile from './components/RequireProfile'
import Step1Gender from './pages/ProfileSetup/Step1Gender'
import Step2Basic from './pages/ProfileSetup/Step2Basic'
import Step3Photos from './pages/ProfileSetup/Step3Photos'
import Step4Bio from './pages/ProfileSetup/Step4Bio'
import Step5Interests from './pages/ProfileSetup/Step5Interests'
import Step6Location from './pages/ProfileSetup/Step6Location'
import AdminEmbed from './pages/AdminEmbed'
import AdminDashboard from './pages/AdminDashboard'

export default function App() {
  const { user, signOut } = useAuth()

  return (
    <div className="min-h-screen font-app">
      <header className="sticky top-0 z-50 bg-gradient-card-pink backdrop-blur border-b border-pink-30">
        <div className="max-w-[1800px] 2xl:max-w-[1920px] mx-auto px-8 xl:px-12 py-3 flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-8 w-auto" />
            <span className="font-bold text-lg text-white">Love Bug</span>
          </Link>
          <nav className="flex items-center gap-8 text-white">
            <Link to="/" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9.5L12 3l9 6.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1V9.5z"/></svg>
              <span>Home</span>
            </Link>
            <Link to="/browse" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <span>Discover</span>
            </Link>
            <Link to="/plans" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7l9-4 9 4-9 4-9-4z"/><path d="M21 7v6l-9 4-9-4V7"/></svg>
              <span>Plans</span>
            </Link>
            {false && (
              <a href="/admin/index.html#/admin" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 12c2.21 0 4-1.79 4-4S14.21 4 12 4 8 5.79 8 8s1.79 4 4 4z"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>
                <span>Admin</span>
              </a>
            )}
            {!user && (
              <Link to="/login" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <span>Sign In</span>
              </Link>
            )}
            {user && (
              <Link to="/profile/edit" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.24 12.24l-8.48 8.48H7v-4.76l8.48-8.48z"/><path d="M18 2l4 4"/></svg>
                <span>Edit profile</span>
              </Link>
            )}
            {user && (
              <button onClick={() => signOut()} className="text-sm text-red-300 hover:text-red-200 transition-colors">Sign out</button>
            )}
          </nav>
        </div>
      </header>

      <main className="max-w-[1800px] 2xl:max-w-[1920px] mx-auto px-8 xl:px-12 py-4">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/auth/phone" element={<PhoneOtp />} />
          <Route path="/auth/magic" element={<MagicLinkVerify />} />
          <Route path="/signup" element={<SignUp />} />
          <Route path="/signin" element={<SignIn />} />
          <Route path="/auth/verify-email" element={<EmailCodeVerify />} />
          <Route path="/stories" element={<Stories />} />
          <Route path="/story/:id" element={<StoryDetail />} />
          <Route path="/profile/:id" element={<ProfileDetail />} />
          <Route path="/profile/edit" element={<ProfileEdit />} />
          <Route path="/plans" element={<Plans />} />
          {/* Profile setup wizard */}
          <Route path="/profile/setup/1" element={<ProtectedRoute><Step1Gender /></ProtectedRoute>} />
          <Route path="/profile/setup/2" element={<ProtectedRoute><Step2Basic /></ProtectedRoute>} />
          <Route path="/profile/setup/3" element={<ProtectedRoute><Step3Photos /></ProtectedRoute>} />
          <Route path="/profile/setup/4" element={<ProtectedRoute><Step4Bio /></ProtectedRoute>} />
          <Route path="/profile/setup/5" element={<ProtectedRoute><Step5Interests /></ProtectedRoute>} />
          <Route path="/profile/setup/6" element={<ProtectedRoute><Step6Location /></ProtectedRoute>} />
          <Route path="/browse" element={<ProtectedRoute><RequireProfile><Profiles /></RequireProfile></ProtectedRoute>} />
          <Route path="/admin" element={<ProtectedRoute adminRequired={true}><Admin /></ProtectedRoute>} />
          <Route path="/admin/subscriptions" element={<ProtectedRoute adminRequired={true}><AdminSubscriptions /></ProtectedRoute>} />
          <Route path="/admin/embed" element={<AdminEmbed />} />
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
        </Routes>
      </main>
      <Footer />
    </div>
  )
}


