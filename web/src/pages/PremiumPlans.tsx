import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import GlassCardPink from '../components/ui/GlassCardPink'
import PinkGradientButton from '../components/ui/PinkGradientButton'
import { subscriptionPlansService, PlanWithPricing } from '../services/subscriptionPlans'
import { PaymentService } from '../services/paymentService'
import { useAuth } from '../context/AuthContext'
import { Crown, Star, Zap, CheckCircle, ArrowLeft } from 'lucide-react'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
const supabase = createClient(supabaseUrl, supabaseAnonKey)

function CheckItem({ children, muted = false }: { children: React.ReactNode; muted?: boolean }) {
  return (
    <li className={`flex items-start gap-2 ${muted ? 'text-light-white' : 'text-white'}`}>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={`${muted ? 'opacity-50' : ''} mt-0.5`}>
        <polyline points="20 6 9 17 4 12" />
      </svg>
      <span className={`${muted ? 'opacity-70' : ''}`}>{children}</span>
    </li>
  )
}

export default function PremiumPlans() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [plans, setPlans] = useState<PlanWithPricing[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedDuration, setSelectedDuration] = useState<number | null>(null)
  const [isProcessingPayment, setIsProcessingPayment] = useState(false)

  // UI-only overrides to ensure the display matches client-approved pricing
  const uiPricingOverrides: Record<number, { original: number; price: number; discountPct: number; savings: number }> = {
    1: { original: 2000, price: 1500, discountPct: 25, savings: 500 },
    3: { original: 4500, price: 2250, discountPct: 50, savings: 2250 },
    6: { original: 9000, price: 3600, discountPct: 60, savings: 5400 },
  }

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        setLoading(true)
        setError(null)
        
        // Initialize payment service
        await PaymentService.initialize()
        
        const plansData = await subscriptionPlansService.getPlansWithPricing()
        setPlans(plansData)
        
        // Set first paid plan as selected by default
        const firstPaidPlan = plansData.find(plan => plan.name !== 'Free')
        if (firstPaidPlan) {
          setSelectedDuration(1) // Default to 1 month
        }
      } catch (error) {
        console.error('Error fetching plans:', error)
        setError('Failed to load subscription plans. Using default plans.')
        // Fallback to static plans if database fails
        setPlans([
          {
            id: 'premium-static',
            name: 'Premium',
            description: 'Unlock all features',
            price_monthly: 2000,
            price_yearly: 5000,
            features: ['Everything in Free', 'See who liked you', 'Priority visibility', 'Advanced filters', 'Read receipts', 'Unlimited matches', 'Super likes', 'Profile boost'],
            is_active: true,
            sort_order: 2,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            pricing_options: [
              {
                id: 'premium-1m',
                plan_id: 'premium-static',
                duration_months: 1,
                price: 1500,
                original_price: 2000,
                discount_percentage: 25,
                is_popular: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-3m',
                plan_id: 'premium-static',
                duration_months: 3,
                price: 2250,
                original_price: 4500,
                discount_percentage: 50,
                is_popular: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-6m',
                plan_id: 'premium-static',
                duration_months: 6,
                price: 3600,
                original_price: 9000,
                discount_percentage: 60,
                is_popular: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              }
            ]
          }
        ])
        setSelectedDuration(1)
      } finally {
        setLoading(false)
      }
    }

    fetchPlans()
  }, [])

  const handlePayment = async (planType: string) => {
    if (!user) {
      alert('Please login first')
      return
    }

    try {
      setIsProcessingPayment(true)
      
      // Get user profile for name
      const { data: profile } = await supabase
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single()

      const userName = profile?.name || 'User'
      const userEmail = user.email || ''

      console.log('Initiating payment for:', planType, userName, userEmail)
      
      await PaymentService.initiatePayment(planType, userEmail, userName)
      
      // Add timeout to reset processing state if modal doesn't open
      setTimeout(() => {
        setIsProcessingPayment(false)
      }, 5000)
      
    } catch (error) {
      console.error('Error initiating payment:', error)
      alert('Failed to initiate payment: ' + error.message)
      setIsProcessingPayment(false)
    }
  }

  const premiumPlan = plans.find(plan => plan.name === 'Premium')

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-pink border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/70 text-lg">Loading plans...</p>
        </div>
      </div>
    )
  }

  if (error) {
    console.log('Plans page error:', error)
  }

  return (
    <div className="min-h-screen">
      {/* Header */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-12 sm:py-16 md:py-20">
          <button 
            onClick={() => navigate('/plans')}
            className="text-pink-300 hover:text-pink-200 text-sm mb-6 flex items-center gap-2"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Plans
          </button>
          
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-white">Choose Your Premium Plan</h1>
          <p className="text-light-white mt-3 max-w-2xl text-sm sm:text-base">Select the duration that works best for you. All plans include our pre-launch discount!</p>
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>

      {/* Premium Plan Options */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-8 sm:py-12">
          {premiumPlan && (
            <div className="max-w-4xl mx-auto">
              {/* Premium Features */}
              <div className="mb-8">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-8 h-8 bg-gradient-to-r from-pink to-purple rounded-full flex items-center justify-center">
                    <Crown className="w-4 h-4 text-white" />
                  </div>
                  <h2 className="text-2xl font-bold text-white">Premium Features</h2>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <ul className="space-y-3">
                    {premiumPlan.features.slice(0, 4).map((feature, index) => (
                      <CheckItem key={index}>
                        {feature}
                      </CheckItem>
                    ))}
                  </ul>
                  <ul className="space-y-3">
                    {premiumPlan.features.slice(4).map((feature, index) => (
                      <CheckItem key={index + 4}>
                        {feature}
                      </CheckItem>
                    ))}
                  </ul>
                </div>
              </div>

              {/* Duration Options */}
              <div className="space-y-6">
                <div className="text-center">
                  <h3 className="text-xl font-bold text-white mb-2">Choose Your Duration</h3>
                  <p className="text-sm text-light-white">All plans include pre-launch discount</p>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  {premiumPlan.pricing_options?.map((option) => {
                    const override = uiPricingOverrides[option.duration_months]
                    const displayPrice = override ? override.price : option.price
                    const discountLine = override
                      ? `${override.discountPct}% discount with savings of ${subscriptionPlansService.formatPrice(override.savings)}`
                      : ''

                    return (
                      <div
                        key={option.id}
                        className={`relative p-6 rounded-xl border-2 cursor-pointer transition-all bg-gradient-to-b from-white/5 to-transparent ${
                          selectedDuration === option.duration_months ? 'border-pink/50 shadow-lg shadow-pink-500/20' : 'border-white/20 hover:border-pink/30 hover:shadow-md hover:shadow-pink-500/10 hover:-translate-y-0.5'
                        } ${option.is_popular ? 'ring-2 ring-pink-400/40' : ''}`}
                        onClick={() => setSelectedDuration(option.duration_months)}
                      >
                        {/* Popular Badge */}
                        {option.is_popular && (
                          <div className="absolute -top-3 right-4 bg-gradient-to-r from-pink to-purple text-white text-xs font-bold px-3 py-1 rounded-full shadow-md">
                            ⭐ Most Popular
                          </div>
                        )}
                        
                        {/* Plan Card Content */}
                        <div className="text-center">
                          <div className="text-4xl font-bold text-white mb-2">
                            {subscriptionPlansService.formatPrice(displayPrice)}
                          </div>
                          {override && (
                            <div className="text-lg mb-2" style={{ color: '#ec4899', textDecoration: 'line-through' }}>
                              {subscriptionPlansService.formatPrice(override.original)}
                            </div>
                          )}
                          <div className="text-white font-semibold mb-2 text-lg">
                            {option.duration_months}-Month Plan
                          </div>
                          <div className="text-green-300 text-sm">
                            {discountLine}
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>

                {/* Main Action Button */}
                <div className="text-center mt-8">
                  <PinkGradientButton 
                    className="px-12 py-4 rounded-xl text-lg font-semibold"
                    onClick={() => {
                      if (selectedDuration) {
                        handlePayment(`${selectedDuration}_month`)
                      } else {
                        alert('Please select a plan duration')
                      }
                    }}
                    disabled={isProcessingPayment || !selectedDuration}
                  >
                    {isProcessingPayment ? 'Processing...' : selectedDuration ? `Upgrade to ${selectedDuration}-Month Premium` : 'Select a Plan First'}
                  </PinkGradientButton>
                  
                  {isProcessingPayment && (
                    <div className="mt-4">
                      <button
                        onClick={() => setIsProcessingPayment(false)}
                        className="text-pink-300 hover:text-pink-200 text-sm underline"
                      >
                        Cancel / Reset
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>
    </div>
  )
}
