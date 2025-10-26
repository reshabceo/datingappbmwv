import React from 'react'
import { Link } from 'react-router-dom'

export default function Careers() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Careers</h1>
          <p className="text-light-white text-lg leading-relaxed">
            Join our mission to create meaningful connections and help people find love in the digital age.
          </p>
        </div>

        {/* No Open Positions */}
        <div className="mb-12">
          <div className="text-center">
            <div className="inline-block p-8 rounded-xl bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30">
              <h2 className="text-3xl font-bold mb-6 text-light-pink">No Open Positions Available</h2>
              <p className="text-light-white text-lg leading-relaxed mb-6">
                We're not currently hiring, but we're always interested in connecting with talented individuals who share our vision.
              </p>
              <p className="text-light-white text-lg leading-relaxed mb-8">
                If you're passionate about creating meaningful connections and want to be part of our journey, reach out to us directly.
              </p>
              <a 
                href="mailto:lovebugdating@proton.me" 
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
                Reach Out to Us
              </a>
            </div>
          </div>
        </div>

        {/* About Working at Love Bug */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Why Work at Love Bug?</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Our Mission</h3>
              <p className="text-light-white leading-relaxed">
                We're on a mission to create meaningful connections for every single person worldwide. Join us in building technology that brings people together in ways that are intuitive, inclusive, and accessible to all.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Our Values</h3>
              <p className="text-light-white leading-relaxed">
                We believe in inclusivity, safety, and innovation. We're committed to creating a workplace where everyone can thrive and contribute to our mission of helping people find love and meaningful connections.
              </p>
            </div>
          </div>
        </div>

        {/* What We Look For */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What We Look For</h2>
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Passion for Our Mission</h3>
              <p className="text-light-white leading-relaxed">
                We're looking for people who are genuinely excited about helping others find meaningful connections and who believe in the power of technology to bring people together.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Innovation & Creativity</h3>
              <p className="text-light-white leading-relaxed">
                We value creative thinkers who can help us innovate and improve our platform. Whether you're a developer, designer, marketer, or have other skills, we want to hear from you.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Collaborative Spirit</h3>
              <p className="text-light-white leading-relaxed">
                We believe in the power of teamwork and collaboration. We're looking for people who work well with others and who can contribute to our positive, inclusive culture.
              </p>
            </div>
          </div>
        </div>

        {/* Future Opportunities */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Future Opportunities</h2>
          <p className="text-light-white leading-relaxed mb-6">
            While we don't have open positions right now, we're always growing and may have opportunities in the future. We're particularly interested in:
          </p>
          <ul className="space-y-2 text-light-white mb-8">
            <li>• Software Engineers (Frontend, Backend, Mobile)</li>
            <li>• Product Designers</li>
            <li>• Marketing Specialists</li>
            <li>• Customer Support Representatives</li>
            <li>• Data Scientists</li>
            <li>• Content Creators</li>
            <li>• Business Development</li>
          </ul>
          <p className="text-light-white leading-relaxed">
            If you're interested in any of these areas or have other skills you think would be valuable to our team, please don't hesitate to reach out!
          </p>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Get in Touch</h2>
          <p className="text-light-white mb-8">
            Ready to join our mission? Send us your resume and tell us why you'd like to work at Love Bug.
          </p>
          <a 
            href="mailto:lovebugdating@proton.me?subject=Career Inquiry" 
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            Send Us Your Resume
          </a>
        </div>
      </div>
    </div>
  )
}
