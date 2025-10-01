import React, { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import GlassCardPink from '../components/ui/GlassCardPink'
import PinkGradientButton from '../components/ui/PinkGradientButton'
import { subscriptionPlansService, PlanWithPricing } from '../services/subscriptionPlans'
import { offersService, DiscountedPricing } from '../services/offersService'
import { useAuth } from '../context/AuthContext'
import { Crown, Star, Zap, CheckCircle } from 'lucide-react'

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

export default function Plans() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [plans, setPlans] = useState<PlanWithPricing[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isWomenFree, setIsWomenFree] = useState(false)

  // UI-only overrides to ensure the display matches client-approved pricing
  const uiPricingOverrides: Record<number, { original: number; price: number; discountPct: number; savings: number }> = {
    1: { original: 2, price: 1, discountPct: 50, savings: 1 }, // ₹1 for 1 month (TESTING)
    3: { original: 2, price: 1, discountPct: 50, savings: 1 },
    6: { original: 2, price: 1, discountPct: 50, savings: 1 },
  }

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        setLoading(true)
        setError(null)
        
        const plansData = await subscriptionPlansService.getPlansWithPricing()
        setPlans(plansData)
        
        // Check if user is eligible for women's free subscription
        if (user) {
          const isEligible = await offersService.isEligibleForWomenFree(user.id)
          console.log('User is eligible for women free:', isEligible)
          setIsWomenFree(isEligible)
        } else {
          setIsWomenFree(false)
        }
      } catch (error) {
        console.error('Error fetching plans:', error)
        setError('Failed to load subscription plans. Using default plans.')
        // Fallback to static plans if database fails
        setPlans([
          {
            id: 'free-static',
            name: 'Free',
            description: 'Perfect for getting started',
            price_monthly: 0,
            price_yearly: 0,
            features: ['Browse public profiles', 'View limited stories', 'Basic search filters', 'Create your profile', 'Limited matches'],
            is_active: true,
            sort_order: 1,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            pricing_options: []
          },
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
                price: 100, // ₹1 in paise (TESTING)
                original_price: 200000,
                discount_percentage: 25,
                is_popular: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-3m',
                plan_id: 'premium-static',
                duration_months: 3,
                price: 100, // ₹1 in paise (TESTING)
                original_price: 450000,
                discount_percentage: 50,
                is_popular: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-6m',
                plan_id: 'premium-static',
                duration_months: 6,
                price: 100, // ₹1 in paise (TESTING)
                original_price: 900000,
                discount_percentage: 60,
                is_popular: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              }
            ]
          }
        ])
      } finally {
        setLoading(false)
      }
    }

    fetchPlans()
  }, [])


  const renderPricingCard = (plan: PlanWithPricing) => {
    const isFree = plan.name === 'Free'
    
    return (
      <div key={plan.id} className="relative">
        {/* Pre-launch Offer Banner */}
        {!isFree && (
          <div className="absolute -top-3 left-4 bg-gradient-to-r from-orange-500 to-red-500 text-white text-xs font-bold px-4 py-2 rounded-full flex items-center gap-1 z-10 shadow-lg animate-pulse">
            🚀 Pre-Launch Offer
          </div>
        )}
        
        <GlassCardPink className="h-full">
          <div className="flex items-center gap-3 mb-4">
            {isFree ? (
              <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
                <Zap className="w-4 h-4 text-white" />
              </div>
            ) : (
              <div className="w-8 h-8 bg-gradient-to-r from-pink to-purple rounded-full flex items-center justify-center">
                <Crown className="w-4 h-4 text-white" />
              </div>
            )}
            <h2 className="text-2xl font-bold text-white">{plan.name}</h2>
          </div>

          {isFree ? (
            <div className="mb-6">
              <div className="text-3xl font-bold text-white">Free</div>
              <div className="text-light-white">Forever</div>
            </div>
          ) : null}

          <ul className="space-y-3 mb-8">
            {plan.features.map((feature, index) => (
              <CheckItem key={index} muted={false}>
                {feature}
              </CheckItem>
            ))}
          </ul>

          {isFree ? (
            <Link to="/signup">
              <PinkGradientButton className="w-full rounded-xl py-3">
                Start Free
              </PinkGradientButton>
            </Link>
          ) : (
            <div className="space-y-4">
              {/* Show the small duration cards for information */}
              <div className="space-y-3">
                <div className="text-center mb-4">
                  <h3 className="text-lg font-bold text-white mb-2">Choose Your Plan</h3>
                  <p className="text-sm text-light-white">All plans include 25% pre-launch discount</p>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {plan.pricing_options?.map((option) => {
                    const override = uiPricingOverrides[option.duration_months]
                    const displayPrice = override ? override.price : option.price
                    const discountLine = override
                      ? `${override.discountPct}% discount with savings of ${subscriptionPlansService.formatPrice(override.savings)}`
                      : ''

                    return (
                      <div
                        key={option.id}
                        className={`relative p-4 rounded-xl border-2 bg-gradient-to-b from-white/5 to-transparent ${
                          option.is_popular ? 'ring-2 ring-pink-400/40' : ''
                        } border-white/20`}
                      >
                        {/* Popular Badge */}
                        {option.is_popular && (
                          <div className="absolute -top-3 right-2 bg-gradient-to-r from-pink to-purple text-white text-[10px] font-bold px-2.5 py-1 rounded-full shadow-md">
                            ⭐ Most Popular
                          </div>
                        )}
                        
                        {/* Plan Card Content (display only) */}
                        <div className="text-center">
                          <div className="text-3xl font-bold text-white mb-1">
                            {subscriptionPlansService.formatPrice(displayPrice)}
                          </div>
                          {override && (
                            <div className="text-sm mb-1" style={{ color: '#ec4899', textDecoration: 'line-through' }}>
                              {subscriptionPlansService.formatPrice(override.original)}
                            </div>
                          )}
                          <div className="text-white font-semibold mb-1">
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
              </div>

              <PinkGradientButton 
                className="w-full rounded-xl py-3"
                onClick={() => {
                  if (!user) {
                    alert('Please login first')
                    return
                  }
                  navigate('/premium-plans')
                }}
              >
                Upgrade to Premium
              </PinkGradientButton>
            </div>
          )}
        </GlassCardPink>
      </div>
    )
  }

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
      {/* Hero */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-12 sm:py-16 md:py-20">
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-white">Choose Your Plan</h1>
          <p className="text-light-white mt-3 max-w-2xl text-sm sm:text-base">Upgrade anytime. Cancel anytime. Try Free or unlock Premium for the full experience.</p>
          
          {/* Special Women's Offer Banner */}
          {isWomenFree && (
            <div className="mt-6 sm:mt-8 bg-gradient-to-r from-pink-500/20 to-purple-500/20 border border-pink-400/30 rounded-2xl p-4 sm:p-6 text-center">
              <div className="text-xl sm:text-2xl font-bold bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent mb-2">
                👑 Special Offer for Women!
              </div>
              <p className="text-white text-base sm:text-lg">
                Get <span className="font-bold text-pink-300">FREE Premium access</span> during our pre-launch period
              </p>
              <p className="text-pink-200 text-xs sm:text-sm mt-2">
                All Premium features • No payment required • Limited time offer
              </p>
            </div>
          )}
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>

      {/* Plans Grid */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-8 sm:py-12">
          {/* Removed the top green savings banner per client request */}
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
            {plans.filter(plan => plan.name === 'Free' || plan.name === 'Premium').map(renderPricingCard)}
          </div>
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>

      {/* Women's Free Section */}
      {(isWomenFree || true) && (
        <section className="w-full">
          <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-8">
            <div className="max-w-6xl mx-auto">
              <div className="relative">
                  <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-gradient-to-r from-pink-500 to-purple-500 text-white text-xs sm:text-sm font-bold px-4 sm:px-6 py-2 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer z-20 border-2 border-pink-300 backdrop-blur-sm bg-opacity-90">
                    <div className="bg-gradient-to-r from-pink-600/20 to-purple-600/20 rounded-full px-3 sm:px-4 py-1 -m-1">
                      👑 FREE FOR WOMEN
                    </div>
                  </div>
                
                <GlassCardPink className="border border-pink-30">
                  <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 sm:gap-6">
                    <div className="flex items-center gap-3 sm:gap-4 w-full sm:w-auto">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-r from-pink to-purple rounded-full flex items-center justify-center flex-shrink-0">
                        <Crown className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h3 className="text-xl sm:text-2xl font-bold text-white">
                          Free for Women
                        </h3>
                        <p className="text-white text-xs sm:text-sm mb-2">Women enjoy all Premium features at no cost</p>
                        <div className="flex flex-wrap items-center gap-2 sm:gap-4 text-xs text-pink-300">
                          <span className="flex items-center gap-1 text-white whitespace-nowrap">
                            <CheckCircle className="w-3 h-3 text-pink-300 flex-shrink-0" />
                            Unlimited Swipes
                          </span>
                          <span className="flex items-center gap-1 text-white whitespace-nowrap">
                            <CheckCircle className="w-3 h-3 text-pink-300 flex-shrink-0" />
                            See Who Likes You
                          </span>
                          <span className="flex items-center gap-1 text-white whitespace-nowrap">
                            <CheckCircle className="w-3 h-3 text-pink-300 flex-shrink-0" />
                            Priority Matching
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="text-center sm:text-right w-full sm:w-auto">
                      <div className="text-3xl sm:text-4xl font-bold text-white">
                        FREE
                      </div>
                      <div className="text-white text-xs sm:text-sm mb-1">Always Free for Women</div>
                      <div className="text-xs text-pink-300 font-semibold">
                        Premium Features Included
                      </div>
                      <div className="mt-2 text-xs text-green-300">
                        ✨ No Payment Required
                      </div>
                    </div>
                  </div>
                </GlassCardPink>
              </div>
            </div>
          </div>
          <div className="w-full border-t border-border-white-10" />
        </section>
      )}

      {/* Feature Comparison */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <h3 className="text-2xl font-bold text-white mb-6">Feature Comparison</h3>
          <div className="rounded-2xl overflow-hidden bg-gradient-card-pink border border-pink-30">
            <div className="grid grid-cols-3 text-white">
              <div className="px-4 py-3 font-semibold">Features</div>
              <div className="px-4 py-3 font-semibold text-center">Free</div>
              <div className="px-4 py-3 font-semibold text-center">
                Premium 
                <div className="text-xs text-pink-300 font-normal">(FREE for Women!)</div>
              </div>
            </div>
            {[
              ['Profile Creation', true, true],
              ['Browse Profiles', true, true],
              ['Limited Matches', true, false],
              ['Send Messages', false, true],
              ['See Who Likes You', false, true],
              ['Advanced Filters', false, true],
              ['Priority Visibility', false, true],
              ['Read Receipts', false, true],
              ['VIP Support', false, true],
              ['Profile Verification', false, true],
            ].map(([label, free, premium], idx) => (
              <div key={String(label)} className={`grid grid-cols-3 items-center ${idx % 2 ? 'bg-white/5' : ''}`}>
                <div className="px-4 py-3 text-light-white">{label as string}</div>
                <div className="px-4 py-3 flex justify-center">
                  {free ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
                  )}
                </div>
                <div className="px-4 py-3 flex justify-center">
                  {premium ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* CTA Banner */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <div className="rounded-2xl p-10 bg-gradient-card-pink border border-pink-30 text-center">
            <h3 className="text-3xl font-bold text-white">Ready to Find Your Perfect Match?</h3>
            <p className="text-light-white mt-3">Join thousands of happy couples who found love on Love Bug.</p>
            <div className="mt-6 flex items-center justify-center gap-4">
              <PinkGradientButton className="rounded-xl px-6 py-3">Get Premium Now</PinkGradientButton>
              <a href="#" className="px-6 py-3 rounded-xl bg-white/10 border border-border-white-10 text-white">Learn More</a>
            </div>
          </div>
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* FAQ */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <h3 className="text-2xl font-bold text-white mb-6">FAQ</h3>
          <div className="grid md:grid-cols-2 gap-6">
            {[{
              q: 'Can I cancel anytime?',
              a: 'Yes, you can cancel your subscription at any time from your account settings.'
            },{
              q: 'Do you offer refunds?',
              a: 'We do not offer refunds for partial periods, but you will retain access until your term ends.'
            },{
              q: 'Will Free users lose data when upgrading?',
              a: 'No, your chats and profile stay intact. Upgrading only unlocks extra features.'
            }].map(({q,a}) => (
              <details key={q} className="rounded-xl bg-gradient-card-pink border border-pink-30 p-5">
                <summary className="cursor-pointer text-white font-semibold">{q}</summary>
                <p className="text-light-white mt-3">{a}</p>
              </details>
            ))}
          </div>
          <p className="text-light-white text-xs mt-8">Payments are powered by Cashfree. You can cancel anytime.</p>
        </div>
      </section>
    </div>
  )
}


