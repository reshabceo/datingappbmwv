import React from 'react'
import { Link } from 'react-router-dom'
import GlassCardPink from '../components/ui/GlassCardPink'
import PinkGradientButton from '../components/ui/PinkGradientButton'

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
  const freeFeatures = [
    { text: 'Browse public profiles', muted: false },
    { text: 'View limited stories', muted: false },
    { text: 'Basic search filters', muted: false },
    { text: 'See who liked you', muted: true },
    { text: 'Priority visibility', muted: true },
  ]

  const premiumFeatures = [
    { text: 'Everything in Free', muted: false },
    { text: 'See who liked you', muted: false },
    { text: 'Priority visibility', muted: false },
    { text: 'Advanced filters', muted: false },
    { text: 'Read receipts', muted: false },
  ]

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
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Free */}
            <GlassCardPink>
              <div className="flex items-baseline justify-between">
                <h2 className="text-2xl font-bold text-white">Free</h2>
                <span className="text-light-white">₹0 / month</span>
              </div>
              <ul className="mt-6 space-y-3">
                {freeFeatures.map((f) => (
                  <CheckItem key={f.text} muted={f.muted}>{f.text}</CheckItem>
                ))}
              </ul>
              <div className="mt-8">
                <Link to="/signup">
                  <PinkGradientButton className="w-full rounded-xl py-3">Start Free</PinkGradientButton>
                </Link>
              </div>
            </GlassCardPink>

            {/* Premium */}
            <div className="relative">
              <div className="absolute -top-3 right-4 bg-light-pink text-white text-xs font-semibold px-3 py-1 rounded-full">Most Popular</div>
              <GlassCardPink>
                <div className="flex items-baseline justify-between">
                  <h2 className="text-2xl font-bold text-white">Premium</h2>
                  <span className="text-light-white">₹499 / month</span>
                </div>
                <ul className="mt-6 space-y-3">
                  {premiumFeatures.map((f) => (
                    <CheckItem key={f.text} muted={f.muted}>{f.text}</CheckItem>
                  ))}
                </ul>
                <div className="mt-8">
                  <PinkGradientButton className="w-full rounded-xl py-3" onClick={() => alert('Checkout integration coming soon')}>Upgrade to Premium</PinkGradientButton>
                </div>
              </GlassCardPink>
            </div>
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


