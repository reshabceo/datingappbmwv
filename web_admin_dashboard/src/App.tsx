import React, { useState, useEffect, Suspense, lazy } from 'react'
import { Routes, Route, Link, useLocation } from 'react-router-dom'

// GTM tracking for page views
declare global {
  interface Window {
    dataLayer: any[];
    gtag: (...args: any[]) => void;
  }
}
import { WelcomeEmailService } from './services/welcomeEmailService'
import { useAuth } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Footer from './components/Footer'
import RequireProfile from './components/RequireProfile'
import StoryViewer from './components/StoryViewer'
import { Toaster } from 'sonner'

const Login = lazy(() => import('./pages/Login'))
const Profiles = lazy(() => import('./pages/Profiles'))
const Home = lazy(() => import('./pages/Home'))
const ProfileDetail = lazy(() => import('./pages/ProfileDetail'))
const PhoneOtp = lazy(() => import('./pages/Auth/PhoneOtp'))
const MagicLinkVerify = lazy(() => import('./pages/Auth/MagicLinkVerify'))
const SignUp = lazy(() => import('./pages/Auth/SignUp'))
const SignIn = lazy(() => import('./pages/Auth/SignIn'))
const EmailCodeVerify = lazy(() => import('./pages/Auth/EmailCodeVerify'))
const Stories = lazy(() => import('./pages/Stories'))
const StoryDetail = lazy(() => import('./pages/StoryDetail'))
const ProfileEdit = lazy(() => import('./pages/ProfileEdit'))
const Plans = lazy(() => import('./pages/Plans'))
const PremiumPlans = lazy(() => import('./pages/PremiumPlans'))
const PaymentTest = lazy(() => import('./pages/PaymentTest'))
const OrderHistory = lazy(() => import('./pages/OrderHistory'))
const PaymentSuccess = lazy(() => import('./pages/PaymentSuccess'))
const InvoiceTest = lazy(() => import('./pages/InvoiceTest'))
const PDFTest = lazy(() => import('./pages/PDFTest'))
const AdminSubscriptions = lazy(() => import('./pages/AdminSubscriptions'))
const Step1Gender = lazy(() => import('./pages/ProfileSetup/Step1Gender'))
const Step2Basic = lazy(() => import('./pages/ProfileSetup/Step2Basic'))
const Step3Photos = lazy(() => import('./pages/ProfileSetup/Step3Photos'))
const Step4Bio = lazy(() => import('./pages/ProfileSetup/Step4Bio'))
const Step5Interests = lazy(() => import('./pages/ProfileSetup/Step5Interests'))
const Step6Location = lazy(() => import('./pages/ProfileSetup/Step6Location'))
const AdminEmbed = lazy(() => import('./pages/AdminEmbed'))
const AdminDashboard = lazy(() => import('./pages/AdminDashboard'))
const CommunityGuidelines = lazy(() => import('./pages/CommunityGuidelines'))
const SafetyTips = lazy(() => import('./pages/SafetyTips'))
const CookiePolicy = lazy(() => import('./pages/CookiePolicy'))
const ContactUs = lazy(() => import('./pages/ContactUs'))
const AboutUs = lazy(() => import('./pages/AboutUs'))
const VerificationScreen = lazy(() => import('./pages/VerificationScreen'))
const AdminVerification = lazy(() => import('./pages/AdminVerification'))
const Accessibility = lazy(() => import('./pages/Accessibility'))
const PrivacyPolicy = lazy(() => import('./pages/PrivacyPolicy'))
const TermsOfService = lazy(() => import('./pages/TermsOfService'))
const RefundPolicy = lazy(() => import('./pages/RefundPolicy'))
const Careers = lazy(() => import('./pages/Careers'))
const Press = lazy(() => import('./pages/Press'))
const Blog = lazy(() => import('./pages/Blog'))
const EarlyAccessThankYou = lazy(() => import('./pages/EarlyAccessThankYou'))
const SubscriptionPlansAdmin = lazy(() => import('./pages/admin/SubscriptionPlansAdmin'))
const OffersAdmin = lazy(() => import('./pages/admin/OffersAdmin'))
const ReportsManagement = lazy(() => import('./admin-components/ReportsManagement'))
const PremiumStatusWidget = lazy(() => import('./components/PremiumStatusWidget'))

