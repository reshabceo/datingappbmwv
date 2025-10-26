import React from 'react'
import { Link } from 'react-router-dom'

export default function Press() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Press</h1>
          <p className="text-light-white text-lg leading-relaxed">
            Media inquiries, press releases, and information for journalists covering Love Bug.
          </p>
        </div>

        {/* Press Contact */}
        <div className="mb-12">
          <div className="text-center">
            <div className="inline-block p-8 rounded-xl bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30">
              <h2 className="text-3xl font-bold mb-6 text-light-pink">Press Inquiries</h2>
              <p className="text-light-white text-lg leading-relaxed mb-6">
                For press inquiries, media requests, or to get details about Love Bug, please email us directly.
              </p>
              <p className="text-light-white text-lg leading-relaxed mb-8">
                We're happy to provide information about our platform, company updates, and answer any questions you may have.
              </p>
              <a 
                href="mailto:lovebugdating@proton.me?subject=Press Inquiry" 
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
                Email Us for Details
              </a>
            </div>
          </div>
        </div>

        {/* About Love Bug */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">About Love Bug</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Love Bug is a modern dating app designed to create meaningful connections through innovative technology, astrological compatibility, and inclusive design. We're on a mission to help every single person worldwide find love, friendship, or meaningful connections.
          </p>
          <p className="text-light-white leading-relaxed">
            Launched in 2025, Love Bug has quickly become one of the most innovative startup projects in India in terms of dating and socializing, with a focus on creating a safe, inclusive space for all users.
          </p>
        </div>

        {/* Key Features */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Key Features</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Astrological Matchmaking</h3>
              <p className="text-light-white leading-relaxed">
                Our unique algorithm uses astrological compatibility to help users find their perfect match based on zodiac signs and celestial alignments.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Virtual Gifts & Socializing</h3>
              <p className="text-light-white leading-relaxed">
                Users can express their feelings with virtual gifts during private messages and video calls, creating more meaningful interactions.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Safety First</h3>
              <p className="text-light-white leading-relaxed">
                We prioritize user safety with comprehensive safety features, photo verification, and robust reporting systems.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Inclusive Design</h3>
              <p className="text-light-white leading-relaxed">
                Our platform welcomes everyone regardless of gender, sexual orientation, race, or background, creating an inclusive dating experience.
              </p>
            </div>
          </div>
        </div>

        {/* Company Information */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Company Information</h2>
          <div className="space-y-4 text-light-white">
            <div>
              <strong>Company Name:</strong> Love Bug Dating Pvt Ltd
            </div>
            <div>
              <strong>Founded:</strong> 2025
            </div>
            <div>
              <strong>Headquarters:</strong> India
            </div>
            <div>
              <strong>Mission:</strong> Creating meaningful connections for every single person worldwide
            </div>
            <div>
              <strong>Target Audience:</strong> Adults 18+ looking for meaningful relationships
            </div>
            <div>
              <strong>Platform:</strong> Mobile app and web platform
            </div>
          </div>
        </div>

        {/* Media Assets */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Media Assets</h2>
          <p className="text-light-white leading-relaxed mb-6">
            For media assets, logos, screenshots, or other materials, please contact us and we'll be happy to provide what you need for your coverage.
          </p>
          <div className="bg-white/5 border border-border-white-10 rounded-xl p-6">
            <h3 className="text-xl font-semibold mb-4 text-white">Available Upon Request:</h3>
            <ul className="space-y-2 text-light-white">
              <li>• Company logos and brand assets</li>
              <li>• App screenshots and interface images</li>
              <li>• Press photos and team images</li>
              <li>• Company fact sheet</li>
              <li>• Executive bios and quotes</li>
              <li>• Product demos and videos</li>
            </ul>
          </div>
        </div>

        {/* Contact Information */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Press Contact</h2>
          <p className="text-light-white mb-8">
            For all press inquiries, please contact us at:
          </p>
          <a 
            href="mailto:lovebugdating@proton.me?subject=Press Inquiry" 
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            lovebugdating@proton.me
          </a>
        </div>
      </div>
    </div>
  )
}
