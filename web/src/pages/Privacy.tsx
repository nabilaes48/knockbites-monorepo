import { Card, CardContent } from "@/components/ui/card";

export default function Privacy() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <Card className="bg-slate-800/50 border-slate-700">
          <CardContent className="p-8">
            <div className="prose prose-invert max-w-none">
              <h1 className="text-4xl font-bold text-white mb-2">Privacy Policy</h1>
              <p className="text-slate-400 mb-8">
                <strong>Effective Date:</strong> December 1, 2024<br />
                <strong>Last Updated:</strong> November 24, 2024
              </p>

              <hr className="border-slate-700 my-8" />

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Introduction</h2>
              <p className="text-slate-300">
                Welcome to KnockBites, the official mobile and web ordering platform for KnockBites 24-7 stores.
                This Privacy Policy explains how Highland Mills Snack Shop Inc. ("we," "us," or "our") collects, uses,
                shares, and protects your personal information when you use our mobile application and website
                (collectively, the "Service").
              </p>
              <p className="text-slate-300">
                By using KnockBites, you agree to the collection and use of information in accordance with this policy.
              </p>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Information We Collect</h2>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">1. Information You Provide to Us</h3>
              <p className="text-slate-300">When you use KnockBites, we collect the following information that you voluntarily provide:</p>

              <p className="text-slate-300 font-semibold mt-4">For Order Placement:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Name</strong> - To identify your order when ready for pickup</li>
                <li><strong>Phone Number</strong> - To contact you about your order status</li>
                <li><strong>Email Address</strong> (optional) - For order confirmations and receipts</li>
              </ul>

              <p className="text-slate-300 font-semibold mt-4">For Account Creation (Optional):</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Email Address</strong> - For account login and communication</li>
                <li><strong>Password</strong> - Securely hashed and encrypted</li>
                <li><strong>Delivery Address</strong> (if applicable) - For future delivery services</li>
              </ul>

              <p className="text-slate-300 font-semibold mt-4">Order Information:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Items ordered</li>
                <li>Special instructions or customizations</li>
                <li>Order timestamps</li>
                <li>Store location selected</li>
                <li>Payment information (if paying online - currently we accept payment at pickup only)</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">2. Information Collected Automatically</h3>
              <p className="text-slate-300">When you use our Service, we automatically collect certain information:</p>

              <p className="text-slate-300 font-semibold mt-4">Device Information:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Device type (iPhone, iPad, Android, Web browser)</li>
                <li>Operating system version</li>
                <li>App version</li>
                <li>Unique device identifiers</li>
              </ul>

              <p className="text-slate-300 font-semibold mt-4">Location Information:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Approximate location (city/zip code level) to show nearest KnockBites locations</li>
                <li>We DO NOT track your precise GPS location without explicit permission</li>
              </ul>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">How We Use Your Information</h2>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">Order Fulfillment</h3>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Processing and preparing your food orders</li>
                <li>Contacting you when your order is ready</li>
                <li>Handling special requests or dietary requirements</li>
                <li>Providing customer support</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">Service Improvement</h3>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Analyzing usage patterns to improve our menu and app features</li>
                <li>Fixing bugs and technical issues</li>
                <li>Understanding which menu items are most popular</li>
                <li>Optimizing order preparation times</li>
              </ul>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">How We Share Your Information</h2>
              <p className="text-slate-300 font-bold text-lg">We DO NOT sell your personal information to third parties.</p>
              <p className="text-slate-300">We only share your information in the following limited circumstances:</p>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">With Our Staff</h3>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li>Store employees see your name and phone number to prepare and fulfill your order</li>
                <li>This information is only visible to staff at the specific store you're ordering from</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">With Service Providers</h3>
              <p className="text-slate-300">We work with trusted third-party companies to provide our Service:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Supabase (Database & Auth)</strong> - SOC 2 Type II compliant, stores data securely</li>
                <li><strong>Vercel (Web Hosting)</strong> - Hosts our website infrastructure</li>
                <li><strong>Apple (Push Notifications)</strong> - Delivers order status notifications on iOS</li>
              </ul>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Data Security</h2>
              <p className="text-slate-300">We take data security seriously and implement industry-standard measures:</p>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">Technical Safeguards</h3>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Encryption in Transit</strong> - All data transmitted uses HTTPS/TLS encryption</li>
                <li><strong>Encryption at Rest</strong> - Database contents encrypted using AES-256</li>
                <li><strong>Secure Authentication</strong> - Passwords hashed using bcrypt with salt</li>
                <li><strong>Row Level Security</strong> - Database access restricted based on user roles</li>
              </ul>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Your Privacy Rights</h2>
              <p className="text-slate-300">Depending on your location, you may have the following rights:</p>

              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Right to Access</strong> - Request a copy of the personal data we hold about you</li>
                <li><strong>Right to Correction</strong> - Update or correct inaccurate information</li>
                <li><strong>Right to Deletion</strong> - Request deletion of your personal data</li>
                <li><strong>Right to Opt-Out</strong> - Unsubscribe from marketing communications</li>
              </ul>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">How to Exercise Your Rights</h3>
              <p className="text-slate-300">To exercise any of these rights, please contact us at:</p>
              <ul className="text-slate-300 list-none pl-0 space-y-1 mt-3">
                <li><strong>Email:</strong> jaydeli@outonemail.com</li>
                <li><strong>Phone:</strong> (845) 928-2883</li>
                <li><strong>Mail:</strong> 634 NY-32, Highland Mills, NY 10930</li>
              </ul>
              <p className="text-slate-300 mt-3">We will respond to your request within 30 days.</p>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Data Retention</h2>
              <p className="text-slate-300">We retain your personal information for as long as necessary to provide our Service:</p>
              <ul className="text-slate-300 list-disc pl-6 space-y-2">
                <li><strong>Order History</strong> - Retained for 2 years for accounting and customer service</li>
                <li><strong>Account Data</strong> - Retained until you request account deletion</li>
                <li><strong>Payment Information</strong> - Not stored (we accept payment at pickup only)</li>
                <li><strong>Usage Analytics</strong> - Aggregated data retained indefinitely (anonymized)</li>
              </ul>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Children's Privacy</h2>
              <p className="text-slate-300">
                KnockBites is not directed to children under 13 years of age. We do not knowingly collect
                personal information from children under 13. If you are a parent or guardian and believe your child
                has provided us with personal information, please contact us immediately so we can delete it.
              </p>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Location-Specific Privacy Rights</h2>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">California Residents (CCPA)</h3>
              <p className="text-slate-300">
                If you are a California resident, you have additional rights under the California Consumer Privacy Act.
              </p>
              <p className="text-slate-300 font-bold mt-3">We do NOT sell your personal information.</p>

              <h3 className="text-xl font-semibold text-white mt-6 mb-3">European Union Residents (GDPR)</h3>
              <p className="text-slate-300">
                If you are in the EU/EEA, you have additional rights under GDPR including the right to withdraw consent
                at any time and the right to lodge a complaint with a supervisory authority.
              </p>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Changes to This Privacy Policy</h2>
              <p className="text-slate-300">
                We may update this Privacy Policy from time to time to reflect changes in our practices or for legal,
                operational, or regulatory reasons. Material changes will be communicated via email or in-app notification.
              </p>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Contact Us</h2>
              <p className="text-slate-300">
                If you have questions, concerns, or requests regarding this Privacy Policy, please contact us:
              </p>
              <div className="bg-slate-700/50 p-6 rounded-lg mt-4">
                <p className="text-white font-semibold text-lg">Highland Mills Snack Shop Inc.</p>
                <p className="text-slate-300">634 NY-32, Highland Mills, NY 10930</p>
                <p className="text-slate-300 mt-2">
                  <strong>Email:</strong> jaydeli@outonemail.com<br />
                  <strong>Phone:</strong> (845) 928-2883<br />
                  <strong>Hours:</strong> Monday - Sunday, 24/7
                </p>
              </div>

              <h2 className="text-2xl font-bold text-white mt-8 mb-4">Summary (TL;DR)</h2>
              <div className="bg-blue-900/30 border border-blue-700 p-6 rounded-lg">
                <p className="text-white font-semibold mb-3">What we collect:</p>
                <ul className="text-slate-300 list-disc pl-6 space-y-1 mb-4">
                  <li>Name and phone number for orders</li>
                  <li>Email for account creation (optional)</li>
                  <li>Usage data to improve the app</li>
                </ul>

                <p className="text-white font-semibold mb-3">What we DON'T do:</p>
                <ul className="text-slate-300 list-disc pl-6 space-y-1 mb-4">
                  <li>❌ We don't sell your data</li>
                  <li>❌ We don't share data with advertisers</li>
                  <li>❌ We don't track your precise location</li>
                  <li>❌ We don't send spam</li>
                </ul>

                <p className="text-white font-semibold mb-3">Your rights:</p>
                <ul className="text-slate-300 list-disc pl-6 space-y-1">
                  <li>✅ Request your data</li>
                  <li>✅ Delete your account</li>
                  <li>✅ Opt-out of marketing</li>
                  <li>✅ Update your information</li>
                </ul>
              </div>

              <p className="text-slate-400 text-center mt-8 pt-8 border-t border-slate-700">
                This Privacy Policy is effective as of December 1, 2024.<br />
                Thank you for trusting KnockBites with your food orders!
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