const PageLoader = () => (
  <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-gradient-to-b from-[#05020e] to-[#140524] text-white">
    <img
      src="/assets/5347d249-47bc-4b25-8053-83255e59a1f0.png"
      alt="Love Bug"
      className="h-12 w-auto animate-bounce"
      loading="lazy"
    />
    <p className="text-base font-semibold tracking-wide">Finding your perfect match…</p>
  </div>
)

export default function App() {
  const { user, signOut } = useAuth()
  const location = useLocation()
  const isAdminRoute = location.pathname.startsWith('/admin')
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  // Initialize welcome email service without blocking initial render
  useEffect(() => {
    let idleId: number | null = null
    let timeoutId: ReturnType<typeof setTimeout> | null = null

    const startService = () => {
      WelcomeEmailService.startProcessing()
    }

    const win = typeof window !== 'undefined'
      ? (window as Window & {
          requestIdleCallback?: (callback: IdleRequestCallback, options?: IdleRequestOptions) => number
          cancelIdleCallback?: (handle: number) => void
        })
      : null

    if (win?.requestIdleCallback) {
      idleId = win.requestIdleCallback(() => startService(), { timeout: 4000 })
    } else {
      timeoutId = setTimeout(startService, 2000)
    }
    
    return () => {
      if (idleId !== null && win?.cancelIdleCallback) {
        win.cancelIdleCallback(idleId)
      }
      if (timeoutId) {
        clearTimeout(timeoutId)
      }
      WelcomeEmailService.stopProcessing()
    }
  }, [])

  // GTM page view tracking for React Router
  useEffect(() => {
    // Small delay to ensure page is fully loaded
    const timer = setTimeout(() => {
      // Track page view for GTM
      if (typeof window !== 'undefined' && window.dataLayer) {
        window.dataLayer.push({
          event: 'page_view',
          page_path: location.pathname + location.search,
          page_title: document.title,
          page_location: window.location.href
        })
      }
    }, 100)
    
    return () => clearTimeout(timer)
  }, [location])

  return (
    <div className="min-h-screen font-app">
      <Toaster 
        richColors 
        position="bottom-right" 
        theme="dark"
        toastOptions={{
          duration: 3500,
          classNames: {
            toast: 'rounded-2xl bg-gradient-to-r from-pink-500/90 to-purple-600/90 text-white border border-pink-400/30 shadow-2xl backdrop-blur-sm px-6 py-4 text-lg flex items-center gap-3 whitespace-nowrap min-w-fit max-w-[calc(100vw-2rem)]',
            title: 'text-white font-semibold text-lg',
            description: 'text-white',
            icon: 'text-red-400 flex-shrink-0',
            actionButton: 'bg-white/15 hover:bg-white/25 text-white border border-white/20 rounded-lg text-sm px-3 py-2',
            cancelButton: 'bg-transparent hover:bg-white/10 text-white border border-white/20 rounded-lg text-sm px-3 py-2'
          }
        }}
      />
      <Suspense fallback={<PageLoader />}>
        {!isAdminRoute && (
        <header className="sticky top-0 z-50 bg-gradient-card-pink backdrop-blur border-b border-pink-30">
        <div className="w-full px-4 sm:px-6 md:px-8 xl:px-12 py-3 flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2">
            <img src="/assets/images/logolight.png" alt="Love Bug Logo" className="h-10 sm:h-12 w-auto" loading="lazy" decoding="async" />
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
                {/* <Link to="/invoice-test" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                  <span>Invoice Test</span>
                </Link>
                <Link to="/pdf-test" className="inline-flex items-center gap-2 text-sm hover:text-light-white transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14,2 14,8 20,8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10,9 9,9 8,9"/></svg>
                  <span>PDF Test</span>
                </Link> */}
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
            <Route path="/" element={<AdminDashboard />} />
            <Route path="/dashboard" element={<AdminDashboard />} />
            <Route path="/subscriptions" element={<ProtectedRoute adminRequired={true}><AdminSubscriptions /></ProtectedRoute>} />
            <Route path="/subscription-plans" element={<ProtectedRoute adminRequired={true}><SubscriptionPlansAdmin /></ProtectedRoute>} />
            <Route path="/offers" element={<ProtectedRoute adminRequired={true}><OffersAdmin /></ProtectedRoute>} />
            <Route path="/reports" element={<ProtectedRoute adminRequired={true}><ReportsManagement /></ProtectedRoute>} />
            <Route path="/verification" element={<ProtectedRoute adminRequired={true}><AdminVerification /></ProtectedRoute>} />
            <Route path="/embed" element={<AdminEmbed />} />
          </Routes>
        } />
        
        {/* Main app routes - with header/footer */}
        <Route path="/*" element={
          <>
            <main className="w-full px-4 sm:px-6 md:px-8 xl:px-12 py-4">
              <Suspense fallback={null}>
                <PremiumStatusWidget />
              </Suspense>
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
                <Route path="/verification" element={<ProtectedRoute><VerificationScreen /></ProtectedRoute>} />
                <Route path="/plans" element={<Plans />} />
                <Route path="/premium-plans" element={<PremiumPlans />} />
                <Route path="/payment-test" element={<PaymentTest />} />
                <Route path="/invoice-test" element={<InvoiceTest />} />
                <Route path="/pdf-test" element={<PDFTest />} />
                <Route path="/order-history" element={<ProtectedRoute><OrderHistory /></ProtectedRoute>} />
                <Route path="/payment/success" element={<PaymentSuccess />} />
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
                <Route path="/thank-you" element={<EarlyAccessThankYou />} />
              </Routes>
            </main>
            <Footer />
          </>
        } />
      </Routes>
      </Suspense>
    </div>
  )
}


