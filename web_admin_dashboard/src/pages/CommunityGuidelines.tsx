import React from 'react'
import { Link } from 'react-router-dom'

export default function CommunityGuidelines() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Community Guidelines</h1>
          <p className="text-light-white text-lg">Welcome to Love Bug - where meaningful connections happen.</p>
        </div>

        {/* Introduction */}
        <div className="mb-12">
          <p className="text-lg leading-relaxed mb-6">
            Love Bug is where meaningful connections can happen. It Starts With a Swipe™. Sometimes you click. Sometimes you don't. And sometimes the talking leads to more. Opportunity is overflowing. Possibilities are endless. All (adults) are welcome to come explore.
          </p>
          <p className="text-lg leading-relaxed mb-6">
            We want Love Bug to be a fun, safe, and inclusive space where anyone can be themselves while getting to know others. That's what these Community Guidelines are for–to set expectations for everyone's behavior, both on and off the app. So read on; not following these guidelines can have real consequences-from a nudge to a ban.
          </p>
        </div>

        {/* Rules Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-8 text-light-pink">LOVE BUG's Rules:</h2>
          
          <div className="space-y-8">
            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">1. Consider boundaries</h3>
              <p className="text-light-white leading-relaxed">
                Comfort levels vary from person to person. That's why we don't allow nudity, sexual content, sexual desires, or looking for sex on your public profile. If you are in a private conversation, these are okay if everyone is okay with it. Consent matters.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">2. Share cautiously and thoughtfully</h3>
              <p className="text-light-white leading-relaxed">
                Don't publicly broadcast your personal information or ways for people to connect with you (no public displays of things like phone numbers, emails, or social handles). Sharing your bank account numbers or email password is always a bad idea. Don't ask others to send you their personal details either. Be cautious, if someone asks you to send them money or tries to get you to invest, it's probably a scam.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">3. Steer clear of violent content</h3>
              <p className="text-light-white leading-relaxed">
                We promote positivity and won't tolerate any sort of violent content that contains gore, death, images, or descriptions of violent acts (against humans or animals), use of weapons, or anything advocating or glorifying self-harm.
              </p>
              <p className="text-light-white leading-relaxed mt-3">
                If we believe there's a risk of imminent harm, we may take steps to assist, like reaching out directly with crisis resources.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">4. Make personal connections, not biz ones</h3>
              <p className="text-light-white leading-relaxed">
                Don't advertise, promote, share your social handles to gain followers, sell stuff, fundraise, or campaign. This also means Love Bug isn't the place for any sort of sex work, escort services, or compensated relationships. So, no–don't use Love Bug to find your sugarmamma.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">5. Just be you</h3>
              <p className="text-light-white leading-relaxed">
                People want to meet the real you. Not your fake persona. Don't create a fake account or pretend to be someone you're not, even if it's just for fun.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">6. Communicate Respectfully</h3>
              <p className="text-light-white leading-relaxed">
                Talking to new people can be tricky, especially when you're interacting with humans from all walks of life. Respect goes a long way.
              </p>
              <p className="text-light-white leading-relaxed mt-3">
                If the conversation goes unexpectedly awry and you find yourself getting upset or feeling angry–pause and reflect before you react. Harassment, threats, bullying, intimidation, doxing, sextortion, blackmail, or anything intentionally done to cause harm is not allowed.
              </p>
              <p className="text-light-white leading-relaxed mt-3">
                Love Bug is not a place for hate. We will never stand behind racism, bigotry, hatred, or violence based on who someone is, how they identify, or what they look like. This includes (but is not limited to) someone's race, ethnicity, nationality, immigration status, caste, religion, gender identity, sexual orientation, disability, body type, or health status. If you see someone who doesn't meet your personal criteria, don't like them, or unmatch and move on. Don't report them unless you think they've violated our policies.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">7. Lead with kindness, not harm</h3>
              <p className="text-light-white leading-relaxed">
                Any acts or behavior that suggest, intend, or cause harm to another user - either on or offline, physically or digitally - will be taken very seriously. This includes anything calling for or inciting harm.
              </p>
              <p className="text-light-white leading-relaxed mt-3">
                If you have been hurt by someone on Love Bug: first, please take care of yourself, and second, take some time to decide what you need to heal, whether that be accountability measures, disclosure, support, or all of the above. If this includes reporting the harm to us, please reach out. We are here for you.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">8. Adults only</h3>
              <p className="text-light-white leading-relaxed">
                You must be 18 years of age or older to use Love Bug. This also means we don't allow photos of unaccompanied or unclothed minors, including photos of your younger self–no matter how adorable you were back then.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">9. Abide by the law</h3>
              <p className="text-light-white leading-relaxed">
                No illegal content or activities are allowed, ever. This means you can't use Love Bug to buy or sell drugs or counterfeit goods, or ask for assistance to help you break the law. We definitely won't tolerate anyone using Love Bug to advocate or participate in any sort of harm involving minors or human trafficking.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">10. One person, one account</h3>
              <p className="text-light-white leading-relaxed">
                Each account can only have one owner. For logistic and privacy reasons, we can't support multiple people accessing the same account, each individual needs to have their own. Also, one person can't have more than one account at a time.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">11. This is your space, post your own content</h3>
              <p className="text-light-white leading-relaxed">
                Don't post images or private messages from other people unless you've been given consent to do so. Don't post work that's copyrighted or trademarked by others.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">12. Be a good Love Bug user</h3>
              <p className="text-light-white leading-relaxed">
                Don't abuse Love Bug. Don't use Love Bug to spread false or misleading information. Don't spam harmful links or unsolicited content. Don't create mass accounts. Don't use Love Bug to manipulate, con, or get people to send you money or anything else. It's okay to talk to your friends and family about people you are meeting, but don't publicly share someone else's information. Don't submit false, misleading, or malicious reports. Don't use third-party apps or other technology to unlock features or game the system. Don't harass, threaten, or otherwise violate these rules when speaking directly with Love Bug, Match Group, or its affiliates.
              </p>
            </div>

            <div className="p-6">
              <h3 className="text-xl font-semibold mb-3">13. Stick around to stay active</h3>
              <p className="text-light-white leading-relaxed">
                If you don't log into your Love Bug account in two years, we'll assume it's not being used and may delete it for inactivity. So if you want to be seen in the app, just log in from time to time.
              </p>
            </div>
          </div>
        </div>

        {/* Reporting Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Reporting</h2>
          <div className="p-6">
            <p className="text-light-white leading-relaxed">
              As a member of the Love Bug community, we encourage you to speak up and speak out. If someone is causing you harm or is violating our Community Guidelines–report it. Your report is always treated as confidential. By reporting, you can help us stop harmful behavior and protect others.
            </p>
          </div>
        </div>

        {/* Impact Section */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Impact</h2>
          <div className="p-6">
            <p className="text-light-white leading-relaxed">
              We take our Community Guidelines and the impact they have on our community seriously. We'll do everything we can to make sure people follow them. We have a warning system in place, but if violations continue or if the violation is severe, we will respond accordingly.
            </p>
            <p className="text-light-white leading-relaxed mt-4">
              We reserve the right to investigate and/or terminate accounts without a refund of any purchases if we find you have misused the Service or behaved in a way Love Bug deems inappropriate, unlawful, or in violation of our Community Guidelines, including actions or communications that occur off the Service but involve others you meet through the Service.
            </p>
          </div>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <p className="text-light-white mb-4">
            Questions about these guidelines? Need to report something?
          </p>
          <a href="mailto:support@lovebug.live" className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-pink-500 to-purple-600 rounded-xl text-white font-semibold hover:from-pink-600 hover:to-purple-700 transition-all">
            Contact Support
          </a>
        </div>
      </div>
    </div>
  )
}
