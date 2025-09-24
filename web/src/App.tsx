import React, { useState } from 'react'
import { Routes, Route, Link, useLocation } from 'react-router-dom'
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
import PremiumPlans from './pages/PremiumPlans'
import PaymentTest from './pages/PaymentTest'
import OrderHistory from './pages/OrderHistory'
import AdminSubscriptions from './pages/AdminSubscriptions'
import { useAuth } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Footer from './components/Footer'
import RequireProfile from './components/RequireProfile'
import PremiumStatusWidget from './components/PremiumStatusWidget'
import Step1Gender from './pages/ProfileSetup/Step1Gender'
import Step2Basic from './pages/ProfileSetup/Step2Basic'
import Step3Photos from './pages/ProfileSetup/Step3Photos'
import Step4Bio from './pages/ProfileSetup/Step4Bio'
import Step5Interests from './pages/ProfileSetup/Step5Interests'
import Step6Location from './pages/ProfileSetup/Step6Location'
import AdminEmbed from './pages/AdminEmbed'
import AdminDashboard from './pages/AdminDashboard'
import CommunityGuidelines from './pages/CommunityGuidelines'
import SafetyTips from './pages/SafetyTips'
import CookiePolicy from './pages/CookiePolicy'
import ContactUs from './pages/ContactUs'
import AboutUs from './pages/AboutUs'
import Accessibility from './pages/Accessibility'
import PrivacyPolicy from './pages/PrivacyPolicy'
import TermsOfService from './pages/TermsOfService'
import RefundPolicy from './pages/RefundPolicy'
import Careers from './pages/Careers'
import Press from './pages/Press'
import Blog from './pages/Blog'
import SubscriptionPlansAdmin from './pages/admin/SubscriptionPlansAdmin'
import OffersAdmin from './pages/admin/OffersAdmin'

