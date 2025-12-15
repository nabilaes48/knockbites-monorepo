import { useState, useEffect } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Lock, CheckCircle, Loader2, Eye, EyeOff, UserPlus } from "lucide-react";
import heroImage from "@/assets/hero-food.jpg";
import { supabase } from "@/lib/supabase";

const SetPassword = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [searchParams] = useSearchParams();

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isCheckingSession, setIsCheckingSession] = useState(true);
  const [userName, setUserName] = useState("");

  // Check if this is from an invite (vs reset password)
  const isInvite = searchParams.get("invited") === "true" || searchParams.get("type") === "invite";
  const isRecovery = searchParams.get("type") === "recovery";

  useEffect(() => {
    // Check if user is authenticated (from magic link)
    const checkSession = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();

        if (error) {
          console.error("Session error:", error);
          toast({
            title: "Session Error",
            description: "Invalid or expired link. Please request a new one.",
            variant: "destructive",
          });
          navigate("/dashboard/login");
          return;
        }

        if (!session) {
          // No session - check if URL has Supabase auth params (access_token, refresh_token)
          // Supabase handles this automatically, but we need to wait for it
          const hash = window.location.hash;
          if (hash && (hash.includes("access_token") || hash.includes("error"))) {
            // Wait for Supabase to process the hash
            const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(hash);
            if (exchangeError) {
              console.error("Token exchange error:", exchangeError);
              toast({
                title: "Link Expired",
                description: "This link has expired. Please request a new one.",
                variant: "destructive",
              });
              navigate("/dashboard/login");
              return;
            }
          } else {
            // No hash and no session - redirect to login
            toast({
              title: "Session Required",
              description: "Please use the link from your email to set your password.",
              variant: "destructive",
            });
            navigate("/dashboard/login");
            return;
          }
        }

        // Get user info
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          setUserName(user.user_metadata?.full_name || user.email?.split("@")[0] || "");
        }
      } catch (err) {
        console.error("Check session error:", err);
      } finally {
        setIsCheckingSession(false);
      }
    };

    checkSession();

    // Listen for auth state changes (handles magic link processing)
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "SIGNED_IN" && session) {
        setIsCheckingSession(false);
        setUserName(session.user.user_metadata?.full_name || session.user.email?.split("@")[0] || "");
      } else if (event === "PASSWORD_RECOVERY") {
        // Password recovery event - user is ready to set new password
        setIsCheckingSession(false);
      }
    });

    return () => subscription.unsubscribe();
  }, [navigate, toast]);

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

      // If this is an invite, mark it as accepted
      if (isInvite) {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          await supabase
            .from("user_profiles")
            .update({
              invite_status: "accepted",
              updated_at: new Date().toISOString(),
            })
            .eq("id", user.id);
        }
      }

      setIsSuccess(true);
      toast({
        title: isInvite ? "Welcome to KnockBites!" : "Password Updated",
        description: isInvite
          ? "Your account is ready. Redirecting to dashboard..."
          : "Your password has been updated successfully.",
      });

      // Redirect to dashboard after a short delay
      setTimeout(() => {
        navigate("/dashboard");
      }, 2000);
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to set password. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  if (isCheckingSession) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-black/80 via-black/70 to-[#FBBF24]/40">
        <div className="text-center text-white">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p>Verifying your link...</p>
        </div>
      </div>
    );
  }

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
          Back to Login
        </Link>

        <Card className="shadow-xl border-0 bg-white/95 backdrop-blur-sm">
          <CardHeader className="text-center">
            {isInvite ? (
              <div className="w-16 h-16 bg-gradient-to-r from-[#FBBF24] to-[#F59E0B] rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
                <UserPlus className="h-8 w-8 text-white" />
              </div>
            ) : (
              <img src="/knockbites-logo.png" alt="KnockBites" className="w-16 h-16 rounded-xl mx-auto mb-4 shadow-lg" />
            )}
            <CardTitle className="text-2xl text-gray-900">
              {isSuccess ? (
                "You're All Set!"
              ) : isInvite ? (
                <>Welcome{userName ? `, ${userName}` : ""}!</>
              ) : (
                "Set New Password"
              )}
            </CardTitle>
            <CardDescription className="text-gray-600">
              {isSuccess ? (
                "Redirecting to dashboard..."
              ) : isInvite ? (
                "Complete your account setup by creating a password"
              ) : (
                "Create a new password for your account"
              )}
            </CardDescription>
          </CardHeader>

          <CardContent>
            {isSuccess ? (
              <div className="text-center space-y-4">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                  <CheckCircle className="h-8 w-8 text-green-600" />
                </div>
                <p className="text-gray-600">
                  {isInvite
                    ? "Your account is ready! Taking you to the dashboard..."
                    : "Your password has been updated successfully."}
                </p>
                <Loader2 className="h-5 w-5 animate-spin mx-auto text-[#FBBF24]" />
              </div>
            ) : (
              <>
                {isInvite && (
                  <div className="mb-6 p-4 bg-gradient-to-r from-[#FBBF24]/10 to-[#F59E0B]/10 border border-[#FBBF24]/20 rounded-lg">
                    <p className="text-sm text-gray-700 text-center">
                      You've been invited to join the <strong>KnockBites</strong> team!
                      <br />
                      Create a password to access your dashboard.
                    </p>
                  </div>
                )}

                <form onSubmit={handleSetPassword} className="space-y-4">
                  <div>
                    <Label htmlFor="password" className="text-gray-700">New Password</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                      <Input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        placeholder="Enter your new password"
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
                        placeholder="Confirm your new password"
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
                        Setting Password...
                      </>
                    ) : isInvite ? (
                      "Complete Setup"
                    ) : (
                      "Set New Password"
                    )}
                  </Button>
                </form>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SetPassword;
