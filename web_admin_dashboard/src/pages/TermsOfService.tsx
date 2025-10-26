import React from 'react'
import { Link } from 'react-router-dom'

export default function TermsOfService() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">LOVE BUG Terms And Conditions of Use</h1>
          <p className="text-light-white text-lg leading-relaxed">
            Welcome to Love Bug's Terms and Conditions of Use (these "Terms"). This is a contract between you and the Love Bug Dating Pvt Ltd (as defined further below) and we want you to know yours and our rights before you use the Love Bug website or application ("Love Bug" or the "App"). Please take a few moments to read these Terms before enjoying the App, because once you access, view, or use the App, you will be legally bound by these Terms (so probably best to read them first!). Please also read our Community Guidelines (part of these Terms) and our Privacy Policy.
          </p>
        </div>

        {/* Account Registration */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Account Registration</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Before you can use the App, you will need to register for an account ("Account"). In order to create an Account you must:
          </p>
          <ol className="list-decimal list-inside space-y-2 text-light-white mb-6">
            <li>be at least 18 years old or the age of majority to legally enter into a contract under the laws of your home country if that happens to be greater than 18; and</li>
            <li>be legally permitted to use the App by the laws of your home country.</li>
          </ol>
          <p className="text-light-white leading-relaxed mb-6">
            Please note that we monitor for underage use and we will terminate, suspend or ask you to verify your Account if we have reason to believe that you may be underage.
          </p>
          <p className="text-light-white leading-relaxed">
            You can create an Account via manual registration, or by using your Facebook login details. If you create an Account using your Facebook login details, you authorise us to access, display and use certain information from your Facebook account (e.g. profile pictures, relationship status, location and information about Facebook friends). For more information about what information we use and how we use it, please check out our Privacy Policy.
          </p>
        </div>

        {/* Account Termination */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Account Termination</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Unfortunately, we cannot allow you to use another person's Love Bug's account or to share your Love Bug account with any other person without permission. You are responsible for ensuring that any use of your account complies with these Terms.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            You'll have great fun on Love Bug, but if you feel the need to leave, you can delete your Account at any time by going to the 'Settings' page when you are logged in and clicking on the 'Delete account' link. Your Account will be deleted immediately but it may take a little while for Your Content (defined below) to be completely removed from the App. Your profile information will be treated in accordance with our Privacy Policy. If you delete your Account and try to create a new account within this time period using the same credentials, we will re-activate your Account for you.
          </p>
          <p className="text-light-white leading-relaxed">
            We use a combination of automated systems, user reports and a team of moderators to monitor and review accounts and content to identify breaches of these Terms. We reserve the right at our sole discretion to terminate or suspend any Account, restrict access to the App, or make use of any operational, technological, legal or other means available to enforce the Terms (including without limitation blocking specific IP addresses).
          </p>
        </div>

        {/* Content Restrictions */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Content Restrictions</h2>
          <p className="text-light-white leading-relaxed mb-6">
            There is certain content we can't allow on Love Bug. We want our users to be able express themselves as much as possible on Love Bug, but we have to impose restrictions on certain content which:
          </p>
          <ul className="space-y-2 text-light-white">
            <li>• is illegal or encourages, promotes or incites any illegal activity;</li>
            <li>• is harmful to minors;</li>
            <li>• is defamatory or libellous;</li>
            <li>• itself, or the posting of which, infringes any third party's rights (including, without limitation, intellectual property rights and privacy rights);</li>
            <li>• shows another person which was created or distributed without that person's consent;</li>
            <li>• contains language or imagery which could be deemed offensive or is likely to harass, upset, embarrass, alarm or annoy any other person;</li>
            <li>• is obscene, pornographic, violent or otherwise may offend human dignity;</li>
            <li>• is abusive, insulting or threatening, discriminatory or which promotes or encourages racism, sexism, hatred or bigotry;</li>
            <li>• relates to commercial activities (including, without limitation, sales, competitions and advertising, links to other websites or premium line telephone numbers);</li>
            <li>• involves the transmission of "junk" mail or "spam";</li>
            <li>• impersonates or intends to deceive or manipulate a person (including, without limitation, scams and inauthentic behaviour);</li>
            <li>• contains any spyware, adware, viruses, corrupt files, worm programs or other malicious code designed to interrupt, damage or limit the functionality of or disrupt any software, hardware, telecommunications, networks, servers or other equipment, Trojan horse or any other material designed to damage, interfere with, wrongly intercept or expropriate any data or personal information whether from Bumble or otherwise; or</li>
            <li>• in any other way violates our Community Guidelines.</li>
          </ul>
        </div>

        {/* User Responsibilities */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">User Responsibilities</h2>
          <p className="text-light-white leading-relaxed mb-4">You agree to:</p>
          <ul className="space-y-2 text-light-white mb-6">
            <li>• comply with all applicable laws, including without limitation, privacy laws, intellectual property laws, anti-spam laws, equal opportunity laws and regulatory requirements;</li>
            <li>• use your real name and real age in creating your Love Bug account and on your profile; and</li>
            <li>• use the services in a safe, inclusive and respectful manner and adhere to our Community Guidelines at all times.</li>
          </ul>
          
          <p className="text-light-white leading-relaxed mb-4">You agree that you will not:</p>
          <ul className="space-y-2 text-light-white">
            <li>• act in an unlawful or disrespectful manner including being dishonest, abusive or discriminatory;</li>
            <li>• misrepresent your identity, your age, your current or previous positions, qualifications or affiliations with a person or entity;</li>
            <li>• disclose information that you do not have the consent to disclose;</li>
            <li>• stalk or harass any other user of the App;</li>
            <li>• use the App in any deceptive, inauthentic or manipulative way, including engaging in conduct or distributing content relating to scams, spam, inauthentic profiles or commercial and promotional activity;</li>
            <li>• submit appeals, reports, notices or complaints that are manifestly unfounded; or;</li>
            <li>• develop, support or use software, devices, scripts, robots, other types of mobile code or any other means or processes (including crawlers, browser plugins and add-on or other technology) to scrape or otherwise exfiltrate from Love Bug or its services, or otherwise copy profiles and other data from the services.</li>
          </ul>
        </div>

        {/* Refund Policy */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Refund Policy</h2>
          <div className="bg-red-500/20 border border-red-500/30 rounded-xl p-6">
            <p className="text-white font-semibold text-lg mb-4">
              ALL PURCHASES AND REDEMPTIONS OF VIRTUAL ITEMS MADE THROUGH OUR SERVICES ARE FINAL AND NON-REFUNDABLE.
            </p>
            <p className="text-light-white">
              YOU ACKNOWLEDGE THAT LOVE BUG IS NOT REQUIRED TO PROVIDE A REFUND FOR ANY REASON, AND THAT YOU WILL NOT RECEIVE MONEY OR OTHER COMPENSATION FOR UNUSED VIRTUAL ITEMS WHEN AN ACCOUNT IS CLOSED, WHETHER SUCH CLOSURE WAS VOLUNTARY OR INVOLUNTARY.
            </p>
          </div>
        </div>

        {/* Disclaimer */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Disclaimer</h2>
          <p className="text-light-white leading-relaxed">
            THE APP, SITE, OUR CONTENT, AND MEMBER CONTENT ARE ALL PROVIDED TO YOU "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO, FITNESS FOR A PARTICULAR PURPOSE, TITLE, OR NON-INFRINGEMENT. WITHOUT LIMITING THE FOREGOING, WE DO NOT GUARANTEE THE COMPATIBILITY OF ANY MATCHES.
          </p>
        </div>

        {/* Contact */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Contact Us</h2>
          <p className="text-light-white mb-8">
            If you have any questions about these Terms, please contact us.
          </p>
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
    </div>
  )
}
