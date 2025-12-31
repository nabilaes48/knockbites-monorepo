import { useState, useEffect } from "react";
import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { ArrowLeft, Users } from "lucide-react";

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

const DashboardLogin = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [searchParams] = useSearchParams();
  const { signIn, signInWithGoogle, profile, loading, user } = useAuth();
  const [credentials, setCredentials] = useState({
    email: "",
    password: "",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);
  const [justLoggedIn, setJustLoggedIn] = useState(false);

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

  // Check if this is from an invite
  const isInvite = searchParams.get("invited") === "true";

  // Handle invite flow - if user is authenticated via magic link and invited=true, redirect to set password
  useEffect(() => {
    if (isInvite && user && !loading) {
      // User came from invite email - redirect to set password page
      navigate("/set-password?invited=true");
    }
  }, [isInvite, user, loading, navigate]);

  // Auto-redirect or block based on profile
  useEffect(() => {
    // Wait for auth to finish loading
    if (loading) return;

    // Don't redirect if this is an invite flow (handled above)
    if (isInvite) return;

    // If user is logged in
    if (user) {
      // If profile loaded
      if (profile) {
        // If customer signs in here, redirect them to customer dashboard
        if (profile.role === 'customer') {
          navigate("/customer/dashboard");
          setIsLoading(false);
          setJustLoggedIn(false);
          return;
        }

        // Business user - redirect to dashboard
        navigate("/dashboard");
        setIsLoading(false);
        setJustLoggedIn(false);
      } else if (justLoggedIn) {
        // User logged in but no profile found - they don't have staff access
        toast({
          title: "Access Denied",
          description: "You don't have staff access. Please request staff access or contact an administrator.",
          variant: "destructive",
        });
        setIsLoading(false);
        setJustLoggedIn(false);
      }
    }
  }, [profile, loading, justLoggedIn, user, navigate, toast, isInvite]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await signIn(credentials.email, credentials.password);
      setJustLoggedIn(true);

      toast({
        title: "Login Successful",
        description: "Welcome back!",
      });
    } catch (error: any) {
      toast({
        title: "Login Failed",
        description: error.message || "Invalid email or password",
        variant: "destructive",
      });
      setIsLoading(false);
      setJustLoggedIn(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Back to Home Link */}
        <Link to="/" className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary mb-6 transition-colors">
          <ArrowLeft className="h-4 w-4" />
          Back to Home
        </Link>

        <Card>
          <CardHeader className="text-center">
            <img
              src="/knockbites-logo.png"
              alt="KnockBites"
              className="w-16 h-16 rounded-xl mx-auto mb-4 shadow-lg"
            />
            <CardTitle className="text-2xl">Business Dashboard</CardTitle>
            <CardDescription>
              Sign in to manage orders and menu
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleLogin} className="space-y-4">
              <div>
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@knockbites.com"
                  value={credentials.email}
                  onChange={(e) => setCredentials({ ...credentials, email: e.target.value })}
                  required
                />
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="password">Password</Label>
                  <Link
                    to="/dashboard/forgot-password"
                    className="text-xs text-primary hover:underline"
                  >
                    Forgot password?
                  </Link>
                </div>
                <Input
                  id="password"
                  type="password"
                  placeholder="Enter your password"
                  value={credentials.password}
                  onChange={(e) => setCredentials({ ...credentials, password: e.target.value })}
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
                {isLoading ? "Signing in..." : "Sign In"}
              </Button>
            </form>

            {/* Divider */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-background px-2 text-muted-foreground">
                  Or continue with
                </span>
              </div>
            </div>

            {/* Google Sign In */}
            <Button
              type="button"
              variant="outline"
              size="lg"
              className="w-full"
              onClick={handleGoogleSignIn}
              disabled={isGoogleLoading}
            >
              <GoogleIcon />
              <span className="ml-2">
                {isGoogleLoading ? "Connecting..." : "Continue with Google"}
              </span>
            </Button>

            {/* Request Staff Access */}
            <div className="mt-6 space-y-3">
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <p className="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  Need Staff Access?
                </p>
                <p className="text-xs text-blue-700 mb-3">
                  Request staff access to join the KnockBites team. Your request will be reviewed by an administrator.
                </p>
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full border-blue-300 hover:bg-blue-100"
                  onClick={() => navigate("/request-staff-access")}
                >
                  Request Staff Access
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DashboardLogin;
