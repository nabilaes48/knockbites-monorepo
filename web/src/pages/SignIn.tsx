import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { Store, ArrowLeft, UserPlus } from "lucide-react";
import heroImage from "@/assets/hero-food.jpg";

const SignIn = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { signIn } = useAuth();
  const [credentials, setCredentials] = useState({
    email: "",
    password: "",
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await signIn(credentials.email, credentials.password);

      toast({
        title: "Welcome back!",
        description: "You have been signed in successfully",
      });

      // Wait a moment for profile to load, then check role
      setTimeout(() => {
        // Get the user profile from AuthContext to determine redirect
        const profile = JSON.parse(localStorage.getItem('supabase.auth.token') || '{}');

        // For now, navigate to customer dashboard
        // In production, you'd check the role from AuthContext
        navigate("/customer/dashboard");
      }, 500);
    } catch (error: any) {
      toast({
        title: "Sign in failed",
        description: error.message || "Invalid email or password",
        variant: "destructive",
      });
      setIsLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat relative"
      style={{
        backgroundImage: `url(${heroImage})`,
      }}
    >
      {/* Overlay - Orange to Pink gradient for KnockBites */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#FF8C42]/90 via-[#FF8C42]/70 to-[#E84393]/60" />

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
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-[#FF8C42] to-[#E84393] mx-auto mb-4 shadow-lg">
              <Store className="h-8 w-8 text-white" />
            </div>
            <CardTitle className="text-3xl text-gray-900">
              KnockBites <span className="text-[#FF8C42]">24-7</span> Deli
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
                  className="border-gray-300 focus:border-[#FF8C42] focus:ring-[#FF8C42]"
                />
              </div>

              <div>
                <Label htmlFor="password" className="text-gray-700">Password</Label>
                <Input
                  id="password"
                  type="password"
                  placeholder="Enter your password"
                  value={credentials.password}
                  onChange={(e) =>
                    setCredentials({ ...credentials, password: e.target.value })
                  }
                  required
                  className="border-gray-300 focus:border-[#FF8C42] focus:ring-[#FF8C42]"
                />
              </div>

              <Button
                type="submit"
                size="lg"
                className="w-full bg-gradient-to-r from-[#FF8C42] to-[#E84393] hover:from-[#F57C00] hover:to-[#D63384] text-white font-semibold shadow-md hover:shadow-lg transition-all"
                disabled={isLoading}
              >
                {isLoading ? "Signing in..." : "Sign In"}
              </Button>
            </form>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-600">
                Don't have an account?{" "}
                <Link
                  to="/signup"
                  className="text-[#FF8C42] hover:text-[#F57C00] hover:underline font-semibold"
                >
                  Sign up
                </Link>
              </p>
            </div>

            <div className="mt-6 p-4 bg-gradient-to-br from-[#FF8C42]/5 to-[#E84393]/5 border border-[#FF8C42]/20 rounded-xl">
              <p className="text-sm font-semibold text-gray-800 mb-2 flex items-center gap-2">
                <UserPlus className="h-4 w-4 text-[#FF8C42]" />
                New Customer?
              </p>
              <p className="text-xs text-gray-600 mb-3">
                Create an account to track your orders, earn rewards, and save your favorite items!
              </p>
              <Button
                variant="outline"
                size="sm"
                className="w-full border-[#FF8C42] text-[#FF8C42] hover:bg-[#FF8C42] hover:text-white transition-colors"
                onClick={() => navigate("/signup")}
              >
                Create Account
              </Button>
            </div>

            <div className="mt-4 text-center">
              <Link
                to="/dashboard/login"
                className="text-xs text-gray-500 hover:text-[#FF8C42] transition-colors"
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
