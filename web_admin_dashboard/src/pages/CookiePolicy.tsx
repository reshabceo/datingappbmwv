import React from 'react'
import { Link } from 'react-router-dom'

export default function CookiePolicy() {
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
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Cookie Policy</h1>
          <p className="text-light-white text-lg leading-relaxed">
            At Love Bug, we believe in being clear and open about how we collect and process data about you. This page is designed to inform you about our practices regarding cookies and explain to you how you can manage them.
          </p>
        </div>

        {/* Quick Settings */}
        <div className="mb-12">
          <h2 className="text-2xl font-bold mb-4 text-light-pink">You already know everything there is to know about cookies and just want to adjust your settings?</h2>
          <p className="text-light-white leading-relaxed mb-4">
            No problem. Head to the profile settings in Love Bug, to update your website cookies settings, and head to your account settings in your app to adjust your privacy preferences there.
          </p>
          <h2 className="text-2xl font-bold mb-4 text-light-pink">You want to know more about cookies and how we use them?</h2>
          <p className="text-light-white leading-relaxed mb-4">
            Happy to explain! Keep on reading.
          </p>
          <p className="text-light-white leading-relaxed text-sm italic">
            Note: This Cookie Policy does not address how we process your personal information outside of our usage of cookies. To learn more about how we process your personal information, please read our Privacy Policy.
          </p>
        </div>

        {/* What are cookies */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What are cookies?</h2>
          <p className="text-light-white leading-relaxed">
            Cookies are small text files that are sent to or accessed from your web browser or your device's memory. A cookie typically contains the name of the domain (internet location) from which the cookie originated, the "lifetime" of the cookie (i.e., when it expires), and a randomly generated unique number or similar identifier. A cookie also may contain information about your device, such as user settings, browsing history, and activities conducted while using our services.
          </p>
        </div>

        {/* Types of cookies */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Are there different types of cookies?</h2>
          
          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">First-party and third-party cookies</h3>
            <p className="text-light-white leading-relaxed mb-4">
              There are first-party cookies and third-party cookies. First-party cookies are placed on your device directly by us. For example, we use first-party cookies to adapt our website to your browser's language preferences and to better understand your use of our website. Third-party cookies are placed on your device by our partners and service providers. You can learn more about these partners and service providers through our website and in-app consent management tools. For details on these tools, see "How can you control cookies?" below.
            </p>
          </div>

          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Session and persistent cookies</h3>
            <p className="text-light-white leading-relaxed">
              There are session cookies and persistent cookies. Session cookies only last until you close your browser. We use session cookies for a variety of reasons, including to learn more about your use of our website during one single browser session and to help you use our website more efficiently. Persistent cookies have a longer lifespan and last beyond the current session. These types of cookies can be used to help you quickly sign in to our website again, for analytical purposes, and for other reasons as described below.
            </p>
          </div>
        </div>

        {/* Other tracking technologies */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What about other tracking technologies, like web beacons and SDKs?</h2>
          <p className="text-light-white leading-relaxed">
            Other technologies such as web beacons (also called pixel, tags or clear gifs), tracking URLs or software development kits (SDKs) are used for similar purposes as cookies. Web beacons are tiny graphics files that contain a unique identifier that enable us to recognize when someone has visited our service or opened an e-mail that we have sent them. Tracking URLs are custom generated links that help us understand where the traffic to our webpages comes from. SDKs are small pieces of code included in apps, which function like cookies and web beacons.
          </p>
          <p className="text-light-white leading-relaxed mt-4">
            For simplicity, we also refer to these technologies as "cookies" in this Cookie Policy.
          </p>
        </div>

        {/* What do we use cookies for */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">What do we use cookies for?</h2>
          <p className="text-light-white leading-relaxed mb-6">
            Like other providers of online services, we use cookies to provide, secure and improve our services, including by remembering your preferences, recognizing you when you visit our website, measuring the success of our marketing campaigns and personalizing and tailoring ads to your interests. To accomplish these purposes, we also may link information from cookies with other personal information we hold about you.
          </p>
          <p className="text-light-white leading-relaxed mb-6">
            When you use our services, some or all of the following types of cookies may be set on your device.
          </p>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border-white-10">
                  <th className="text-left py-3 px-4 font-semibold text-light-pink">Cookie type</th>
                  <th className="text-left py-3 px-4 font-semibold text-light-pink">Description</th>
                </tr>
              </thead>
              <tbody className="text-light-white">
                <tr className="border-b border-border-white-10">
                  <td className="py-3 px-4 font-medium">Essential cookies</td>
                  <td className="py-3 px-4">These cookies are strictly necessary to provide you our services, such as enabling you to log in, remembering your preferences and keeping you safe by detecting malicious activity.</td>
                </tr>
                <tr className="border-b border-border-white-10">
                  <td className="py-3 px-4 font-medium">Analytics cookies</td>
                  <td className="py-3 px-4">These cookies help us understand how our services are being used and help us customize and improve our services for you.</td>
                </tr>
                <tr className="border-b border-border-white-10">
                  <td className="py-3 px-4 font-medium">Advertising & marketing cookies</td>
                  <td className="py-3 px-4">These cookies are used to determine how effective our marketing campaigns are and make the ads you see more relevant to you. They perform functions like helping us understand how much traffic our marketing campaigns drive on our services, preventing the same ad from continuously reappearing, ensuring that ads are properly displayed for advertisers, selecting advertisements relevant to you and measuring the number of ads displayed and their performance, such as how many people interacted with a given ad.</td>
                </tr>
                <tr>
                  <td className="py-3 px-4 font-medium">Social networking cookies</td>
                  <td className="py-3 px-4">These cookies are used to enable you to share pages and content that you find interesting on our services through third-party social networking and other websites or services. These cookies may also be used for advertising purposes.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* How to control cookies */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">How can you control cookies?</h2>
          <p className="text-light-white leading-relaxed mb-6">
            There are several cookie management options available to you. Please note that changes you make to your cookie preferences may make using our services a less satisfying experience as they may not be as personalized to you. In some cases, you may even find yourself unable to use all or part of our services.
          </p>

          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Tools we provide</h3>
            <p className="text-light-white leading-relaxed">
              You can set and adjust your cookies preferences at any time, and by heading to your account settings in your app and adjusting your app cookie preferences there
            </p>
          </div>

          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Browser and devices controls</h3>
            <p className="text-light-white leading-relaxed mb-4">
              Some web browsers provide settings that allow you to control or reject cookies or to alert you when a cookie is placed on your computer. The procedure for managing cookies is slightly different for each internet browser. You can check the specific steps in your particular browser help menu
            </p>
            <p className="text-light-white leading-relaxed">
              You also may be able to reset device identifiers or opt-out from having identifiers collected or processed by using the appropriate setting on your mobile device. The procedures for managing identifiers are slightly different for each device. You can check the specific steps in the help or settings menu of your particular device.
            </p>
          </div>

          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Interest-based advertising tools</h3>
            <p className="text-light-white leading-relaxed mb-4">
              Advertising companies may participate in self-regulatory programs which allow you to opt out of any interest-based ads involving them. For more information on this, you can visit the following sites: Digital Advertising Alliance; Interactive Digital Advertising Alliance; Appchoices (apps only).
            </p>
            <p className="text-light-white leading-relaxed">
              Opting out does not mean that you will not see advertising - it means you won't see personalized advertising from the companies that participate in the opt-out programs. Also, if you delete cookies on your device after you opted out, you will need to opt-out again.
            </p>
          </div>
        </div>

        {/* Google Cookies */}
        <div className="mb-12">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">Google™ Cookies</h2>
          
          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Google™ Maps API Cookies</h3>
            <p className="text-light-white leading-relaxed mb-4">
              Some features of our website and some Love Bug services rely on the use of Google™ Maps API Cookies. Such cookies will be stored on your device.
            </p>
            <p className="text-light-white leading-relaxed mb-4">
              When browsing this website and using the services relying on Google™ Maps API cookies, you consent to the storage, collection of such cookies on your device and to the access, usage and sharing by Google of the data collected thereby.
            </p>
            <p className="text-light-white leading-relaxed">
              Google™ manages the information and your choices pertaining to Google™ Maps API Cookies via an interface separate from that supplied by your browser. For more information, please see how Google uses cookies.
            </p>
          </div>

          <div className="mb-8">
            <h3 className="text-xl font-semibold mb-4">Google Analytics</h3>
            <p className="text-light-white leading-relaxed mb-4">
              We use Google Analytics, which is a Google service that uses cookies and other data collection technologies to collect information about your use of the website and services in order to report website trends.
            </p>
            <p className="text-light-white leading-relaxed">
              For more information on how Google collects and processes data, visit Google's Privacy and Terms page. You can opt out of Google Analytics by downloading the Google Analytics opt-out browser add-on and opt-out of Google's ad personalization.
            </p>
          </div>
        </div>

        {/* Contact Section */}
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 text-light-pink">How to contact us?</h2>
          <p className="text-light-white mb-4">
            If you have questions about this Cookie Policy, you can contact us online
          </p>
          <a href="mailto:lovebugdating@proton.me" className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-pink-500 to-purple-600 rounded-xl text-white font-semibold hover:from-pink-600 hover:to-purple-700 transition-all">
            lovebugdating@proton.me
          </a>
        </div>
      </div>
    </div>
  )
}
