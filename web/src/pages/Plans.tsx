import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import GlassCardPink from '../components/ui/GlassCardPink'
import PinkGradientButton from '../components/ui/PinkGradientButton'
import { subscriptionPlansService, PlanWithPricing, PricingOption } from '../services/subscriptionPlans'
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
  const [plans, setPlans] = useState<PlanWithPricing[]>([])
  const [discountedPricing, setDiscountedPricing] = useState<{ [key: string]: DiscountedPricing[] }>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null)
  const [isWomenFree, setIsWomenFree] = useState(false)

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
          // For testing purposes, set to true if no user (you can remove this later)
          console.log('No user logged in, setting women free to false')
          setIsWomenFree(false)
        }
        
        // Get discounted pricing for each plan
        if (user) {
          const pricingMap: { [key: string]: DiscountedPricing[] } = {}
          for (const plan of plansData) {
            if (plan.name !== 'Free') {
              const durations = [1, 3, 6] // Standard durations
              const allPricing: DiscountedPricing[] = []
              
              for (const duration of durations) {
                try {
                  const discountedPricing = await offersService.getPricingWithOffers(
                    user.id,
                    plan.id,
                    duration
                  )
                  allPricing.push(...discountedPricing)
                } catch (err) {
                  console.error(`Error fetching offers for ${plan.name} ${duration} month:`, err)
                }
              }
              
              pricingMap[plan.id] = allPricing
            }
          }
          setDiscountedPricing(pricingMap)
        }
        
        // Set first paid plan as selected by default
        const firstPaidPlan = plansData.find(plan => plan.name !== 'Free')
        if (firstPaidPlan) {
          setSelectedPlan(firstPaidPlan.id)
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
                original_price: 3000,
                discount_percentage: 25,
                is_popular: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-6m',
                plan_id: 'premium-static',
                duration_months: 6,
                price: 3750,
                original_price: 5000,
                discount_percentage: 25,
                is_popular: false,
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
    const isPopular = plan.pricing_options?.some(option => option.is_popular) || false
    const planDiscountedPricing = discountedPricing[plan.id] || []
    
    // Check if this plan has special offers
    const hasOffers = planDiscountedPricing.some(pricing => pricing.savings > 0)
    const isWomenFreeForPlan = isWomenFree && !isFree
    
    return (
      <div key={plan.id} className="relative">
        {isPopular && (
          <div className="absolute -top-3 right-4 bg-gradient-to-r from-pink to-purple text-white text-xs font-semibold px-4 py-2 rounded-full flex items-center gap-1 z-10">
            <Star className="w-3 h-3" />
            Most Popular
          </div>
        )}
        
        {/* Pre-launch Offer Banner */}
        {!isFree && (
          <div className="absolute -top-3 left-4 bg-gradient-to-r from-orange-500 to-red-500 text-white text-xs font-bold px-4 py-2 rounded-full flex items-center gap-1 z-10 shadow-lg animate-bounce">
            🚀 PRE-LAUNCH OFFER
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
          ) : (
            <div className="mb-6">
              <div className="flex items-baseline gap-2">
                <div className="text-3xl font-bold text-white">
                  {subscriptionPlansService.formatPrice(plan.pricing_options?.[0]?.price || plan.price_monthly)}
                </div>
                {plan.pricing_options?.[0]?.original_price && (
                  <div className="text-lg text-gray-400 line-through">
                    {subscriptionPlansService.formatPrice(plan.pricing_options[0].original_price)}
                  </div>
                )}
              </div>
              <div className="text-light-white">Starting from</div>
              {hasOffers && (
                <div className="mt-2 text-sm text-green-300 font-semibold">
                  🚀 Pre-launch Discount - Save {subscriptionPlansService.formatPrice((plan.pricing_options?.[0]?.original_price || 0) - (plan.pricing_options?.[0]?.price || 0))}!
                </div>
              )}
            </div>
          )}

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
              {/* Pricing Options - Horizontal Layout */}
              <div className="grid grid-cols-3 gap-2">
                {plan.pricing_options?.map((option) => {
                  const monthlyPrice = subscriptionPlansService.getMonthlyPrice(option.price, option.duration_months)
                  const savings = subscriptionPlansService.calculateSavings(option.price, option.original_price)
                  
                  // Find discounted pricing for this option
                  const discountedOption = planDiscountedPricing.find(
                    dp => dp.duration_months === option.duration_months
                  )
                  
                  const displayPrice = discountedOption?.discounted_price || option.price
                  const displayMonthlyPrice = subscriptionPlansService.getMonthlyPrice(displayPrice, option.duration_months)
                  const totalSavings = discountedOption?.savings || 0
                  
                  return (
                    <div
                      key={option.id}
                      className={`p-3 rounded-lg border-2 cursor-pointer transition-all text-center ${
                        selectedPlan === plan.id ? 'border-pink/50 bg-pink/10' : 'border-white/20 hover:border-pink/30'
                      } ${option.is_popular ? 'ring-2 ring-pink-400/50' : ''}`}
                      onClick={() => setSelectedPlan(plan.id)}
                    >
                      <div className="text-white font-semibold text-sm mb-1">
                        {option.duration_months}M
                      </div>
                      <div className="text-white font-bold text-lg">
                        {subscriptionPlansService.formatPrice(displayPrice)}
                      </div>
                      <div className="text-light-white text-xs">
                        {subscriptionPlansService.formatPrice(displayMonthlyPrice)}/mo
                      </div>
                      {savings > 0 && (
                        <div className="text-green-400 text-xs font-semibold mt-1">
                          Save {subscriptionPlansService.formatPrice(option.original_price - option.price)}
                        </div>
                      )}
                      {option.is_popular && (
                        <div className="text-xs text-pink-400 font-semibold mt-1">
                          ⭐ Popular
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>

              <PinkGradientButton 
                className="w-full rounded-xl py-3"
                onClick={() => alert('Checkout integration coming soon')}
              >
                Upgrade to {plan.name}
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
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <h1 className="text-4xl md:text-5xl font-bold text-white">Choose Your Plan</h1>
          <p className="text-light-white mt-3 max-w-2xl">Upgrade anytime. Cancel anytime. Try Free or unlock Premium for the full experience.</p>
          
          {/* Special Women's Offer Banner */}
          {isWomenFree && (
            <div className="mt-8 bg-gradient-to-r from-pink-500/20 to-purple-500/20 border border-pink-400/30 rounded-2xl p-6 text-center">
              <div className="text-2xl font-bold bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent mb-2">
                👑 Special Offer for Women!
              </div>
              <p className="text-white text-lg">
                Get <span className="font-bold text-pink-300">FREE Premium access</span> during our pre-launch period
              </p>
              <p className="text-pink-200 text-sm mt-2">
                All Premium features • No payment required • Limited time offer
              </p>
            </div>
          )}
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* Plans Grid */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-12">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {plans.map(renderPricingCard)}
          </div>
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* Women's Free Section */}
      {(isWomenFree || true) && (
        <section className="w-full">
          <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-8">
            <div className="max-w-6xl mx-auto">
              <div className="relative">
                  <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-gradient-to-r from-pink-500 to-purple-500 text-white text-sm font-bold px-6 py-2 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer z-20 border-2 border-pink-300 backdrop-blur-sm bg-opacity-90">
                    <div className="bg-gradient-to-r from-pink-600/20 to-purple-600/20 rounded-full px-4 py-1 -m-1">
                      👑 FREE FOR WOMEN
                    </div>
                  </div>
                
                <GlassCardPink className="border border-pink-30">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-gradient-to-r from-pink to-purple rounded-full flex items-center justify-center">
                        <Crown className="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 className="text-2xl font-bold text-white">
                          Free for Women
                        </h3>
                        <p className="text-white text-sm mb-2">Women enjoy all Premium features at no cost</p>
                        <div className="flex items-center gap-4 text-xs text-pink-300">
                          <span className="flex items-center gap-1 text-white">
                            <CheckCircle className="w-3 h-3 text-pink-300" />
                            Unlimited Swipes
                          </span>
                          <span className="flex items-center gap-1 text-white">
                            <CheckCircle className="w-3 h-3 text-pink-300" />
                            See Who Likes You
                          </span>
                          <span className="flex items-center gap-1 text-white">
                            <CheckCircle className="w-3 h-3 text-pink-300" />
                            Priority Matching
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="text-right">
                      <div className="text-4xl font-bold text-white">
                        FREE
                      </div>
                      <div className="text-white text-sm mb-1">Always Free for Women</div>
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
          <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
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
          <p className="text-light-white text-xs mt-8">Payments are powered by Stripe/Razorpay. You can cancel anytime.</p>
        </div>
      </section>
    </div>
  )
}


