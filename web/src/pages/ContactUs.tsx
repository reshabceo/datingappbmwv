import React from 'react'
import { Link } from 'react-router-dom'

export default function ContactUs() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Contact Us</h1>
          <p className="text-light-white text-lg leading-relaxed">
            Got something you want to talk about? Contact us or email us and we promise to get back to you as soon as we can
          </p>
        </div>

        {/* Help / Support Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Help / Support</h2>
          <p className="text-light-white leading-relaxed mb-6">
            For all things technical and app-related.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            Contact Us or reach us by facsimile at
          </p>
          <div className="text-center">
            <a 
              href="mailto:lovebugdating@proton.me" 
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

        {/* Additional Contact Information */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Other Ways to Reach Us</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4">General Inquiries</h3>
              <p className="text-light-white leading-relaxed mb-4">
                For general questions about Love Bug, our services, or how to get started.
              </p>
              <a 
                href="mailto:lovebugdating@proton.me" 
                className="text-light-pink hover:text-pink-400 transition-colors"
              >
                lovebugdating@proton.me
              </a>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4">Technical Support</h3>
              <p className="text-light-white leading-relaxed mb-4">
                Having trouble with the app? We're here to help with any technical issues.
              </p>
              <a 
                href="mailto:lovebugdating@proton.me" 
                className="text-light-pink hover:text-pink-400 transition-colors"
              >
                lovebugdating@proton.me
              </a>
            </div>
          </div>
        </div>

        {/* Response Time */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Response Time</h2>
          <div className="text-center">
            <div className="inline-block p-6 rounded-xl bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30">
              <p className="text-light-white text-lg">
                We typically respond to all inquiries within <span className="text-light-pink font-semibold">24-48 hours</span>
              </p>
            </div>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Frequently Asked Questions</h2>
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold mb-2 text-white">How do I report a user?</h3>
              <p className="text-light-white leading-relaxed">
                You can report a user directly from their profile or through the match list. Every report is taken seriously and reviewed by our team.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-2 text-white">How do I delete my account?</h3>
              <p className="text-light-white leading-relaxed">
                You can delete your account by going to Settings &gt; Account &gt; Delete Account. Please note that this action cannot be undone.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-2 text-white">How do I update my profile?</h3>
              <p className="text-light-white leading-relaxed">
                You can update your profile by going to your profile page and clicking the edit button. Make sure to keep your information up to date!
              </p>
            </div>
          </div>
        </div>

        {/* Contact Form */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Send us a Message</h2>
          <p className="text-light-white mb-8">
            Can't find what you're looking for? Send us a direct message and we'll get back to you.
          </p>
          <a 
            href="mailto:lovebugdating@proton.me?subject=Love Bug Support Request" 
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            Send Message
          </a>
        </div>
      </div>
    </div>
  )
}