export default function App() {
  const { user, signOut } = useAuth()
  const location = useLocation()
  const isAdminRoute = location.pathname.startsWith('/admin')
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  return (
    <div className="min-h-screen font-app">
      {!isAdminRoute && (
        <header className="sticky top-0 z-50 bg-gradient-card-pink backdrop-blur border-b border-pink-30">
        <div className="w-full px-4 sm:px-6 md:px-8 xl:px-12 py-3 flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2">
            <img src="/assets/5347d249-47bc-4b25-8053-83255e59a1f0.png" alt="Love Bug Logo" className="h-10 sm:h-12 w-auto" />
          </Link>
          
          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-6 lg:gap-8 text-white">
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
            {!user && (
              <Link to="/login" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                <span>Sign In</span>
              </Link>
            )}
            {user && (
              <>
                <Link to="/profile/edit" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.24 12.24l-8.48 8.48H7v-4.76l8.48-8.48z"/><path d="M18 2l4 4"/></svg>
                  <span>Edit profile</span>
                </Link>
                <Link to="/order-history" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14,2 14,8 20,8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10,9 9,9 8,9"/></svg>
                  <span>Orders</span>
                </Link>
              </>
            )}
            {user && (
              <button onClick={() => signOut()} className="text-sm text-red-300 hover:text-red-200 transition-colors">Sign out</button>
            )}
          </nav>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="md:hidden p-2 text-white hover:text-light-white transition-colors"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              {isMobileMenuOpen ? (
                <path d="M18 6L6 18M6 6l12 12"/>
              ) : (
                <path d="M3 12h18M3 6h18M3 18h18"/>
              )}
            </svg>
          </button>
        </div>

        {/* Mobile Dropdown Menu */}
        {isMobileMenuOpen && (
          <div className="md:hidden bg-gradient-card-pink border-t border-pink-30 backdrop-blur-md">
            <div className="px-4 py-4 space-y-3">
              <Link 
                to="/" 
                className="flex items-center gap-3 text-white hover:text-light-white transition-colors py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9.5L12 3l9 6.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1V9.5z"/></svg>
                <span>Home</span>
              </Link>
              <Link 
                to="/browse" 
                className="flex items-center gap-3 text-white hover:text-light-white transition-colors py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                <span>Discover</span>
              </Link>
              <Link 
                to="/plans" 
                className="flex items-center gap-3 text-white hover:text-light-white transition-colors py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7l9-4 9 4-9 4-9-4z"/><path d="M21 7v6l-9 4-9-4V7"/></svg>
                <span>Plans</span>
              </Link>
              {!user && (
                <Link 
                  to="/login" 
                  className="flex items-center gap-3 text-white hover:text-light-white transition-colors py-2"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                  <span>Sign In</span>
                </Link>
              )}
              {user && (
                <Link 
                  to="/profile/edit" 
                  className="flex items-center gap-3 text-white hover:text-light-white transition-colors py-2"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.24 12.24l-8.48 8.48H7v-4.76l8.48-8.48z"/><path d="M18 2l4 4"/></svg>
                  <span>Edit profile</span>
                </Link>
              )}
              {user && (
                <button 
                  onClick={() => {
                    signOut()
                    setIsMobileMenuOpen(false)
                  }} 
                  className="flex items-center gap-3 text-red-300 hover:text-red-200 transition-colors py-2 w-full text-left"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16,17 21,12 16,7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                  <span>Sign out</span>
                </button>
              )}
            </div>
          </div>
        )}
      </header>
      )}

      <Routes>
        {/* Admin routes - no header/footer */}
        <Route path="/admin/*" element={
          <Routes>
            <Route path="/" element={<ProtectedRoute adminRequired={true}><Admin /></ProtectedRoute>} />
            <Route path="/subscriptions" element={<ProtectedRoute adminRequired={true}><AdminSubscriptions /></ProtectedRoute>} />
            <Route path="/subscription-plans" element={<ProtectedRoute adminRequired={true}><SubscriptionPlansAdmin /></ProtectedRoute>} />
            <Route path="/offers" element={<ProtectedRoute adminRequired={true}><OffersAdmin /></ProtectedRoute>} />
            <Route path="/embed" element={<AdminEmbed />} />
            <Route path="/dashboard" element={<AdminDashboard />} />
          </Routes>
        } />
        
        {/* Main app routes - with header/footer */}
        <Route path="/*" element={
          <>
            <main className="w-full px-4 sm:px-6 md:px-8 xl:px-12 py-4">
              <PremiumStatusWidget />
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/login" element={<Login />} />
                <Route path="/auth/phone" element={<PhoneOtp />} />
                <Route path="/auth/magic" element={<MagicLinkVerify />} />
                <Route path="/signup" element={<SignUp />} />
                <Route path="/signin" element={<SignIn />} />
                <Route path="/auth/verify-email" element={<EmailCodeVerify />} />
                <Route path="/stories" element={<ProtectedRoute><Stories /></ProtectedRoute>} />
                <Route path="/story/:id" element={<ProtectedRoute><StoryDetail /></ProtectedRoute>} />
                <Route path="/profile/:id" element={<ProtectedRoute><ProfileDetail /></ProtectedRoute>} />
                <Route path="/profile/edit" element={<ProtectedRoute><ProfileEdit /></ProtectedRoute>} />
                <Route path="/plans" element={<Plans />} />
                <Route path="/premium-plans" element={<PremiumPlans />} />
                <Route path="/payment-test" element={<PaymentTest />} />
                <Route path="/order-history" element={<ProtectedRoute><OrderHistory /></ProtectedRoute>} />
                {/* Profile setup wizard */}
                <Route path="/profile/setup/1" element={<ProtectedRoute><Step1Gender /></ProtectedRoute>} />
                <Route path="/profile/setup/2" element={<ProtectedRoute><Step2Basic /></ProtectedRoute>} />
                <Route path="/profile/setup/3" element={<ProtectedRoute><Step3Photos /></ProtectedRoute>} />
                <Route path="/profile/setup/4" element={<ProtectedRoute><Step4Bio /></ProtectedRoute>} />
                <Route path="/profile/setup/5" element={<ProtectedRoute><Step5Interests /></ProtectedRoute>} />
                <Route path="/profile/setup/6" element={<ProtectedRoute><Step6Location /></ProtectedRoute>} />
                <Route path="/browse" element={<ProtectedRoute><RequireProfile><Profiles /></RequireProfile></ProtectedRoute>} />
                <Route path="/community-guidelines" element={<CommunityGuidelines />} />
                <Route path="/safety-tips" element={<SafetyTips />} />
                <Route path="/cookie-policy" element={<CookiePolicy />} />
                <Route path="/contact-us" element={<ContactUs />} />
                <Route path="/about-us" element={<AboutUs />} />
                <Route path="/accessibility" element={<Accessibility />} />
                <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                <Route path="/terms-of-service" element={<TermsOfService />} />
                <Route path="/refund-policy" element={<RefundPolicy />} />
                <Route path="/careers" element={<Careers />} />
                <Route path="/press" element={<Press />} />
                <Route path="/blog" element={<Blog />} />
              </Routes>
            </main>
            <Footer />
          </>
        } />
      </Routes>
    </div>
  )
}


