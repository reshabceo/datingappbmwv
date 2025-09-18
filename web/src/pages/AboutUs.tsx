import React from 'react'
import { Link } from 'react-router-dom'

export default function AboutUs() {
  return (
    <div className="text-white">
      <div className="max-w-4xl mx-auto px-8 py-12">
        {/* Header */}
        <div className="mb-12">
          <Link to="/" className="inline-flex items-center gap-2 text-light-white hover:text-white transition-colors mb-8">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="m15 18-6-6 6-6"/>
            </svg>
            Back to Home
          </Link>
          <h1 className="text-4xl md:text-5xl font-bold mb-4">About Us</h1>
        </div>

        {/* Main Content */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">So, Why Choose A Dating App Like Love Bug?</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Regarding dating apps, you've got options: Tinder, Badoo, Bumble, Hinge, Match, POF, OKCupid, and many more. It doesn't matter if you want to find love, a date, or have a casual chat, you still want to find an app that's the right match for you. And it's not always black and white — when you want to meet new people, your friends at Love Bug can help you out with features designed to make the impossible possible. Dating online just got easier.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            We won't brag about being the best free site — we'll let you decide for yourself by giving you Love Bug at a glance.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            We have features like Astrological matchmaking, Socializing & Virtual Gifts which can be used in private messages and while Video calling you can surprise your loved one with an animation of your present to show appreciation and love also it's a way of saying how much you have been invested in that person
          </p>
        </div>

        {/* Features Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-8 text-light-pink">Our Unique Features</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Astrological Matchmaking</h3>
              <p className="text-light-white leading-relaxed">
                Find your perfect match based on astrological compatibility. Our advanced algorithm considers zodiac signs and celestial alignments to connect you with someone who truly understands you.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Virtual Gifts & Socializing</h3>
              <p className="text-light-white leading-relaxed">
                Express your feelings with virtual gifts during private messages and video calls. Surprise your loved one with animated presents to show appreciation and love.
              </p>
            </div>
          </div>
        </div>

        {/* Matches Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Matches at Your Fingertips</h2>
          <p className="text-light-white leading-relaxed mb-6">
            One of the most adult decisions you'll make is picking a dating app that can offer you all the things your ex couldn't. And it's not just as simple as choosing between Badoo or Zoosk. Meeting people online is a journey, and you want someone along for the ride that you can trust.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            When it comes to making a match, consider the Love Bug app your new copilot.
          </p>
        </div>

        {/* All-Inclusive Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">All-Inclusive, All the Time</h2>
          <p className="text-light-white leading-relaxed mb-6">
            We're not a fan of labels, so we offer a dating experience designed to connect you with new people outside your usual circles. We believe everyone deserves the right to be seen and make the first move no matter how they identify.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            On our app, we put everyone in front of you and let you choose who you want to chat with.
          </p>
        </div>

        {/* Mission Statement */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Our Mission</h2>
          <div className="text-center">
            <div className="inline-block p-8 rounded-xl bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30">
              <p className="text-light-white text-lg leading-relaxed">
                To create meaningful connections through innovative technology, astrological compatibility, and inclusive design. We believe everyone deserves to find love, friendship, or meaningful connections in a safe, welcoming environment.
              </p>
            </div>
          </div>
        </div>

        {/* Values */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-8 text-light-pink">Our Values</h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Inclusivity</h3>
              <p className="text-light-white leading-relaxed">
                We welcome everyone regardless of gender, sexual orientation, race, or background. Love knows no boundaries.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Safety</h3>
              <p className="text-light-white leading-relaxed">
                Your safety and privacy are our top priorities. We provide tools and features to help you feel secure while connecting.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Innovation</h3>
              <p className="text-light-white leading-relaxed">
                We continuously innovate with features like astrological matching and virtual gifts to enhance your dating experience.
              </p>
            </div>
          </div>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Get in Touch</h2>
          <p className="text-light-white mb-8">
            Have questions about Love Bug? We'd love to hear from you!
          </p>
          <a 
            href="mailto:lovebugdating@proton.me" 
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            Contact Us
          </a>
        </div>
      </div>
    </div>
  )
}
