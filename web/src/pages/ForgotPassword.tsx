import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Mail, CheckCircle, Lock, Eye, EyeOff, Loader2 } from "lucide-react";
import heroImage from "@/assets/hero-food.jpg";
import { supabase } from "@/lib/supabase";

type Step = "email" | "code" | "password" | "success";

const ForgotPassword = () => {
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
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });

      if (error) throw error;

      setStep("code");
      toast({
        title: "Code sent!",
        description: "Check your inbox for the verification code",
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

      setStep("success");
      toast({
        title: "Password updated!",
        description: "Your password has been changed successfully.",
      });

      // Redirect to login after 2 seconds
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
    <div
      className="min-h-screen flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat relative"
      style={{
        backgroundImage: `url(${heroImage})`,
      }}
    >
      {/* Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-black/80 via-black/70 to-[#FBBF24]/40" />

      <div className="w-full max-w-md relative z-10">
        <Link
          to="/dashboard/login"
          className="inline-flex items-center gap-2 text-sm text-white/90 hover:text-white mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Sign In
        </Link>

        <Card className="shadow-xl border-0 bg-white/95 backdrop-blur-sm">
          <CardHeader className="text-center">
            <img src="/knockbites-logo.png" alt="KnockBites" className="w-16 h-16 rounded-xl mx-auto mb-4 shadow-lg" />
            <CardTitle className="text-3xl text-gray-900">
              <span className="text-[#FBBF24]">Knock</span>Bites
            </CardTitle>
            <CardDescription className="text-gray-600">
              {getStepTitle()}
            </CardDescription>
          </CardHeader>

          <CardContent>
            {/* Step 1: Enter Email */}
            {step === "email" && (
              <>
                <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-start gap-3">
                    <Mail className="h-5 w-5 text-[#FBBF24] mt-0.5" />
                    <p className="text-sm text-gray-600">
                      Enter your email address and we'll send you a verification code.
                    </p>
                  </div>
                </div>

                <form onSubmit={handleSendCode} className="space-y-4">
                  <div>
                    <Label htmlFor="email" className="text-gray-700">Email</Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="you@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                      className="border-gray-300 focus:border-[#FBBF24] focus:ring-[#FBBF24]"
                    />
                  </div>

                  <Button
                    type="submit"
                    size="lg"
                    className="w-full bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all"
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
                  <p className="text-gray-700 font-medium">Code sent!</p>
                  <p className="text-sm text-gray-500 mt-2">
                    We've sent a verification code to <span className="font-medium">{email}</span>
                  </p>
                </div>

                <form onSubmit={handleVerifyCode} className="space-y-4">
                  <div>
                    <Label htmlFor="code" className="text-gray-700">Verification Code</Label>
                    <Input
                      id="code"
                      type="text"
                      placeholder="Enter code from email"
                      value={code}
                      onChange={(e) => setCode(e.target.value.trim())}
                      required
                      className="border-gray-300 focus:border-[#FBBF24] focus:ring-[#FBBF24] text-center font-mono"
                    />
                    <p className="text-xs text-gray-400 mt-1">Copy the full code from your email</p>
                  </div>

                  <Button
                    type="submit"
                    size="lg"
                    className="w-full bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all"
                    disabled={isLoading || code.length < 6}
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

                <p className="text-xs text-gray-400 text-center mt-4">
                  Didn't receive the code? Check your spam folder or{" "}
                  <button
                    onClick={() => {
                      setStep("email");
                      setCode("");
                    }}
                    className="text-[#FBBF24] hover:text-[#D97706] hover:underline"
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
                  <Label htmlFor="password" className="text-gray-700">New Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter new password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      minLength={8}
                      className="pl-10 pr-10 border-gray-300 focus:border-[#FBBF24] focus:ring-[#FBBF24]"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                <div>
                  <Label htmlFor="confirmPassword" className="text-gray-700">Confirm Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      id="confirmPassword"
                      type={showPassword ? "text" : "password"}
                      placeholder="Confirm new password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      required
                      minLength={8}
                      className="pl-10 border-gray-300 focus:border-[#FBBF24] focus:ring-[#FBBF24]"
                    />
                  </div>
                  {password && confirmPassword && password !== confirmPassword && (
                    <p className="text-sm text-red-500 mt-1">Passwords don't match</p>
                  )}
                </div>

                <Button
                  type="submit"
                  size="lg"
                  className="w-full bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] hover:from-[#D97706] hover:to-[#B45309] text-white font-semibold shadow-md hover:shadow-lg transition-all"
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
                  <p className="text-gray-700 font-medium">Password updated successfully!</p>
                  <p className="text-sm text-gray-500 mt-2">
                    Redirecting to login...
                  </p>
                </div>
                <Loader2 className="h-5 w-5 animate-spin mx-auto text-[#FBBF24]" />
              </div>
            )}

            {step !== "success" && (
              <div className="mt-6 text-center">
                <p className="text-sm text-gray-600">
                  Remember your password?{" "}
                  <Link
                    to="/dashboard/login"
                    className="text-[#FBBF24] hover:text-[#D97706] hover:underline font-semibold"
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

export default ForgotPassword;
