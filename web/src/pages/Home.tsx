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
      img: '/assets/home/story1.jpg',
      title: 'Sarah & Michael',
      quote:
        "\"Love Bug helped us find each other when we least expected it. Now we're planning our wedding!\"",
    },
    {
      img: '/assets/home/story2.jpg',
      title: 'Emma & James',
      quote:
        '"We matched on Love Bug and instantly connected. Six months later, we\'re moving in together!"',
    },
    {
      img: '/assets/home/story3.jpg',
      title: 'Lisa & David',
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
          <div className="flex items-center justify-center gap-8">
            <div className="w-64 h-80 rounded-3xl overflow-hidden shadow-2xl bg-white/10 border border-border-white-10">
              <img src="/assets/home/hero-1.jpg" alt="Happy couple" className="w-full h-full object-cover" />
            </div>
            <div className="w-56 h-72 rounded-3xl overflow-hidden shadow-2xl bg-white/10 border border-border-white-10 hidden sm:block">
              <img src="/assets/home/hero-2.jpg" alt="Romantic date" className="w-full h-full object-cover" />
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
              <div className="h-56 bg-black/20">
                <img src={s.img} alt={s.title} className="w-full h-full object-cover" />
              </div>
              <div className="p-5">
                <div className="font-semibold text-xl mb-2">{s.title}</div>
                <p className="text-light-white text-base leading-relaxed">{s.quote}</p>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* App Promo */}
      <Section>
        <div className="grid md:grid-cols-2 gap-10 items-center rounded-2xl p-6 md:p-10 bg-gradient-to-r from-appbar-3/60 to-appbar-2/60 border border-border-white-10">
          <div>
            <h3 className="text-2xl md:text-3xl font-bold mb-3">Take Love On The Go</h3>
            <p className="text-light-white mb-5">
              Download our mobile app and find love anywhere, anytime. Get exclusive features and instant
              notifications when someone likes you.
            </p>
            <div className="flex gap-3">
              <a href="#" className="px-4 py-2 rounded-xl bg-white/90 text-gray-800 text-sm font-medium">Get it on Google Play</a>
              <a href="#" className="px-4 py-2 rounded-xl bg-white/90 text-gray-800 text-sm font-medium">Download on the App Store</a>
            </div>
          </div>
          <div className="rounded-2xl overflow-hidden bg-white/10 border border-border-white-10 h-64">
            <img src="/assets/home/app-mock.png" alt="Love Bug app mobile interface" className="w-full h-full object-cover" />
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

      {/* Footer */}
      <footer className="w-screen relative left-1/2 -translate-x-1/2 py-12 border-t border-border-white-10">
        <div className="max-w-6xl mx-auto px-4 grid md:grid-cols-4 gap-8 text-light-white">
          <div>
            <div className="text-white font-bold text-xl mb-2">Love Bug</div>
            <p>Finding your perfect match has never been easier. Join millions of singles looking for love.</p>
          </div>
          <div>
            <div className="text-white font-semibold mb-3">Company</div>
            <ul className="space-y-2 text-sm">
              <li><a href="#">About Us</a></li>
              <li><a href="#">Careers</a></li>
              <li><a href="#">Press</a></li>
              <li><a href="#">Blog</a></li>
            </ul>
          </div>
          <div>
            <div className="text-white font-semibold mb-3">Support</div>
            <ul className="space-y-2 text-sm">
              <li><a href="#">Help Center</a></li>
              <li><a href="#">Safety Tips</a></li>
              <li><a href="#">Contact Us</a></li>
              <li><a href="#">Community Guidelines</a></li>
            </ul>
          </div>
          <div>
            <div className="text-white font-semibold mb-3">Legal</div>
            <ul className="space-y-2 text-sm">
              <li><a href="#">Privacy Policy</a></li>
              <li><a href="#">Terms of Service</a></li>
              <li><a href="#">Cookie Policy</a></li>
              <li><a href="#">Accessibility</a></li>
            </ul>
          </div>
        </div>
        <div className="max-w-6xl mx-auto px-4 mt-8 text-center text-xs text-light-white">© 2025 Love Bug. All rights reserved.</div>
      </footer>
    </div>
  )
}


