import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { FileText, ShoppingCart, CreditCard, RefreshCw, AlertTriangle, Scale } from "lucide-react";

const TermsOfService = () => {
  const lastUpdated = "November 14, 2024";

  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      <main className="pt-24 pb-16">
        <div className="container mx-auto px-4 max-w-4xl">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-secondary/10 rounded-full mb-4">
              <FileText className="h-8 w-8 text-secondary" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold mb-4">Terms of Service</h1>
            <p className="text-lg text-muted-foreground">
              Last updated: {lastUpdated}
            </p>
          </div>

          {/* Quick Overview */}
          <Card className="mb-8 border-secondary/20 bg-secondary/5">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Scale className="h-5 w-5 text-secondary" />
                Agreement Overview
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">
                By accessing and using KnockBites services, you agree to be bound by these
                Terms of Service. Please read them carefully. If you do not agree with any part
                of these terms, you may not use our services.
              </p>
            </CardContent>
          </Card>

          {/* Main Content */}
          <div className="space-y-8">
            <Card>
              <CardHeader>
                <CardTitle>1. Acceptance of Terms</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  These Terms of Service ("Terms") govern your access to and use of KnockBites
                  Connect website, mobile application, and related services (collectively, the
                  "Services"). By creating an account or placing an order, you acknowledge that
                  you have read, understood, and agree to be bound by these Terms.
                </p>
                <p className="text-muted-foreground">
                  We reserve the right to modify these Terms at any time. Your continued use of
                  the Services after changes are posted constitutes acceptance of the modified
                  Terms.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>2. Eligibility</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  To use our Services, you must:
                </p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Be at least 13 years of age</li>
                  <li>Have the legal capacity to enter into a binding contract</li>
                  <li>Not be prohibited from using our Services under applicable law</li>
                  <li>Provide accurate and complete registration information</li>
                  <li>Maintain the security of your account credentials</li>
                </ul>
                <p className="text-muted-foreground">
                  By using our Services, you represent and warrant that you meet these eligibility
                  requirements.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>3. Account Registration</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  When you create an account, you agree to:
                </p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Provide accurate, current, and complete information</li>
                  <li>Maintain and update your information to keep it accurate</li>
                  <li>Keep your password secure and confidential</li>
                  <li>Not share your account with others</li>
                  <li>Notify us immediately of any unauthorized access</li>
                  <li>Be responsible for all activities under your account</li>
                </ul>
                <p className="text-muted-foreground mt-4">
                  We reserve the right to suspend or terminate accounts that violate these Terms
                  or engage in fraudulent activity.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ShoppingCart className="h-5 w-5 text-secondary" />
                  4. Ordering and Fulfillment
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Order Placement</h3>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>All orders are subject to acceptance and availability</li>
                    <li>We reserve the right to refuse or cancel any order</li>
                    <li>Prices are subject to change without notice</li>
                    <li>Menu items and availability may vary by location</li>
                  </ul>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Order Confirmation</h3>
                  <p className="text-muted-foreground">
                    You will receive an order confirmation via email or SMS. This confirmation
                    does not constitute acceptance of your order. We accept your order when we
                    begin preparing it.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Pickup and Timing</h3>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>Estimated ready times are approximate and not guaranteed</li>
                    <li>You must pick up orders within 30 minutes of notification</li>
                    <li>Orders not picked up may be cancelled without refund</li>
                    <li>Special instructions are accommodated when possible but not guaranteed</li>
                  </ul>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <CreditCard className="h-5 w-5 text-secondary" />
                  5. Payment Terms
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Accepted Payment Methods</h3>
                  <p className="text-muted-foreground">
                    We accept credit cards, debit cards, Apple Pay, Google Pay, and cash at
                    pickup. All online payments are processed securely through our payment
                    provider.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Pricing and Fees</h3>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>All prices are in USD and include applicable taxes</li>
                    <li>Service fees may apply to online orders</li>
                    <li>Promotional codes are subject to terms and conditions</li>
                    <li>We reserve the right to correct pricing errors</li>
                  </ul>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Payment Authorization</h3>
                  <p className="text-muted-foreground">
                    By providing payment information, you authorize us to charge the total amount
                    to your payment method. You represent that you have the legal right to use
                    the payment method provided.
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <RefreshCw className="h-5 w-5 text-secondary" />
                  6. Cancellations and Refunds
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Order Cancellation</h3>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>You may cancel orders before preparation begins</li>
                    <li>Cancellation requests must be made through your account or by calling the store</li>
                    <li>Orders cannot be cancelled once preparation has started</li>
                    <li>We reserve the right to cancel orders for any reason</li>
                  </ul>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Refund Policy</h3>
                  <ul className="list-disc list-inside space-y-1 text-muted-foreground ml-4">
                    <li>Refunds are issued to the original payment method</li>
                    <li>Processing time may take 5-10 business days</li>
                    <li>Partial refunds may be issued for missing or incorrect items</li>
                    <li>Quality issues must be reported within 24 hours</li>
                    <li>Promotional discounts are not refundable</li>
                  </ul>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Quality Guarantee</h3>
                  <p className="text-muted-foreground">
                    If you're not satisfied with your order quality, please contact us within 24
                    hours. We'll work to make it right with a refund, credit, or replacement.
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>7. Rewards and Loyalty Program</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Rewards points have no cash value and cannot be transferred</li>
                  <li>Points expire 12 months after earning if account is inactive</li>
                  <li>We reserve the right to modify or terminate the program</li>
                  <li>Fraudulent activity may result in forfeiture of points</li>
                  <li>Points are earned on eligible purchases only</li>
                  <li>Promotional bonus points may have different terms</li>
                </ul>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-secondary" />
                  8. Prohibited Conduct
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">You agree not to:</p>
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>Use the Services for any illegal purpose</li>
                  <li>Violate any applicable laws or regulations</li>
                  <li>Infringe on intellectual property rights</li>
                  <li>Transmit viruses, malware, or harmful code</li>
                  <li>Attempt to gain unauthorized access to our systems</li>
                  <li>Impersonate others or provide false information</li>
                  <li>Engage in fraudulent payment activity</li>
                  <li>Harass, abuse, or harm others</li>
                  <li>Scrape, copy, or misuse our content</li>
                  <li>Interfere with the proper functioning of the Services</li>
                </ul>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>9. Intellectual Property</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  All content on our Services, including text, graphics, logos, images, and
                  software, is the property of KnockBites or its licensors and is protected
                  by copyright, trademark, and other intellectual property laws.
                </p>
                <p className="text-muted-foreground">
                  You may not copy, modify, distribute, or create derivative works without our
                  express written permission.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>10. Disclaimers and Limitation of Liability</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Service Disclaimer</h3>
                  <p className="text-muted-foreground">
                    THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY
                    KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE SERVICES WILL BE
                    UNINTERRUPTED, SECURE, OR ERROR-FREE.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Limitation of Liability</h3>
                  <p className="text-muted-foreground">
                    TO THE MAXIMUM EXTENT PERMITTED BY LAW, CAMERON'S CONNECT SHALL NOT BE LIABLE
                    FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES,
                    OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY.
                  </p>
                  <p className="text-muted-foreground mt-2">
                    Our total liability for any claim shall not exceed the amount you paid for
                    the specific order giving rise to the claim.
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>11. Indemnification</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground">
                  You agree to indemnify, defend, and hold harmless KnockBites and its
                  officers, directors, employees, and agents from any claims, liabilities,
                  damages, losses, and expenses arising from your use of the Services or
                  violation of these Terms.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>12. Dispute Resolution</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="font-semibold text-lg mb-2">Governing Law</h3>
                  <p className="text-muted-foreground">
                    These Terms are governed by the laws of the State of New York, without regard
                    to conflict of law principles.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-lg mb-2">Arbitration</h3>
                  <p className="text-muted-foreground">
                    Any dispute arising from these Terms shall be resolved through binding
                    arbitration in accordance with the American Arbitration Association rules.
                    You waive your right to participate in class action lawsuits.
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>13. General Provisions</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <ul className="list-disc list-inside space-y-2 text-muted-foreground ml-4">
                  <li>
                    <strong>Severability:</strong> If any provision is found invalid, the
                    remaining provisions remain in effect
                  </li>
                  <li>
                    <strong>Waiver:</strong> Our failure to enforce any right does not waive that
                    right
                  </li>
                  <li>
                    <strong>Assignment:</strong> You may not assign these Terms without our
                    consent
                  </li>
                  <li>
                    <strong>Entire Agreement:</strong> These Terms constitute the entire agreement
                    between you and KnockBites
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="bg-secondary/5 border-secondary/20">
              <CardHeader>
                <CardTitle>Contact Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <p className="text-muted-foreground">
                  Questions about these Terms? Contact us:
                </p>
                <div className="space-y-1 text-muted-foreground">
                  <p>
                    <strong>Email:</strong>{" "}
                    <a
                      href="mailto:legal@knockbites.com"
                      className="text-secondary hover:underline"
                    >
                      legal@knockbites.com
                    </a>
                  </p>
                  <p>
                    <strong>Phone:</strong> 1-800-KNOCKBITES
                  </p>
                  <p>
                    <strong>Mail:</strong> KnockBites, Legal Department, 123 Main Street,
                    New York, NY 10001
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

export default TermsOfService;
