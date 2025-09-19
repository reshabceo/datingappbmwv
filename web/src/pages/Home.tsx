import React from 'react'
import { Link } from 'react-router-dom'
import PinkGradientButton from '../components/ui/PinkGradientButton'
import GlassCardPink from '../components/ui/GlassCardPink'

type SectionProps = { children: React.ReactNode; className?: string; id?: string; innerClass?: string }
const Section: React.FC<SectionProps> = ({ children, className = '', id, innerClass = '' }) => (
  <section id={id} className={`w-full ${className}`}>
    <div className={`max-w-[1800px] 2xl:max-w-[1920px] mx-auto px-8 xl:px-12 py-20 md:py-24 ${innerClass}`}>
      {children}
    </div>
    <div className="w-screen relative left-1/2 -translate-x-1/2 border-t border-border-white-10" />
  </section>
)

export default function Home() {
  const features = [
    {
      title: 'Smart Matching',
      text: 'Our AI-powered algorithm ensures you meet people who truly match your interests and values.',
      emoji: '✨',
    },
    {
      title: 'Safe & Secure',
      text: 'Your privacy and security are our top priority. Feel safe while finding your perfect match.',
      emoji: '🛡️',
    },
    {
      title: 'Meaningful Connections',
      text: 'Build genuine relationships based on shared interests and compatibility.',
      emoji: '💬',
    },
  ]

  const stories = [
    {
      img: '/assets/d83d12e7-0a5f-4215-a0df-b60f86de7707.JPG',
      title: 'Adam & Aaliya',
      quote:
        "\"Love Bug helped us find each other when we least expected it. Now we're planning our wedding!\"",
    },
    {
      img: '/assets/cd2a694f-ba7e-4bc9-acb6-555f0ecc9f71.JPG',
      title: 'Gurpreet & Simran',
      quote:
        '"We matched on Love Bug and instantly connected. Six months later, we\'re moving in together!"',
    },
    {
      img: '/assets/986045b9-9a2a-47ed-b970-2cec35b53359.JPG',
      title: 'Vihaan & Lakshmi',
      quote:
        '"The algorithm is amazing! We have so much in common and couldn\'t be happier together."',
    },
  ]

  const premium = [
    { title: 'Priority Matching', text: 'Get shown to more potential matches', emoji: '⭐' },
    { title: 'Advanced Messaging', text: 'Send voice notes and video messages', emoji: '💬' },
    { title: 'See Who Likes You', text: 'Browse your admirers instantly', emoji: '👀' },
    { title: 'Premium Badge', text: 'Stand out from the crowd', emoji: '👑' },
  ]

  return (
    <div className="text-white">
      {/* Hero */}
      <Section innerClass="min-h-[calc(100vh-72px)] flex items-center">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div>
            <h1 className="text-5xl md:text-6xl xl:text-7xl font-bold leading-tight">
              Find Your Perfect Match
              <br />
              <span className="text-light-pink">With Love Bug</span>
            </h1>
            <p className="mt-5 text-light-white max-w-3xl text-lg md:text-xl">
              Experience modern dating with a touch of magic. Connect with like-minded individuals and
              start your journey to meaningful relationships.
            </p>
            <div className="mt-9 flex gap-4">
              <Link to="/browse">
                <PinkGradientButton className="px-8 py-4 text-base">Start Matching Now</PinkGradientButton>
              </Link>
              <a href="#why-choose" className="px-7 py-4 rounded-full bg-white/10 border border-border-white-10">Learn More</a>
            </div>
          </div>
          <div className="flex items-center justify-center">
            <div className="w-[32rem] h-[20rem] rounded-3xl overflow-hidden shadow-2xl bg-white/10 border border-border-white-10">
              <img src="/assets/5eab84d3-8fdc-40ac-87cb-1609d42f5228.JPG" alt="Happy couple" className="w-full h-full object-cover" />
            </div>
          </div>
        </div>
      </Section>

      {/* Why Choose */}
      <Section id="why-choose">
        <h2 className="text-4xl font-bold mb-10">Why Choose <span className="text-light-pink">Love Bug</span></h2>
        <div className="grid md:grid-cols-3 gap-8">
          {features.map((f) => (
            <GlassCardPink key={f.title} className="p-7">
              <div className="text-3xl mb-3">{f.emoji}</div>
              <div className="text-2xl font-semibold mb-2">{f.title}</div>
              <p className="text-light-white text-base">{f.text}</p>
            </GlassCardPink>
          ))}
        </div>
      </Section>

      {/* Success Stories */}
      <Section>
        <h2 className="text-4xl font-bold mb-10">Success Stories</h2>
        <div className="grid md:grid-cols-3 gap-8">
          {stories.map((s) => (
            <div key={s.title} className="rounded-2xl overflow-hidden bg-gradient-card-pink border border-pink-30 backdrop-blur-md">
              <div className="h-72 bg-black/20">
                <img src={s.img} alt={s.title} className="w-full h-full object-cover object-[center_20%]" />
              </div>
              <div className="p-5">
                <div className="font-semibold text-xl mb-2">{s.title}</div>
                <p className="text-light-white text-base leading-relaxed">{s.quote}</p>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* App Download Section */}
      <Section>
        <div className="rounded-2xl p-6 md:p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md">
          <div className="grid md:grid-cols-2 gap-8 items-center">
            <div>
              <h3 className="text-2xl md:text-3xl font-bold mb-3 text-white">Take Love On The Go</h3>
              <p className="text-light-white mb-5 text-base">
                Download our mobile app and find love anywhere, anytime. Get exclusive features and instant notifications when someone likes you.
              </p>
                <div className="flex flex-col sm:flex-row gap-3">
                  <button className="px-5 py-3 bg-gradient-to-r from-pink-500 to-purple-500 border border-pink-300 rounded-xl text-white font-semibold hover:from-pink-600 hover:to-purple-600 transition-all duration-300 flex items-center justify-center gap-2 shadow-lg text-sm">
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M3.609 1.814L13.792 12L3.609 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.198l2.807 1.626a1 1 0 0 1 0 1.73l-2.808 1.626L13.5 12l4.199-2.491zM5.864 2.658L16.802 8.99l-2.302 2.302-8.636-8.634z"/>
                    </svg>
                    Get it on Google Play
                  </button>
                  <button className="px-5 py-3 bg-gradient-to-r from-pink-500 to-purple-500 border border-pink-300 rounded-xl text-white font-semibold hover:from-pink-600 hover:to-purple-600 transition-all duration-300 flex items-center justify-center gap-2 shadow-lg text-sm">
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                    </svg>
                    Download on the App Store
                  </button>
                </div>
            </div>
            <div className="flex justify-center">
              <img 
                src="/assets/c59fc0b8-2284-413f-9ed0-e97cebdddd89.png" 
                alt="Love Bug app mobile interface" 
                className="max-w-[200px] h-auto rounded-xl shadow-2xl"
                onError={(e) => {
                  console.log('Image failed to load, trying alternative path');
                  e.currentTarget.src = '/assets/c59fc0b8-2284-413f-9ed0-e97cebdddd89.png';
                }}
              />
            </div>
          </div>
        </div>
      </Section>

      {/* Premium Features */}
      <Section>
        <h2 className="text-4xl font-bold mb-10">Premium Features</h2>
        <div className="grid sm:grid-cols-2 md:grid-cols-4 gap-8">
          {premium.map((p) => (
            <GlassCardPink key={p.title} className="text-center p-7">
              <div className="text-3xl mb-3">{p.emoji}</div>
              <div className="font-semibold text-lg mb-1">{p.title}</div>
              <div className="text-light-white text-base">{p.text}</div>
            </GlassCardPink>
          ))}
        </div>
      </Section>

      {/* Newsletter */}
      <Section>
        <div className="rounded-2xl p-10 md:p-12 bg-gradient-card-pink border border-pink-30 backdrop-blur-md text-center">
          <h3 className="text-3xl md:text-4xl font-bold mb-4">Stay Updated</h3>
          <p className="text-light-white mb-7 text-lg">
            Subscribe to our newsletter for dating tips, success stories, and special offers.
          </p>
          <form
            onSubmit={(e) => {
              e.preventDefault()
              const form = e.target as HTMLFormElement
              const input = form.querySelector('input') as HTMLInputElement
              console.log('Subscribed:', input?.value)
              alert('Thanks for subscribing!')
              input.value = ''
            }}
            className="mx-auto max-w-2xl flex gap-4"
          >
            <input
              type="email"
              required
              placeholder="Enter your email"
              className="flex-1 px-5 py-4 rounded-xl bg-white/90 text-gray-800 placeholder-gray-500 text-base"
            />
            <PinkGradientButton className="rounded-xl px-6 py-4 text-base">Subscribe</PinkGradientButton>
          </form>
        </div>
      </Section>

    </div>
  )
}


