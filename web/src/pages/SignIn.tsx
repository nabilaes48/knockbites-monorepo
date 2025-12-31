import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { ArrowLeft, UserPlus } from "lucide-react";
import heroImage from "@/assets/hero-food.jpg";

// Google icon component
const GoogleIcon = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24">
    <path
      fill="#4285F4"
      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
    />
    <path
      fill="#34A853"
      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
    />
    <path
      fill="#FBBC05"
      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
    />
    <path
      fill="#EA4335"
      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
    />
  </svg>
);

const SignIn = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { signIn, signInWithGoogle, user, profile, loading, isCustomer } = useAuth();
  const [credentials, setCredentials] = useState({
    email: "",
    password: "",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);
  const [justSignedIn, setJustSignedIn] = useState(false);

  const handleGoogleSignIn = async () => {
    setIsGoogleLoading(true);
    try {
      await signInWithGoogle();
    } catch (error: any) {
      toast({
        title: "Google sign in failed",
        description: error.message || "Failed to sign in with Google. Please try again.",
        variant: "destructive",
      });
      setIsGoogleLoading(false);
    }
  };

  // Redirect after sign-in when auth loading is complete
  useEffect(() => {
    console.log('SignIn useEffect:', { justSignedIn, loading, user: !!user, profile: !!profile, isCustomer });

    if (justSignedIn && !loading && user) {
      // Redirect based on role
      if (profile) {
        console.log('Redirecting to:', isCustomer ? '/customer/dashboard' : '/dashboard');
        if (isCustomer) {
          navigate("/customer/dashboard");
        } else {
          // Staff/admin users go to business dashboard
          navigate("/dashboard");
        }
      } else {
        // User exists but no profile - go to home page
        console.log('No profile found, redirecting to home');
        navigate("/");
      }
      setJustSignedIn(false);
      setIsLoading(false);
    }
  }, [justSignedIn, loading, user, profile, isCustomer, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await signIn(credentials.email, credentials.password);
      setJustSignedIn(true);

      toast({
        title: "Welcome back!",
        description: "You have been signed in successfully",
      });
    } catch (error: any) {
      toast({
        title: "Sign in failed",
        description: error.message || "Invalid email or password",
        variant: "destructive",
      });
      setIsLoading(false);
      setJustSignedIn(false);
    }
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat relative"
      style={{
        backgroundImage: `url(${heroImage})`,
      }}
    >
      {/* Overlay - Dark gradient with gold accent */}
      <div className="absolute inset-0 bg-gradient-to-br from-black/80 via-black/70 to-[#FBBF24]/40" />

      <div className="w-full max-w-md relative z-10">
        <Link
          to="/"
          className="inline-flex items-center gap-2 text-sm text-white/90 hover:text-white mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Home
        </Link>

        <Card className="shadow-xl border-0 bg-white/95 backdrop-blur-sm">
          <CardHeader className="text-center">
            <img src="/knockbites-logo.png" alt="KnockBites" className="w-16 h-16 rounded-xl mx-auto mb-4 shadow-lg" />
            <CardTitle className="text-3xl text-gray-900">
              <span className="text-[#FBBF24]">Knock</span>Bites
            </CardTitle>
            <CardDescription className="text-gray-600">Sign in to your account</CardDescription>
          </CardHeader>

          <CardContent>
            <form onSubmit={handleLogin} className="space-y-4">
              <div>
                <Label htmlFor="email" className="text-gray-700">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="you@example.com"
                  value={credentials.email}
                  onChange={(e) =>
                    setCredentials({ ...credentials, email: e.target.value })
                  }
                  required
                  className="border-gray-300 focus:border-[#FBBF24] focus:ring-[#FBBF24]"
                />
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="password" className="text-gray-700">Password</Label>
                  <Link
                    to="/forgot-password"
                    className="text-xs text-[#FBBF24] hover:text-[#D97706] hover:underline"
                  >
                    Forgot password?
                  </Link>
                </div>
                <Input
                  id="password"
                  type="password"
                  placeholder="Enter your password"
                  value={credentials.password}
                  onChange={(e) =>
                    setCredentials({ ...credentials, password: e.target.value })
                  }
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
                {isLoading ? "Signing in..." : "Sign In"}
              </Button>
            </form>

            {/* Divider */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-white/95 px-2 text-gray-500">
                  Or continue with
                </span>
              </div>
            </div>

            {/* Google Sign In */}
            <Button
              type="button"
              variant="outline"
              size="lg"
              className="w-full border-gray-300 hover:bg-gray-50"
              onClick={handleGoogleSignIn}
              disabled={isGoogleLoading}
            >
              <GoogleIcon />
              <span className="ml-2 text-gray-700">
                {isGoogleLoading ? "Connecting..." : "Continue with Google"}
              </span>
            </Button>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-600">
                Don't have an account?{" "}
                <Link
                  to="/signup"
                  className="text-[#FBBF24] hover:text-[#D97706] hover:underline font-semibold"
                >
                  Sign up
                </Link>
              </p>
            </div>

            <div className="mt-6 p-4 bg-gradient-to-br from-[#FBBF24]/5 to-[#F59E0B]/5 border border-[#FBBF24]/20 rounded-xl">
              <p className="text-sm font-semibold text-gray-800 mb-2 flex items-center gap-2">
                <UserPlus className="h-4 w-4 text-[#FBBF24]" />
                New Customer?
              </p>
              <p className="text-xs text-gray-600 mb-3">
                Create an account to track your orders, earn rewards, and save your favorite items!
              </p>
              <Button
                variant="outline"
                size="sm"
                className="w-full border-[#FBBF24] text-[#FBBF24] hover:bg-[#FBBF24] hover:text-white transition-colors"
                onClick={() => navigate("/signup")}
              >
                Create Account
              </Button>
            </div>

            <div className="mt-4 text-center">
              <Link
                to="/dashboard/login"
                className="text-xs text-gray-500 hover:text-[#FBBF24] transition-colors"
              >
                Staff? Sign in here →
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignIn;
