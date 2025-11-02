import React from 'react'
import DunsSeal from './DunsSeal'

export default function Footer() {
  return (
    <footer className="w-screen relative left-1/2 -translate-x-1/2 py-12 border-t border-border-white-10">
      <div className="max-w-6xl mx-auto px-4 grid md:grid-cols-4 gap-8 text-light-white">
        <div>
          <div className="text-white font-bold text-xl mb-2">Love Bug</div>
          <p>Finding your perfect match has never been easier. Join millions of singles looking for love.</p>
        </div>
        <div>
          <div className="text-white font-semibold mb-3">Company</div>
          <ul className="space-y-2 text-sm">
            <li><a href="/about-us">About Us</a></li>
            <li><a href="/careers">Careers</a></li>
            <li><a href="/press">Press</a></li>
            <li><a href="/blog">Blog</a></li>
          </ul>
        </div>
        <div>
          <div className="text-white font-semibold mb-3">Support</div>
          <ul className="space-y-2 text-sm">
            <li><a href="/safety-tips">Safety Tips</a></li>
            <li><a href="/contact-us">Contact Us</a></li>
            <li><a href="/community-guidelines">Community Guidelines</a></li>
          </ul>
        </div>
        <div>
          <div className="text-white font-semibold mb-3">Legal</div>
          <ul className="space-y-2 text-sm">
            <li><a href="/privacy-policy">Privacy Policy</a></li>
            <li><a href="/terms-of-service">Terms of Service</a></li>
            <li><a href="/cookie-policy">Cookie Policy</a></li>
            <li><a href="/accessibility">Accessibility</a></li>
            <li><a href="/refund-policy">Refund Policy</a></li>
          </ul>
        </div>
      </div>
      {/* Social links */}
      <div className="max-w-6xl mx-auto px-4 mt-8">
        <div className="flex items-center justify-center gap-6 text-light-white">
          <a
            href="https://www.instagram.com/lovebug.dating/"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Instagram"
            className="hover:text-white transition-colors"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="2" y="2" width="20" height="20" rx="5" stroke="currentColor" strokeWidth="1.5"/>
              <circle cx="12" cy="12" r="4.5" stroke="currentColor" strokeWidth="1.5"/>
              <circle cx="17.5" cy="6.5" r="1.2" fill="currentColor"/>
            </svg>
          </a>
          <a
            href="https://www.facebook.com/profile.php?id=61580544643427"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Facebook"
            className="hover:text-white transition-colors"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M22 12C22 6.477 17.523 2 12 2S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.988H8.078V12h2.36v-2.356c0-2.33 1.39-3.62 3.52-3.62 1.02 0 2.086.182 2.086.182v2.29h-1.176c-1.159 0-1.52.72-1.52 1.458V12h2.59l-.414 2.89h-2.176v6.988C18.343 21.128 22 16.991 22 12Z" fill="currentColor"/>
            </svg>
          </a>
          <a
            href="https://www.youtube.com/@LoveBugDating"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="YouTube"
            className="hover:text-white transition-colors"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M21.582 7.188a3.01 3.01 0 0 0-2.118-2.13C17.95 4.5 12 4.5 12 4.5s-5.95 0-7.464.558A3.01 3.01 0 0 0 2.418 7.188C1.875 8.71 1.875 12 1.875 12s0 3.29.543 4.812a3.01 3.01 0 0 0 2.118 2.13C6.05 19.5 12 19.5 12 19.5s5.95 0 7.464-.558a3.01 3.01 0 0 0 2.118-2.13C22.125 15.29 22.125 12 22.125 12s0-3.29-.543-4.812Z" fill="currentColor"/>
              <path d="M10 9.75v4.5L14.25 12 10 9.75Z" fill="#0B0B0D"/>
            </svg>
          </a>
        </div>
      </div>
      <div className="max-w-6xl mx-auto px-4 mt-8 flex flex-col md:flex-row items-center justify-between text-xs text-light-white">
        <div>© 2025 Love Bug. All rights reserved.</div>
        <div className="mt-4 md:mt-0">
          <DunsSeal size="small" showText={false} />
        </div>
      </div>
    </footer>
  )
}


