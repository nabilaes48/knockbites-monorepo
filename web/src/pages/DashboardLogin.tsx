import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { Store, ArrowLeft, Users } from "lucide-react";

const DashboardLogin = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { signIn, profile, loading, user } = useAuth();
  const [credentials, setCredentials] = useState({
    email: "",
    password: "",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [justLoggedIn, setJustLoggedIn] = useState(false);

  // Auto-redirect or block based on profile
  useEffect(() => {
    // Wait for auth to finish loading
    if (loading) return;

    // If user is logged in
    if (user) {
      // If profile loaded
      if (profile) {
        // If customer tries to access business dashboard, redirect to customer dashboard
        if (profile.role === 'customer') {
          toast({
            title: "Access Denied",
            description: "Customers cannot access the business dashboard. Please use the customer portal.",
            variant: "destructive",
          });
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
  }, [profile, loading, justLoggedIn, user, navigate, toast]);

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
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 mx-auto mb-4">
              <Store className="h-8 w-8 text-primary" />
            </div>
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
                <Label htmlFor="password">Password</Label>
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
