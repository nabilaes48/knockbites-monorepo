import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Mail, CheckCircle, Lock, Eye, EyeOff, Loader2, Building2 } from "lucide-react";
import { supabase } from "@/lib/supabase";

type Step = "email" | "code" | "password" | "success";

/**
 * Staff/Business Password Reset Page
 * - Located at /dashboard/forgot-password
 * - For staff, managers, admins accessing the business dashboard
 * - Redirects to /dashboard/login after reset
 */
const DashboardForgotPassword = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Verify this email belongs to a staff member before sending code
      const { data: staffProfile } = await supabase
        .from('user_profiles')
        .select('id')
        .eq('email', email.toLowerCase())
        .maybeSingle();

      if (!staffProfile) {
        toast({
          title: "Email Not Found",
          description: "This email is not registered as a staff account. Please check your email or contact an administrator.",
          variant: "destructive",
        });
        setIsLoading(false);
        return;
      }

      // Use OTP flow (no redirectTo) for consistency with iOS apps
      const { error } = await supabase.auth.resetPasswordForEmail(email);

      if (error) throw error;

      setStep("code");
      toast({
        title: "Code sent!",
        description: "Check your inbox for the 8-digit verification code",
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to send reset email",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const { data, error } = await supabase.auth.verifyOtp({
        email,
        token: code,
        type: "recovery",
      });

      if (error) throw error;

      if (data.session) {
        setStep("password");
        toast({
          title: "Code verified!",
          description: "Now set your new password",
        });
      }
    } catch (error: any) {
      toast({
        title: "Invalid code",
        description: error.message || "The code is incorrect or expired. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleSetPassword = async (e: React.FormEvent) => {
    e.preventDefault();

    if (password !== confirmPassword) {
      toast({
        title: "Passwords don't match",
        description: "Please make sure both passwords are the same.",
        variant: "destructive",
      });
      return;
    }

    if (password.length < 8) {
      toast({
        title: "Password too short",
        description: "Password must be at least 8 characters.",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);

    try {
      const { error } = await supabase.auth.updateUser({
        password: password,
      });

      if (error) throw error;

      // Sign out after password update (staff should log in fresh)
      await supabase.auth.signOut();

      setStep("success");
      toast({
        title: "Password updated!",
        description: "Your password has been changed successfully.",
      });

      // Redirect to staff login after 2 seconds
      setTimeout(() => {
        navigate("/dashboard/login");
      }, 2000);
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to update password",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const getStepTitle = () => {
    switch (step) {
      case "email":
        return "Reset your password";
      case "code":
        return "Enter verification code";
      case "password":
        return "Set new password";
      case "success":
        return "Password updated!";
    }
  };

  return (
    <div className="min-h-screen bg-gradient-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <Link
          to="/dashboard/login"
          className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Staff Login
        </Link>

        <Card>
          <CardHeader className="text-center">
            <div className="w-16 h-16 bg-primary/10 rounded-xl flex items-center justify-center mx-auto mb-4">
              <Building2 className="h-8 w-8 text-primary" />
            </div>
            <CardTitle className="text-2xl">Business Portal</CardTitle>
            <CardDescription>{getStepTitle()}</CardDescription>
          </CardHeader>

          <CardContent>
            {/* Step 1: Enter Email */}
            {step === "email" && (
              <>
                <div className="mb-6 p-4 bg-muted rounded-lg">
                  <div className="flex items-start gap-3">
                    <Mail className="h-5 w-5 text-primary mt-0.5" />
                    <p className="text-sm text-muted-foreground">
                      Enter your staff email address and we'll send you an 8-digit verification code.
                    </p>
                  </div>
                </div>

                <form onSubmit={handleSendCode} className="space-y-4">
                  <div>
                    <Label htmlFor="email">Staff Email</Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="staff@knockbites.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                    />
                  </div>

                  <Button
                    type="submit"
                    variant="secondary"
                    size="lg"
                    className="w-full"
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Sending...
                      </>
                    ) : (
                      "Send Code"
                    )}
                  </Button>
                </form>
              </>
            )}

            {/* Step 2: Enter Code */}
            {step === "code" && (
              <>
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <CheckCircle className="h-8 w-8 text-green-600" />
                  </div>
                  <p className="text-foreground font-medium">Code sent!</p>
                  <p className="text-sm text-muted-foreground mt-2">
                    We've sent an 8-digit verification code to <span className="font-medium">{email}</span>
                  </p>
                </div>

                <form onSubmit={handleVerifyCode} className="space-y-4">
                  <div>
                    <Label htmlFor="code">Verification Code</Label>
                    <Input
                      id="code"
                      type="text"
                      placeholder="00000000"
                      value={code}
                      onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 8))}
                      required
                      maxLength={8}
                      className="text-center font-mono text-xl tracking-widest"
                    />
                    <p className="text-xs text-muted-foreground mt-1">Enter the 8-digit code from your email</p>
                  </div>

                  <Button
                    type="submit"
                    variant="secondary"
                    size="lg"
                    className="w-full"
                    disabled={isLoading || code.length < 8}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Verifying...
                      </>
                    ) : (
                      "Verify Code"
                    )}
                  </Button>
                </form>

                <p className="text-xs text-muted-foreground text-center mt-4">
                  Didn't receive the code? Check your spam folder or{" "}
                  <button
                    onClick={() => {
                      setStep("email");
                      setCode("");
                    }}
                    className="text-primary hover:underline"
                  >
                    try again
                  </button>
                </p>
              </>
            )}

            {/* Step 3: Set New Password */}
            {step === "password" && (
              <form onSubmit={handleSetPassword} className="space-y-4">
                <div>
                  <Label htmlFor="password">New Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter new password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      minLength={8}
                      className="pl-10 pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                <div>
                  <Label htmlFor="confirmPassword">Confirm Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="confirmPassword"
                      type={showPassword ? "text" : "password"}
                      placeholder="Confirm new password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      required
                      minLength={8}
                      className="pl-10"
                    />
                  </div>
                  {password && confirmPassword && password !== confirmPassword && (
                    <p className="text-sm text-destructive mt-1">Passwords don't match</p>
                  )}
                </div>

                <Button
                  type="submit"
                  variant="secondary"
                  size="lg"
                  className="w-full"
                  disabled={isLoading || password !== confirmPassword}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Updating...
                    </>
                  ) : (
                    "Update Password"
                  )}
                </Button>
              </form>
            )}

            {/* Step 4: Success */}
            {step === "success" && (
              <div className="text-center space-y-4">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                  <CheckCircle className="h-8 w-8 text-green-600" />
                </div>
                <div>
                  <p className="text-foreground font-medium">Password updated successfully!</p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Redirecting to staff login...
                  </p>
                </div>
                <Loader2 className="h-5 w-5 animate-spin mx-auto text-primary" />
              </div>
            )}

            {step !== "success" && (
              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  Remember your password?{" "}
                  <Link
                    to="/dashboard/login"
                    className="text-primary hover:underline font-semibold"
                  >
                    Sign in
                  </Link>
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DashboardForgotPassword;
