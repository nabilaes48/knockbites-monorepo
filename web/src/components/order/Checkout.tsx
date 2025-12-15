import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { User, Phone, Mail, CreditCard, Clock, MapPin, ShieldCheck, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";

interface CartItem {
  id: number;
  name: string;
  price: number;
  quantity: number;
  customizations?: string[]; // Human-readable: ["Cheese: Extra Cheese"]
  selectedOptions?: Record<string, string[]>; // Raw data: {"group_cheese": ["extra_cheese"]}
}

interface CheckoutProps {
  items: CartItem[];
  storeId: number | null;
  storeName?: string;
}

export const Checkout = ({ items, storeId, storeName }: CheckoutProps) => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user, profile, isCustomer } = useAuth();

  // Get user's first name for personalization
  const firstName = profile?.full_name?.split(' ')[0] || '';
  const [isProcessing, setIsProcessing] = useState(false);

  // Guest checkout - no login required!
  const [guestInfo, setGuestInfo] = useState({
    name: "",
    phone: "",
    email: "",
    specialInstructions: "",
  });

  // Email verification state - skip verification if user is logged in
  const [verificationStep, setVerificationStep] = useState<'info' | 'verify' | 'verified'>(
    user && isCustomer ? 'verified' : 'info'
  );
  const [verificationCode, setVerificationCode] = useState("");
  const [isSendingCode, setIsSendingCode] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [pendingOrderError, setPendingOrderError] = useState(false);
  const [fallbackCode, setFallbackCode] = useState<string | null>(null); // Show code when email fails

  // Pre-fill form if user is logged in and auto-verify
  useEffect(() => {
    if (user && profile && isCustomer) {
      setGuestInfo({
        name: profile.full_name || "",
        phone: profile.phone || "",
        email: profile.email || user.email || "",
        specialInstructions: "",
      });
      // Skip verification for logged-in customers
      setVerificationStep('verified');
    }
  }, [user, profile, isCustomer]);

  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = subtotal * 0.08;
  const total = subtotal + tax;

  // Send verification code to email
  const handleSendVerificationCode = async () => {
    if (!guestInfo.email || !guestInfo.name || !guestInfo.phone) {
      toast({
        title: "Missing Information",
        description: "Please fill in name, phone, and email before verifying.",
        variant: "destructive",
      });
      return;
    }

    setIsSendingCode(true);
    setPendingOrderError(false);

    try {
      // Call Supabase function to create verification
      const { data, error } = await supabase.rpc('create_order_verification', {
        p_email: guestInfo.email,
        p_phone: guestInfo.phone,
      });

      if (error) throw error;

      // Check if customer has pending orders
      if (data && data[0]?.pending_order_exists) {
        setPendingOrderError(true);
        toast({
          title: "Pending Order Exists",
          description: "You have an unpaid order. Please complete or cancel it before placing a new order.",
          variant: "destructive",
        });
        return;
      }

      // Check for rate limiting
      if (data && data[0]?.rate_limited) {
        toast({
          title: "Too Many Requests",
          description: "Please wait a few minutes before requesting another code.",
          variant: "destructive",
        });
        return;
      }

      const code = data[0]?.code;
      const verificationId = data[0]?.verification_id;
      console.log(`📧 Verification code generated for ${guestInfo.email}`);

      // Send verification email via Edge Function
      let emailSent = false;
      try {
        const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
        const response = await fetch(`${supabaseUrl}/functions/v1/send-verification-email`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({
            email: guestInfo.email,
            code: code,
            phone: guestInfo.phone,
            expiresAt: data[0]?.expires_at,
          }),
        });

        if (response.ok) {
          emailSent = true;
        } else {
          console.warn('Email sending failed:', await response.text());
        }
      } catch (emailError) {
        console.warn('Email service unavailable:', emailError);
      }

      if (emailSent) {
        toast({
          title: "Verification Code Sent!",
          description: "Check your email for the 6-digit code.",
        });
        setFallbackCode(null);
      } else {
        // Email failed but code was generated - show the code directly in UI
        setFallbackCode(code);
        toast({
          title: "Verification Ready",
          description: "Your code is shown below.",
        });
      }

      setVerificationStep('verify');
    } catch (error: any) {
      console.error('Error sending verification:', error);
      toast({
        title: "Verification Failed",
        description: error.message || "Failed to send verification code.",
        variant: "destructive",
      });
    } finally {
      setIsSendingCode(false);
    }
  };

  // Verify the code
  const handleVerifyCode = async () => {
    if (verificationCode.length !== 6) {
      toast({
        title: "Invalid Code",
        description: "Please enter the 6-digit code.",
        variant: "destructive",
      });
      return;
    }

    setIsVerifying(true);

    try {
      const { data, error } = await supabase.rpc('verify_order_code', {
        p_email: guestInfo.email,
        p_code: verificationCode,
      });

      if (error) throw error;

      if (data && data[0]?.success) {
        setVerificationStep('verified');
        toast({
          title: "Email Verified!",
          description: "You can now place your order.",
        });
      } else {
        toast({
          title: "Invalid Code",
          description: data[0]?.message || "The code is invalid or expired.",
          variant: "destructive",
        });
      }
    } catch (error: any) {
      console.error('Error verifying code:', error);
      toast({
        title: "Verification Failed",
        description: error.message || "Failed to verify code.",
        variant: "destructive",
      });
    } finally {
      setIsVerifying(false);
    }
  };

  const handleSubmitOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsProcessing(true);

    try {
      // Validate store is selected
      if (!storeId) {
        throw new Error("Please select a store location");
      }

      console.log('📤 Submitting order to Supabase:');
      console.log(`   - Store ID: ${storeId}`);
      console.log(`   - Customer: ${guestInfo.name}`);
      console.log(`   - Logged in: ${user ? 'Yes' : 'No'}`);
      console.log(`   - Items: ${items.length}`);
      console.log(`   - Total: $${total.toFixed(2)}`);

      // Create order in Supabase (with user_id and customer_id if logged in)
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
          store_id: storeId,
          user_id: user?.id || null, // Link to auth.users if logged in
          customer_id: user?.id || null, // Link to customers table for rewards system
          customer_name: guestInfo.name,
          customer_phone: guestInfo.phone,
          customer_email: guestInfo.email || null,
          status: 'pending',
          priority: total >= 100 ? 'vip' : 'normal',
          subtotal: subtotal,
          tax: tax,
          tip: 0,
          total: total,
          order_type: 'pickup',
          estimated_ready_at: new Date(Date.now() + 20 * 60000).toISOString(),
          special_instructions: guestInfo.specialInstructions || null,
          is_repeat_customer: false,
        })
        .select()
        .single();

      if (orderError) throw orderError;

      // Create order items with iOS-compatible format
      const orderItems = items.map(item => {
        console.log(`📦 Adding item: ${item.name} x${item.quantity}`);
        if (item.customizations && item.customizations.length > 0) {
          console.log(`   🎛️ Customizations: ${item.customizations.join(', ')}`);
        }

        return {
          order_id: order.id,
          menu_item_id: item.id,
          item_name: item.name,
          item_price: item.price,
          quantity: item.quantity,
          // Human-readable customizations for business app display
          customizations: item.customizations || [],
          // Raw customization data for advanced processing (iOS format)
          selected_options: item.selectedOptions || {},
          subtotal: item.price * item.quantity,
          notes: null,
        };
      });

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) throw itemsError;

      console.log(`✅ Order submitted successfully: #${order.order_number}`);

      setIsProcessing(false);

      // Personalized thank you message
      const thankYouName = firstName || guestInfo.name.split(' ')[0];
      toast({
        title: `Thank you, ${thankYouName}!`,
        description: `Order #${order.order_number} - Ready in 15-20 minutes`,
      });

      // Navigate to order tracking
      navigate(`/order/tracking/${order.id}`);
    } catch (error: any) {
      console.error('Error placing order:', error);
      setIsProcessing(false);

      toast({
        title: "Order Failed",
        description: error.message || "Failed to place order. Please try again.",
        variant: "destructive",
      });
    }
  };

  const isFormValid = guestInfo.name && guestInfo.phone && guestInfo.email && items.length > 0 && verificationStep === 'verified';

  return (
    <div className="max-w-4xl mx-auto">
      {/* Personalized Header */}
      <div className="text-center mb-6">
        {user && isCustomer && firstName ? (
          <>
            <h2 className="text-3xl font-bold mb-2">
              Almost there, {firstName}!
            </h2>
            <p className="text-muted-foreground">
              Review your order and confirm your details
            </p>
          </>
        ) : (
          <h2 className="text-3xl font-bold">Checkout</h2>
        )}
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Checkout Form */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                {user && isCustomer ? `Welcome back, ${profile?.full_name || 'Customer'}!` : 'Guest Checkout'}
              </CardTitle>
              <p className="text-sm text-muted-foreground">
                {user && isCustomer
                  ? "Your information has been pre-filled. Review and confirm your order."
                  : "No account needed! Just provide your contact info."
                }
              </p>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmitOrder} className="space-y-4">
                {/* Logged-in Customer Info Display */}
                {user && isCustomer && profile ? (
                  <div className="bg-green-50 dark:bg-green-950 rounded-lg p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-green-700 dark:text-green-300">Your Information</span>
                      <Badge className="bg-green-500">
                        <ShieldCheck className="h-3 w-3 mr-1" />
                        Verified Account
                      </Badge>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div className="bg-white dark:bg-gray-800 rounded-md p-3">
                        <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1">
                          <User className="h-3 w-3" />
                          Name
                        </div>
                        <p className="font-medium">{guestInfo.name || 'Not set'}</p>
                      </div>
                      <div className="bg-white dark:bg-gray-800 rounded-md p-3">
                        <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1">
                          <Phone className="h-3 w-3" />
                          Phone
                        </div>
                        <p className="font-medium">{guestInfo.phone || 'Not set'}</p>
                      </div>
                      <div className="bg-white dark:bg-gray-800 rounded-md p-3">
                        <div className="flex items-center gap-2 text-muted-foreground text-xs mb-1">
                          <Mail className="h-3 w-3" />
                          Email
                        </div>
                        <p className="font-medium text-sm truncate">{guestInfo.email || 'Not set'}</p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <>
                    {/* Name */}
                    <div>
                      <Label htmlFor="name">Full Name *</Label>
                      <Input
                        id="name"
                        type="text"
                        placeholder="John Doe"
                        value={guestInfo.name}
                        onChange={(e) => setGuestInfo({ ...guestInfo, name: e.target.value })}
                        required
                      />
                    </div>

                    {/* Phone */}
                    <div>
                      <Label htmlFor="phone">Phone Number *</Label>
                      <Input
                        id="phone"
                        type="tel"
                        placeholder="(555) 123-4567"
                        value={guestInfo.phone}
                        onChange={(e) => setGuestInfo({ ...guestInfo, phone: e.target.value })}
                        required
                      />
                      <p className="text-xs text-muted-foreground mt-1">
                        We'll text you when your order is ready
                      </p>
                    </div>

                    {/* Email (Required for verification) */}
                    <div>
                      <Label htmlFor="email">Email * (Required for verification)</Label>
                      <div className="flex gap-2">
                        <Input
                          id="email"
                          type="email"
                          placeholder="john@example.com"
                          value={guestInfo.email}
                          onChange={(e) => {
                            setGuestInfo({ ...guestInfo, email: e.target.value });
                            // Reset verification if email changes
                            if (verificationStep !== 'info') {
                              setVerificationStep('info');
                              setVerificationCode("");
                              setFallbackCode(null);
                            }
                          }}
                          disabled={verificationStep === 'verified'}
                          required
                        />
                        {verificationStep === 'verified' && (
                          <Badge className="bg-green-500 flex items-center gap-1">
                            <ShieldCheck className="h-3 w-3" />
                            Verified
                          </Badge>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1">
                        We'll send a verification code to confirm your email
                      </p>
                    </div>
                  </>
                )}

                {/* Verification Section - Only for guests */}
                {!user && verificationStep === 'info' && guestInfo.email && guestInfo.name && guestInfo.phone && (
                  <div className="bg-blue-50 dark:bg-blue-950 p-4 rounded-lg">
                    <p className="text-sm font-medium mb-2">Verify your email to continue</p>
                    <Button
                      type="button"
                      onClick={handleSendVerificationCode}
                      disabled={isSendingCode}
                      className="w-full"
                    >
                      {isSendingCode ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Sending Code...
                        </>
                      ) : (
                        <>
                          <Mail className="mr-2 h-4 w-4" />
                          Send Verification Code
                        </>
                      )}
                    </Button>
                    {pendingOrderError && (
                      <p className="text-sm text-red-600 mt-2">
                        You have an existing unpaid order. Please pick up or cancel it first.
                      </p>
                    )}
                  </div>
                )}

                {!user && verificationStep === 'verify' && (
                  <div className="bg-yellow-50 dark:bg-yellow-950 p-4 rounded-lg space-y-3">
                    {fallbackCode ? (
                      <div className="bg-green-100 dark:bg-green-900 p-3 rounded-lg text-center mb-2">
                        <p className="text-xs text-green-700 dark:text-green-300 mb-1">Your verification code:</p>
                        <p className="text-2xl font-bold tracking-widest text-green-800 dark:text-green-200">{fallbackCode}</p>
                      </div>
                    ) : (
                      <p className="text-sm font-medium">Enter the 6-digit code sent to {guestInfo.email}</p>
                    )}
                    <div className="flex justify-center">
                      <InputOTP
                        maxLength={6}
                        value={verificationCode}
                        onChange={(value) => setVerificationCode(value)}
                      >
                        <InputOTPGroup>
                          <InputOTPSlot index={0} />
                          <InputOTPSlot index={1} />
                          <InputOTPSlot index={2} />
                          <InputOTPSlot index={3} />
                          <InputOTPSlot index={4} />
                          <InputOTPSlot index={5} />
                        </InputOTPGroup>
                      </InputOTP>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => {
                          setVerificationStep('info');
                          setVerificationCode("");
                          setFallbackCode(null);
                        }}
                        className="flex-1"
                      >
                        Change Email
                      </Button>
                      <Button
                        type="button"
                        onClick={handleVerifyCode}
                        disabled={isVerifying || verificationCode.length !== 6}
                        className="flex-1"
                      >
                        {isVerifying ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            Verifying...
                          </>
                        ) : (
                          "Verify Code"
                        )}
                      </Button>
                    </div>
                    <p className="text-xs text-center text-muted-foreground">
                      Didn't receive the code?{" "}
                      <button
                        type="button"
                        className="text-primary underline"
                        onClick={handleSendVerificationCode}
                        disabled={isSendingCode}
                      >
                        Resend
                      </button>
                    </p>
                  </div>
                )}

                {!user && verificationStep === 'verified' && (
                  <div className="bg-green-50 dark:bg-green-950 p-4 rounded-lg flex items-center gap-2">
                    <ShieldCheck className="h-5 w-5 text-green-600" />
                    <p className="text-sm font-medium text-green-700 dark:text-green-300">
                      Email verified! You can now place your order.
                    </p>
                  </div>
                )}

                {/* Special Instructions */}
                <div>
                  <Label htmlFor="instructions">Special Instructions</Label>
                  <textarea
                    id="instructions"
                    className="w-full min-h-20 px-3 py-2 border border-border rounded-md text-sm"
                    placeholder="Any special requests or dietary restrictions..."
                    value={guestInfo.specialInstructions}
                    onChange={(e) =>
                      setGuestInfo({ ...guestInfo, specialInstructions: e.target.value })
                    }
                  />
                </div>

                <Separator />

                {/* Payment Method */}
                <div>
                  <Label className="text-base font-semibold mb-3 block">Payment Method</Label>
                  <div className="space-y-3">
                    <Card className="border-2 border-primary bg-primary/5">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <CreditCard className="h-5 w-5 text-primary" />
                          <div>
                            <p className="font-semibold">Pay at Store</p>
                            <p className="text-sm text-muted-foreground">
                              Cash or card when you pick up
                            </p>
                          </div>
                          <Badge variant="default" className="ml-auto bg-primary">
                            Selected
                          </Badge>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="border border-border opacity-50">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <CreditCard className="h-5 w-5" />
                          <div>
                            <p className="font-semibold">Pay Online</p>
                            <p className="text-sm text-muted-foreground">Coming soon</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                </div>

                <Separator />

                {/* Submit Button */}
                <Button
                  type="submit"
                  size="lg"
                  className="w-full bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  disabled={!isFormValid || isProcessing}
                >
                  {isProcessing ? "Processing..." : `Place Order - $${total.toFixed(2)}`}
                </Button>

                <p className="text-xs text-center text-muted-foreground">
                  By placing your order, you agree to our terms and conditions
                </p>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Order Summary */}
        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Order Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Items */}
              <div className="space-y-3">
                {items.map((item) => (
                  <div key={item.id} className="flex justify-between text-sm">
                    <span>
                      {item.quantity}x {item.name}
                    </span>
                    <span className="font-semibold">
                      ${(item.price * item.quantity).toFixed(2)}
                    </span>
                  </div>
                ))}
              </div>

              <Separator />

              {/* Totals */}
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Subtotal</span>
                  <span className="font-semibold">${subtotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Tax</span>
                  <span className="font-semibold">${tax.toFixed(2)}</span>
                </div>
                <Separator />
                <div className="flex justify-between text-lg font-bold">
                  <span>Total</span>
                  <span className="text-primary">${total.toFixed(2)}</span>
                </div>
              </div>

              <Separator />

              {/* Pickup Info */}
              <div className="space-y-3 text-sm">
                <div className="flex items-start gap-2">
                  <Clock className="h-4 w-4 text-primary mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-semibold">Estimated Ready Time</p>
                    <p className="text-muted-foreground">15-20 minutes</p>
                  </div>
                </div>
                <div className="flex items-start gap-2">
                  <MapPin className="h-4 w-4 text-primary mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-semibold">Pickup Location</p>
                    <p className="text-muted-foreground">
                      {storeName || `Store #${storeId}` || "Not selected"}
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};
