import React from 'react'
import { Link } from 'react-router-dom'

export default function SafetyTips() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Safety First</h1>
          <p className="text-light-pink text-xl font-semibold mb-4">The top Love Bug safety features you need to know!</p>
          <p className="text-light-white text-lg leading-relaxed">
            Indian singles are on dating apps, both head and heart first looking to make new connections. But before they do, Love Bug wants to remind them that safety comes first – non-negotiable! Although you can't control the actions of others, there are steps you can take thanks to some nifty features to help stay safe during your Love Bug experience.
          </p>
        </div>

        {/* Safety Features */}
        <div className="space-y-8">
          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Love Bug's Community Guidelines</h2>
            <p className="text-light-white leading-relaxed">
              If you're honest, kind, and respectful to others, you'll always be welcome on Love Bug. If you choose not to be, you may not last. Our goal is to allow users to express themselves authentically as long as it doesn't offend others. Everyone is held to the same standard. We're asking you to be considerate, think before you act, and abide by our community guidelines both on and offline. You heard that right: your offline behaviour can lead to termination of your Love Bug account.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">User Warnings</h2>
            <p className="text-light-white leading-relaxed">
              Recently, Love Bug announced advancements to its in-app user warnings to provide additional guidance to users, informing them of inappropriate behavior, as well as offering an immediate opportunity to change their actions moving forward.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Photo Verification</h2>
            <p className="text-light-white leading-relaxed">
              Once someone has created their Love Bug profile, and added their photos during the sign-up process, they are encouraged to utilise Love Bug's Photo Verification feature. Users who verify their profile get a blue tick and are more likely to get a match, too. Within their Message Settings, Photo Verified users can also opt to only receive messages from other Photo Verified users.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Video Selfie</h2>
            <p className="text-light-white leading-relaxed">
              Video selfie takes Photo Verification to the next level. Until now, users would take still photos while holding a series of static poses, and these photos were compared against others on the user's profile. Now, if users want to get photo verified they will have to complete a series of video prompts. While no photo verification process is perfect, this helps Love Bug keep those blue checkmarks more real.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Video Chat</h2>
            <p className="text-light-white leading-relaxed">
              Love Bug's video chat feature was built with control and comfort as its priority. The in-app video calling feature allows users to meet digitally, verify their match is genuine, and better assess whether the chemistry is there before an IRL date - all without giving out personal contact details.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Mutual Matching</h2>
            <p className="text-light-white leading-relaxed">
              To start a conversation, two people must have mutually liked each other, thanks to the Swipe Right feature, meaning nobody is getting unsolicited messages from someone they haven't expressed interest in.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Block Contacts</h2>
            <p className="text-light-white leading-relaxed">
              Block Contacts allows users to block personal contacts they'd rather not see nor seen by, in the app – empowering them to confidently "like" their way to new connections while avoiding the awkwardness of a familiar face. Whether those contacts are already on Love Bug or decide to download it later using the same contact info, they won't ever appear as a potential match.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Block Profile</h2>
            <p className="text-light-white leading-relaxed">
              Block Profile is an important step to give users the option to choose who they want to see on Love Bug. Now, when profiles are suggested, before matching, users can block them so they don't show up again. It's an easy way to avoid seeing a boss or an ex. This new feature comes in addition to Block Contacts and blocking following making a report.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Unmatch</h2>
            <p className="text-light-white leading-relaxed">
              Love Bug users can unmatch or block someone at any time for any reason, whether it wasn't a good fit or something more serious. Once unmatched, that person will no longer appear in the match list or message list and they won't be able to see you or message you anymore. Users can report someone they have either chosen to unmatch, or have been unmatched with, at any time.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Reporting</h2>
            <p className="text-light-white leading-relaxed">
              From profiles, media, to conversations, Love Bug makes it easy to quickly report accounts. You can report someone directly from a profile or through their match list and can even report someone who has unmatched you. Every report is taken seriously. In addition to its in-app reporting, Love Bug also announced long-press reporting that lets you tap and hold offensive messages and launch the reporting flow directly in the chat experience, making it even easier to report in-app.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Traveller Alert</h2>
            <p className="text-light-white leading-relaxed">
              When LGBTQIA+ users travel IRL or use Love Bug's Passport feature in a country with laws that penalise their community, they are alerted and given a choice to opt out before their profile is shown in the area. Love Bug can be a great way to meet people when travelling, but safety comes first.
            </p>
          </div>

          <div className="p-6">
            <h2 className="text-2xl font-bold mb-4 text-light-pink">Ghost Mode</h2>
            <p className="text-light-white leading-relaxed">
              Ghost Mode is a step up from fully hiding your profile. Subscribers can still Like and Nope in the app, but only those whom they've Liked will see them in their recommendations. Take complete control over who sees you while scrolling through profiles on Love Bug.
            </p>
          </div>
        </div>

        {/* About Love Bug Section */}
        <div className="mt-16 p-8">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">About Love Bug</h2>
          <p className="text-light-white leading-relaxed text-lg">
            Launched in 2025, Love Bug is the most popular app for meeting new people and getting astrological matchmakings. The app is available in different languages. More than half of all users are 18-25 years old. In 2025, Love Bug is one of the most innovative start up projects in India in terms of Dating & socializing.
          </p>
        </div>

        {/* Contact Section */}
        <div className="text-center mt-12">
          <p className="text-light-white mb-4">
            Have safety concerns or need help?
          </p>
          <a href="mailto:support@lovebug.live" className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-pink-500 to-purple-600 rounded-xl text-white font-semibold hover:from-pink-600 hover:to-purple-700 transition-all">
            Contact Support
          </a>
        </div>
      </div>
    </div>
  )
}
