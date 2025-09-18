import React from 'react'
import { Link } from 'react-router-dom'

export default function RefundPolicy() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Refund Policy</h1>
        </div>

        {/* Main Policy */}
        <div className="mb-12">
          <div className="bg-red-500/20 border border-red-500/30 rounded-xl p-8 mb-8">
            <h2 className="text-3xl font-bold mb-6 text-red-300">IMPORTANT NOTICE</h2>
            <p className="text-white font-semibold text-xl mb-4">
              ALL PURCHASES AND REDEMPTIONS OF VIRTUAL ITEMS AND SUBSCRIPTIONS MADE THROUGH OUR SERVICES ARE FINAL AND NON-REFUNDABLE.
            </p>
            <p className="text-light-white text-lg">
              YOU ACKNOWLEDGE THAT LOVE BUG IS NOT REQUIRED TO PROVIDE A REFUND FOR ANY REASON, AND THAT YOU WILL NOT RECEIVE MONEY OR OTHER COMPENSATION FOR UNUSED VIRTUAL ITEMS WHEN AN ACCOUNT IS CLOSED, WHETHER SUCH CLOSURE WAS VOLUNTARY OR INVOLUNTARY.
            </p>
          </div>
        </div>

        {/* What This Means */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What This Means</h2>
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Virtual Items</h3>
              <p className="text-light-white leading-relaxed">
                All virtual gifts, premium features, and in-app purchases are considered final once purchased. This includes but is not limited to:
              </p>
              <ul className="mt-3 space-y-2 text-light-white">
                <li>• Virtual gifts sent to other users</li>
                <li>• Premium subscription features</li>
                <li>• Profile boosts and visibility enhancements</li>
                <li>• Any other virtual items or services</li>
              </ul>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Account Closure</h3>
              <p className="text-light-white leading-relaxed">
                Whether you voluntarily delete your account or your account is terminated by Love Bug for any reason, you will not receive refunds for any unused virtual items or remaining subscription time.
              </p>
            </div>
            
            <div>
              <h3 className="text-xl font-semibold mb-3 text-white">Subscription Services</h3>
              <p className="text-light-white leading-relaxed">
                All subscription services are non-refundable. If you cancel your subscription, you will continue to have access to premium features until the end of your current billing period, but no refunds will be provided for unused time.
              </p>
            </div>
          </div>
        </div>

        {/* Exceptions */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Limited Exceptions</h2>
          <p className="text-light-white leading-relaxed mb-6">
            In very rare circumstances, Love Bug may consider refunds only in the following situations:
          </p>
          <ul className="space-y-3 text-light-white">
            <li>• <strong>Technical errors:</strong> If a technical error on our part results in duplicate charges or incorrect billing amounts</li>
            <li>• <strong>Unauthorized purchases:</strong> If you can prove that a purchase was made without your authorization and you report it within 48 hours</li>
            <li>• <strong>Legal requirements:</strong> If required by applicable law in your jurisdiction</li>
          </ul>
          <p className="text-light-white leading-relaxed mt-6">
            All refund requests must be submitted through our support team and will be reviewed on a case-by-case basis. Love Bug reserves the right to deny any refund request at its sole discretion.
          </p>
        </div>

        {/* How to Contact */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">How to Contact Us</h2>
          <p className="text-light-white leading-relaxed mb-6">
            If you believe you have a valid reason for a refund request under the limited exceptions listed above, please contact our support team with the following information:
          </p>
          <ul className="space-y-2 text-light-white mb-6">
            <li>• Your Love Bug account email</li>
            <li>• Date and time of the purchase</li>
            <li>• Transaction ID or receipt number</li>
            <li>• Detailed explanation of why you believe a refund is warranted</li>
            <li>• Any supporting documentation</li>
          </ul>
        </div>

        {/* Policy Updates */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Policy Updates</h2>
          <p className="text-light-white leading-relaxed">
            Love Bug reserves the right to update this refund policy at any time. Any changes will be posted on this page and will become effective immediately. Your continued use of our services after any changes constitutes acceptance of the updated policy.
          </p>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Need Help?</h2>
          <p className="text-light-white mb-8">
            If you have questions about this refund policy or need to submit a refund request, please contact our support team.
          </p>
          <a 
            href="mailto:lovebugdating@proton.me" 
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            Contact Support
          </a>
        </div>
      </div>
    </div>
  )
}
