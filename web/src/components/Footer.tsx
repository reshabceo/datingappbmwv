import React from 'react'

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
  )
}


