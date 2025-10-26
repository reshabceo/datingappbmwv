import React from 'react'
import { Link } from 'react-router-dom'

export default function Accessibility() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Accessibility Statement</h1>
        </div>

        {/* Introduction */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Introduction</h2>
          <p className="text-light-white leading-relaxed mb-6">
            At Love Bug, we are committed to building and integrating technology that brings people together in ways that are intuitive, inclusive, and accessible to all. We proudly serve a global and diverse community—embracing people of all ages, races, genders, sexual orientations, backgrounds, abilities, and relationship goals. We demonstrate that commitment in the following ways:
          </p>
          
          <ul className="space-y-4 text-light-white">
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Ongoing accessibility training:</strong> Our team receives training on accessibility best practices, which aims to ensure employees have the skills required to improve the inclusivity and level of conformity with current standards.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Regular testing:</strong> We regularly test our services against the latest accessibility guidelines, such as the WCAG 2.2 AA guidelines, and make necessary updates to sustain accessibility.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Feedback mechanisms:</strong> We have established channels for users to provide feedback on accessibility issues and aim to address concerns promptly.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>We recognize that there is more work to be done:</strong> We commit to continuing to do the work to help everyone, everywhere, have the opportunity to connect, belong, and build meaningful relationships—free from barriers, bias, or exclusion.</span>
            </li>
          </ul>
        </div>

        {/* Description of Service */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Description of the Service and Measures to Support Accessibility</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Love Bug is on a mission to create meaningful connections for every single person worldwide. Our goal is to ensure the service is accessible across multiple formats, supporting a broad range of user needs. With that goal in mind, we have endeavored to take multiple measures, including but not limited to the following:
          </p>
          
          <ul className="space-y-4 text-light-white mb-8">
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Text-based descriptions:</strong> Alternatives for non-text, informative content and written information available in plain language.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Audio support:</strong> Narrated descriptions for users with visual disabilities.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Screen reader compatibility:</strong> Services are functional with popular screen readers.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Multimedia alternatives:</strong> When applicable, captions/subtitles, transcripts, audio descriptions and alternative text accompany visual and multimedia content.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Sufficient-contrast and zoom functionality:</strong> Provide sufficient contrast for visual elements and text scaling for users with visual disabilities.</span>
            </li>
          </ul>

          <p className="text-light-white leading-relaxed mb-4">Our service is delivered through an interface that supports accessibility by:</p>
          
          <ul className="space-y-4 text-light-white mb-8">
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Simple navigation:</strong> Logical layouts with consistent headings, landmarks, and navigation.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Keyboard accessibility:</strong> Functions that can be operated via keyboard.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Help and support:</strong> Guides in accessible formats, where warranted.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Customizable settings:</strong> Increased options for users to personalize settings, such as supporting text resizing within mobile device settings, themes, and display modes.</span>
            </li>
          </ul>

          <p className="text-light-white leading-relaxed mb-4">We are continuously striving to improve our accessibility by providing:</p>
          
          <ul className="space-y-4 text-light-white">
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Perceivable content:</strong> We aim to present visual and auditory information in ways that are adaptable to users' needs.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Operable interface:</strong> We continue to work on ensuring the services are navigable by keyboard and compatible with assistive technologies.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Understandable design:</strong> Our interface uses clear and simple language, and avoids unnecessary complexity.</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-light-pink font-bold text-xl">●</span>
              <span><strong>Robust content:</strong> We aim to design and build with the compatibility of current and future user assistive technologies in mind.</span>
            </li>
          </ul>
        </div>

        {/* Limitations */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Limitations and Alternatives</h2>
          <p className="text-light-white leading-relaxed">
            While we aim to provide an accessible experience for all users, some limitations may exist. In some cases, you may need to reboot the app for an accessibility update to become available to you, or double tap a photo to zoom in or out a fixed amount (as an alternative to multi-finger pinch gestures). Additionally, animations can be stopped by turning animation options off in your operating system. If you experience any issues, please let us know, and we will work to provide an alternative solution.
          </p>
        </div>

        {/* Feedback */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Feedback and Contact Information</h2>
          <p className="text-light-white leading-relaxed mb-6">
            We welcome your feedback on the accessibility of our services. If you encounter any accessibility barriers, please contact us via our Help Center.
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
              Contact Us
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}
