import React from 'react'
import { Link } from 'react-router-dom'

/**
 * Child Safety Standards Policy (CSAE) – Published standards for Love Bug.
 * Explicitly prohibits Child Sexual Abuse and Exploitation (CSAE/CSAM).
 * Meets store compliance: functional, relevant (CSAE/child safety), references app name.
 */
export default function CSAEPolicy() {
  return (
    <div className="text-white">
      <div className="max-w-4xl mx-auto px-6 sm:px-8 py-10 sm:py-12">
        {/* Back + Header */}
        <div className="mb-10 sm:mb-12">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-light-white hover:text-white transition-colors mb-6 sm:mb-8"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="m15 18-6-6 6-6" />
            </svg>
            Back to Home
          </Link>
          <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-3 sm:mb-4">
            Child Safety Standards Policy
          </h1>
          <p className="text-light-pink font-semibold text-lg">
            Love Bug – CSAE Declaration &amp; Policy for the Protection of Children and Minors
          </p>
          <p className="text-light-white text-base sm:text-lg leading-relaxed mt-2">
            Love Bug has a strict, zero-tolerance policy to protect children and minors from all forms of CSAE (Child Sexual Abuse and Exploitation). These published standards apply to the Love Bug app and all Love Bug services.
          </p>
        </div>

        {/* Zero tolerance */}
        <section className="mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            Zero tolerance for CSAE
          </h2>
          <p className="text-light-white leading-relaxed mb-4">
            Love Bug does not allow any content in any form that sexualizes or endangers children, whether fictional or real. This includes but is not limited to: photos, images, media, text, illustrations, anime, and any other format.
          </p>
          <p className="text-light-white leading-relaxed mb-4">
            We prohibit any visual depictions, sharing of third‑party links, or discussions of sexually explicit conduct involving a child. It is forbidden on Love Bug to upload, store, produce, share, or encourage anyone to share child sexual abuse material (CSAM), including when the intent is to express outrage or raise awareness.
          </p>
        </section>

        {/* Unintentional child content */}
        <section className="mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            No child content on the platform
          </h2>
          <p className="text-light-white leading-relaxed mb-4">
            Our guidelines also cover unintentional child content. Love Bug does not allow any content depicting children on our platform, even when the intention is non‑sexual. The only exception we allow is discussing expectations for future or potential family‑planning, or talking about existing children in the context of relationship building. Even then, such conversations must remain appropriate, relevant, and lawful.
          </p>
          <p className="text-light-white leading-relaxed">
            If you upload a photo that includes your own child, the child must be completely covered (not just the face) with an emoji or similar. This lets you show context without endangering your child. We ask that you respect this strict policy.
          </p>
        </section>

        {/* Violations & enforcement */}
        <section className="mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            Violations and enforcement
          </h2>
          <p className="text-light-white leading-relaxed">
            Any violation of this Child Safety Standards policy will result in the immediate blocking (and subsequent deletion) of the account and a report to the relevant authorities. Love Bug takes CSAE compliance seriously and will act accordingly.
          </p>
        </section>

        {/* In-app reporting */}
        <section className="mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            In-app reporting
          </h2>
          <p className="text-light-white leading-relaxed mb-4">
            Love Bug provides in‑app reporting for safety concerns:
          </p>
          <ul className="list-disc list-inside space-y-2 text-light-white mb-4">
            <li>On every user&apos;s profile: use the &quot;Report user&quot; option at the bottom of the profile.</li>
            <li>In the Chat Inbox: use the shield icon in the top‑right corner of each chat detail page.</li>
          </ul>
          <p className="text-light-white leading-relaxed">
            We encourage users to report any content or behavior that may violate our Child Safety Standards or involve CSAE.
          </p>
        </section>

        {/* Legal age */}
        <section className="mb-10 sm:mb-12">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            Legal age
          </h2>
          <p className="text-light-white leading-relaxed">
            You must be at least 18 years old to use Love Bug. If we find any indication that you misrepresented your age, we will immediately block and delete your account. This is part of our commitment to child safety and compliance with applicable standards.
          </p>
        </section>

        {/* Compliance note for stores */}
        <section className="mb-10 sm:mb-12 rounded-xl border border-pink-30 bg-white/5 p-6">
          <h2 className="text-xl sm:text-2xl font-bold mb-3 text-light-pink">
            Published standards (Love Bug / Google Play)
          </h2>
          <p className="text-light-white leading-relaxed text-sm sm:text-base">
            These Child Safety Standards are the official published policy of Love Bug (as listed on the Google Play store and other store listings). They explicitly prohibit CSAE and child sexual abuse material (CSAM), and apply to all use of the Love Bug app and services. Love Bug is committed to complying with child safety requirements and to maintaining a safe environment for our users.
          </p>
        </section>

        {/* Contact */}
        <section className="text-center">
          <h2 className="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-light-pink">
            Contact
          </h2>
          <p className="text-light-white mb-6 max-w-xl mx-auto">
            If you have questions about this policy or need to report CSAE‑relevant content, please contact Love Bug:
          </p>
          <a
            href="mailto:lovebugdating@proton.me"
            className="inline-flex items-center gap-2 px-6 sm:px-8 py-3 sm:py-4 bg-gradient-cta text-white font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 rounded-full"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
              <polyline points="22,6 12,13 2,6" />
            </svg>
            lovebugdating@proton.me
          </a>
          <p className="text-light-white text-sm mt-4">
            Love Bug – Child Safety Standards Policy. Last updated for store compliance.
          </p>
        </section>
      </div>
    </div>
  )
}
