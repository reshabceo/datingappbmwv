import React from 'react'
import { Link } from 'react-router-dom'

export default function Blog() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Blog</h1>
          <p className="text-light-white text-lg leading-relaxed">
            Stay updated with the latest from Love Bug - dating tips, success stories, and platform updates.
          </p>
        </div>

        {/* No Blog Posts */}
        <div className="mb-12">
          <div className="text-center">
            <div className="inline-block p-8 rounded-xl bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30">
              <h2 className="text-3xl font-bold mb-6 text-light-pink">No Blog Posts Yet</h2>
              <p className="text-light-white text-lg leading-relaxed mb-6">
                We're working on creating amazing content for you! Our blog will feature dating tips, success stories, platform updates, and insights into modern dating.
              </p>
              <p className="text-light-white text-lg leading-relaxed mb-8">
                Check back soon for our first blog posts, or subscribe to our newsletter to be notified when we publish new content.
              </p>
              <a 
                href="mailto:lovebugdating@proton.me?subject=Blog Subscription" 
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
                Subscribe to Updates
              </a>
            </div>
          </div>
        </div>

        {/* Coming Soon Content */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What's Coming Soon</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Dating Tips & Advice</h3>
              <p className="text-light-white leading-relaxed">
                Expert advice on modern dating, relationship building, and how to make meaningful connections in the digital age.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Success Stories</h3>
              <p className="text-light-white leading-relaxed">
                Real stories from Love Bug users who found love, friendship, or meaningful connections through our platform.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Platform Updates</h3>
              <p className="text-light-white leading-relaxed">
                Stay informed about new features, improvements, and updates to the Love Bug platform.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-4 text-white">Dating Trends</h3>
              <p className="text-light-white leading-relaxed">
                Insights into modern dating trends, astrological compatibility, and the future of online dating.
              </p>
            </div>
          </div>
        </div>

        {/* Newsletter Signup */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Stay Updated</h2>
          <div className="bg-gradient-to-r from-pink-500/20 to-purple-600/20 border border-pink-30 rounded-xl p-8">
            <p className="text-light-white text-lg leading-relaxed mb-6">
              Be the first to know when we publish new blog posts! Subscribe to our newsletter for dating tips, success stories, and platform updates.
            </p>
            <div className="text-center">
              <a 
                href="mailto:lovebugdating@proton.me?subject=Newsletter Subscription" 
                className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
                Subscribe to Newsletter
              </a>
            </div>
          </div>
        </div>

        {/* Content Suggestions */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Have Content Ideas?</h2>
          <p className="text-light-white leading-relaxed mb-6">
            We're always looking for great content ideas! If you have suggestions for blog topics, success stories to share, or questions you'd like us to address, we'd love to hear from you.
          </p>
          <div className="text-center">
            <a 
              href="mailto:lovebugdating@proton.me?subject=Blog Content Suggestion" 
              className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              Send Us Your Ideas
            </a>
          </div>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Get in Touch</h2>
          <p className="text-light-white mb-8">
            Questions about our blog or want to contribute? We'd love to hear from you!
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
