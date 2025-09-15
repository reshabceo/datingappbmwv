import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import GlassCardPink from '../components/ui/GlassCardPink'
import PinkGradientButton from '../components/ui/PinkGradientButton'
import { subscriptionPlansService, PlanWithPricing, PricingOption } from '../services/subscriptionPlans'
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
  const [plans, setPlans] = useState<PlanWithPricing[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null)

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        setLoading(true)
        setError(null)
        const plansData = await subscriptionPlansService.getPlansWithPricing()
        setPlans(plansData)
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
                price: 2000,
                original_price: 2000,
                discount_percentage: 0,
                is_popular: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-3m',
                plan_id: 'premium-static',
                duration_months: 3,
                price: 3000,
                original_price: 6000,
                discount_percentage: 50,
                is_popular: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
              },
              {
                id: 'premium-6m',
                plan_id: 'premium-static',
                duration_months: 6,
                price: 5000,
                original_price: 12000,
                discount_percentage: 58,
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
    
    return (
      <div key={plan.id} className={`relative ${isFree ? '' : 'lg:col-span-2'}`}>
        {isPopular && (
          <div className="absolute -top-3 right-4 bg-gradient-to-r from-pink to-purple text-white text-xs font-semibold px-4 py-2 rounded-full flex items-center gap-1 z-10">
            <Star className="w-3 h-3" />
            Most Popular
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
              <div className="text-3xl font-bold text-white">
                {subscriptionPlansService.formatPrice(plan.pricing_options?.[0]?.price || plan.price_monthly)}
              </div>
              <div className="text-light-white">Starting from</div>
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
              {/* Pricing Options */}
              <div className="space-y-2">
                {plan.pricing_options?.map((option) => {
                  const monthlyPrice = subscriptionPlansService.getMonthlyPrice(option.price, option.duration_months)
                  const savings = subscriptionPlansService.calculateSavings(option.price, option.original_price)
                  
                  return (
                    <div
                      key={option.id}
                      className={`p-3 rounded-xl border-2 cursor-pointer transition-all ${
                        selectedPlan === plan.id ? 'border-pink/50 bg-pink/10' : 'border-white/20 hover:border-pink/30'
                      }`}
                      onClick={() => setSelectedPlan(plan.id)}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="text-white font-semibold">
                            {option.duration_months} Month{option.duration_months > 1 ? 's' : ''}
                          </div>
                          <div className="text-light-white text-sm">
                            {subscriptionPlansService.formatPrice(monthlyPrice)}/month
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-white font-bold">
                            {subscriptionPlansService.formatPrice(option.price)}
                          </div>
                          {savings > 0 && (
                            <div className="text-green-400 text-sm font-semibold">
                              Save {savings}%
                            </div>
                          )}
                        </div>
                      </div>
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
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* Plans Grid */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {plans.map(renderPricingCard)}
          </div>
        </div>
        <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
      </section>

      {/* Feature Comparison */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-8 xl:px-12 py-16 md:py-20">
          <h3 className="text-2xl font-bold text-white mb-6">Feature Comparison</h3>
          <div className="rounded-2xl overflow-hidden bg-gradient-card-pink border border-pink-30">
            <div className="grid grid-cols-3 text-white">
              <div className="px-4 py-3 font-semibold">Features</div>
              <div className="px-4 py-3 font-semibold text-center">Free</div>
              <div className="px-4 py-3 font-semibold text-center">Premium</div>
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


