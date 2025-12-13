import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Cookie, Settings, BarChart, Target, Shield } from "lucide-react";
import { Button } from "@/components/ui/button";

const CookiePolicy = () => {
  const lastUpdated = "November 14, 2024";

  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      <main className="pt-24 pb-16">
        <div className="container mx-auto px-4 max-w-4xl">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-accent/10 rounded-full mb-4">
              <Cookie className="h-8 w-8 text-accent" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold mb-4">Cookie Policy</h1>
            <p className="text-lg text-muted-foreground">
              Last updated: {lastUpdated}
            </p>
          </div>

          {/* Quick Overview */}
          <Card className="mb-8 border-accent/20 bg-accent/5">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Cookie className="h-5 w-5 text-accent" />
                What Are Cookies?
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                Cookies are small text files stored on your device when you visit our website.
                They help us provide you with a better experience by remembering your preferences,
                keeping you signed in, and understanding how you use our services.
              </p>
            </CardContent>
          </Card>

          {/* Main Content */}
          <div className="space-y-8">
            <Card>
              <CardHeader>
                <CardTitle>1. How We Use Cookies</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  KnockBites uses cookies and similar tracking technologies to:
                </p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Keep you signed in to your account</li>
                  <li>Remember your preferences and settings</li>
                  <li>Understand how you use our website</li>
                  <li>Improve our services and user experience</li>
                  <li>Provide personalized content and recommendations</li>
                  <li>Analyze website traffic and performance</li>
                  <li>Deliver relevant advertisements</li>
                  <li>Prevent fraud and enhance security</li>
                </ul>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>2. Types of Cookies We Use</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <Shield className="h-5 w-5 text-accent" />
                    <h3 className="font-semibold text-lg">Essential Cookies</h3>
                  </div>
                  <p className="text-muted-foreground mb-2">
                    Required for the website to function properly. Cannot be disabled.
                  </p>
                  <div className="bg-muted/30 p-4 rounded-lg space-y-1 text-sm">
                    <p><strong>Purpose:</strong> Authentication, security, basic functionality</p>
                    <p><strong>Duration:</strong> Session or up to 1 year</p>
                    <p><strong>Examples:</strong> Login session, shopping cart, security tokens</p>
                  </div>
                </div>

                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <BarChart className="h-5 w-5 text-accent" />
                    <h3 className="font-semibold text-lg">Performance Cookies</h3>
                  </div>
                  <p className="text-muted-foreground mb-2">
                    Help us understand how visitors interact with our website.
                  </p>
                  <div className="bg-muted/30 p-4 rounded-lg space-y-1 text-sm">
                    <p><strong>Purpose:</strong> Analytics, site performance monitoring</p>
                    <p><strong>Duration:</strong> Up to 2 years</p>
                    <p><strong>Examples:</strong> Google Analytics, page load times, error tracking</p>
                    <p><strong>Third Parties:</strong> Google Analytics, Hotjar</p>
                  </div>
                </div>

                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <Settings className="h-5 w-5 text-accent" />
                    <h3 className="font-semibold text-lg">Functional Cookies</h3>
                  </div>
                  <p className="text-muted-foreground mb-2">
                    Remember your preferences and provide enhanced features.
                  </p>
                  <div className="bg-muted/30 p-4 rounded-lg space-y-1 text-sm">
                    <p><strong>Purpose:</strong> User preferences, personalization</p>
                    <p><strong>Duration:</strong> Up to 1 year</p>
                    <p>
                      <strong>Examples:</strong> Language preference, location, display settings,
                      recent searches
                    </p>
                  </div>
                </div>

                <div>
                  <div className="flex items-center gap-2 mb-2">
                    <Target className="h-5 w-5 text-accent" />
                    <h3 className="font-semibold text-lg">Marketing Cookies</h3>
                  </div>
                  <p className="text-muted-foreground mb-2">
                    Used to deliver personalized advertisements and measure campaign effectiveness.
                  </p>
                  <div className="bg-muted/30 p-4 rounded-lg space-y-1 text-sm">
                    <p><strong>Purpose:</strong> Advertising, retargeting, campaign tracking</p>
                    <p><strong>Duration:</strong> Up to 2 years</p>
                    <p>
                      <strong>Examples:</strong> Ad preferences, conversion tracking, social media
                      pixels
                    </p>
                    <p><strong>Third Parties:</strong> Facebook, Google Ads, Instagram</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>3. Third-Party Cookies</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  We use services from trusted third-party providers that may set their own
                  cookies:
                </p>

                <div className="space-y-4">
                  <div className="border-l-4 border-accent pl-4">
                    <h4 className="font-semibold mb-1">Google Analytics</h4>
                    <p className="text-sm text-muted-foreground">
                      Helps us understand website traffic and user behavior.
                    </p>
                    <a
                      href="https://policies.google.com/privacy"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-accent hover:underline"
                    >
                      Google Privacy Policy →
                    </a>
                  </div>

                  <div className="border-l-4 border-accent pl-4">
                    <h4 className="font-semibold mb-1">Stripe</h4>
                    <p className="text-sm text-muted-foreground">
                      Processes payments securely and prevents fraud.
                    </p>
                    <a
                      href="https://stripe.com/privacy"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-accent hover:underline"
                    >
                      Stripe Privacy Policy →
                    </a>
                  </div>

                  <div className="border-l-4 border-accent pl-4">
                    <h4 className="font-semibold mb-1">Social Media Platforms</h4>
                    <p className="text-sm text-muted-foreground">
                      Facebook, Instagram, and Twitter may set cookies for social sharing features.
                    </p>
                  </div>

                  <div className="border-l-4 border-accent pl-4">
                    <h4 className="font-semibold mb-1">Cloudflare</h4>
                    <p className="text-sm text-muted-foreground">
                      Provides security and performance optimization for our website.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>4. Managing Your Cookie Preferences</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Browser Settings</h3>
                  <p className="text-muted-foreground mb-2">
                    You can control cookies through your browser settings:
                  </p>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>
                      <strong>Chrome:</strong> Settings → Privacy and security → Cookies and other
                      site data
                    </li>
                    <li>
                      <strong>Firefox:</strong> Settings → Privacy & Security → Cookies and Site
                      Data
                    </li>
                    <li>
                      <strong>Safari:</strong> Preferences → Privacy → Manage Website Data
                    </li>
                    <li>
                      <strong>Edge:</strong> Settings → Cookies and site permissions → Manage and
                      delete cookies
                    </li>
                  </ul>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Our Cookie Consent Tool</h3>
                  <p className="text-muted-foreground mb-4">
                    You can manage your cookie preferences using our consent tool. Click the
                    button below to update your settings:
                  </p>
                  <Button variant="secondary">
                    <Settings className="h-4 w-4 mr-2" />
                    Manage Cookie Preferences
                  </Button>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Opt-Out Links</h3>
                  <ul className="space-y-2">
                    <li>
                      <a
                        href="https://tools.google.com/dlpage/gaoptout"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-accent hover:underline"
                      >
                        Google Analytics Opt-Out →
                      </a>
                    </li>
                    <li>
                      <a
                        href="https://optout.aboutads.info/"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-accent hover:underline"
                      >
                        Digital Advertising Alliance Opt-Out →
                      </a>
                    </li>
                    <li>
                      <a
                        href="https://optout.networkadvertising.org/"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-accent hover:underline"
                      >
                        Network Advertising Initiative Opt-Out →
                      </a>
                    </li>
                  </ul>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>5. Do Not Track Signals</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground">
                  Some browsers have a "Do Not Track" feature that signals websites you visit that
                  you do not want to be tracked. Currently, there is no industry standard for how
                  to respond to these signals. We do not currently respond to Do Not Track signals.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>6. Impact of Disabling Cookies</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  If you disable cookies, some features may not work properly:
                </p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>You may not be able to stay signed in</li>
                  <li>Your preferences and settings won't be saved</li>
                  <li>Shopping cart functionality may be limited</li>
                  <li>Some pages may not display correctly</li>
                  <li>You may see less relevant advertisements</li>
                </ul>
                <p className="text-muted-foreground">
                  Essential cookies cannot be disabled as they are necessary for the website to
                  function.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>7. Mobile Devices</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  When you use our mobile app, we may use similar technologies to cookies:
                </p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Device identifiers (IDFA for iOS, AAID for Android)</li>
                  <li>Local storage</li>
                  <li>Mobile analytics SDKs</li>
                </ul>
                <p className="text-muted-foreground mt-4">
                  You can control mobile tracking through your device settings:
                </p>
                <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                  <li>
                    <strong>iOS:</strong> Settings → Privacy → Tracking
                  </li>
                  <li>
                    <strong>Android:</strong> Settings → Google → Ads → Opt out of Ads
                    Personalization
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>8. Updates to This Policy</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground">
                  We may update this Cookie Policy from time to time to reflect changes in our
                  practices or legal requirements. We will notify you of significant changes by
                  posting a notice on our website or updating the "Last Updated" date.
                </p>
              </CardContent>
            </Card>

            <Card className="bg-accent/5 border-accent/20">
              <CardHeader>
                <CardTitle>Questions About Cookies?</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <p className="text-muted-foreground">
                  If you have questions about our use of cookies, please contact us:
                </p>
                <div className="space-y-1 text-muted-foreground">
                  <p>
                    <strong>Email:</strong>{" "}
                    <a
                      href="mailto:privacy@knockbites.com"
                      className="text-accent hover:underline"
                    >
                      privacy@knockbites.com
                    </a>
                  </p>
                  <p>
                    <strong>Phone:</strong> 1-800-KNOCKBITES
                  </p>
                </div>
                <div className="pt-4">
                  <p className="text-sm text-muted-foreground">
                    For more information, see our{" "}
                    <a href="/privacy-policy" className="text-accent hover:underline">
                      Privacy Policy
                    </a>{" "}
                    and{" "}
                    <a href="/terms-of-service" className="text-accent hover:underline">
                      Terms of Service
                    </a>
                    .
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default CookiePolicy;
