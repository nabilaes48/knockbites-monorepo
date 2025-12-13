import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { OrderManagement } from "@/components/dashboard/OrderManagement";
import { MenuManagement } from "@/components/dashboard/MenuManagement";
import { Analytics } from "@/components/dashboard/Analytics";
import { Settings } from "@/components/dashboard/Settings";
import { StaffManagement } from "@/components/dashboard/StaffManagement";
import { MarketingManagement } from "@/components/dashboard/MarketingManagement";
import { MultiLocationDashboard } from "@/components/dashboard/MultiLocationDashboard";
import { AIInsights } from "@/components/dashboard/AIInsights";
import { ThemeToggle } from "@/components/ThemeToggle";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import {
  LogOut,
  Store,
  Shield,
  Briefcase,
  Users,
  Crown,
  UserCog,
  ShoppingBag,
  ChefHat,
  BarChart3,
  Settings2,
  Megaphone,
  Building2,
  Brain,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";

const Dashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user, profile, loading, signOut, hasPermission } = useAuth();
  const [activeTab, setActiveTab] = useState("orders");

  const handleLogout = async () => {
    try {
      await signOut();
      toast({
        title: "Logged out",
        description: "You have been logged out successfully",
      });
      navigate("/dashboard/login");
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to log out",
        variant: "destructive",
      });
    }
  };

  // Loading state with dual-theme support
  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <div
            className={cn(
              "h-12 w-12 rounded-full border-2 animate-spin mx-auto",
              "border-primary/30 border-t-primary"
            )}
          />
          <p className="mt-4 text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  // Redirect to login if not authenticated
  if (!user || !profile) {
    return <Navigate to="/dashboard/login" replace />;
  }

  // Redirect customers to customer dashboard
  if (profile.role === "customer") {
    return <Navigate to="/customer/dashboard" replace />;
  }

  // Role badge configuration
  const getRoleBadgeVariant = (): "vip" | "info" | "success" | "default" => {
    const variants: Record<string, "vip" | "info" | "success" | "default"> = {
      super_admin: "vip",
      admin: "info",
      manager: "success",
      staff: "default",
    };
    return variants[profile.role] || "default";
  };

  const getRoleIcon = () => {
    const icons: Record<string, typeof Crown> = {
      super_admin: Crown,
      admin: Shield,
      manager: Briefcase,
      staff: Users,
    };
    return icons[profile.role] || Users;
  };

  const getRoleLabel = () => {
    const labels: Record<string, string> = {
      super_admin: "Super Admin",
      admin: "Admin",
      manager: "Manager",
      staff: "Staff",
    };
    return labels[profile.role] || "Staff";
  };

  const RoleIcon = getRoleIcon();

  // Tab configuration
  const tabs = [
    {
      value: "orders",
      label: "Orders",
      icon: ShoppingBag,
      permission: "orders",
    },
    {
      value: "menu",
      label: "Menu",
      icon: ChefHat,
      permission: "menu",
    },
    {
      value: "analytics",
      label: "Analytics",
      icon: BarChart3,
      permission: "analytics",
    },
    {
      value: "marketing",
      label: "Marketing",
      icon: Megaphone,
      permission: null, // Available for managers and above
      adminOnly: true,
    },
    {
      value: "locations",
      label: "Locations",
      icon: Building2,
      permission: null, // Super admin only for multi-location
      superAdminOnly: true,
    },
    {
      value: "ai",
      label: "AI",
      icon: Brain,
      permission: null, // Admin only for AI insights
      adminOnly: true,
    },
    {
      value: "staff",
      label: "Staff",
      icon: UserCog,
      permission: null, // Special handling for admin roles
      adminOnly: true,
    },
    {
      value: "settings",
      label: "Settings",
      icon: Settings2,
      permission: "settings",
    },
  ];

  // Filter tabs based on permissions
  const visibleTabs = tabs.filter((tab: any) => {
    if (tab.superAdminOnly) {
      return profile.role === "super_admin";
    }
    if (tab.adminOnly) {
      return profile.role === "super_admin" || profile.role === "admin";
    }
    return tab.permission ? hasPermission(tab.permission) : true;
  });

  return (
    <div className="min-h-screen bg-background dark:bg-grid">
      {/* Header */}
      <header
        className={cn(
          "sticky top-0 z-50",
          // Light mode - Clean Apple style
          "bg-background/80 backdrop-blur-xl border-b border-border/50",
          // Dark mode - Glassmorphism
          "dark:bg-background/60 dark:backdrop-blur-2xl",
          "dark:border-b dark:border-primary/10",
          "dark:shadow-[0_4px_30px_rgba(0,0,0,0.3)]"
        )}
      >
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            {/* Left side - Logo and info */}
            <div className="flex items-center gap-4">
              {/* Logo */}
              <div
                className={cn(
                  "p-2.5 rounded-xl",
                  // Light mode
                  "bg-primary text-primary-foreground shadow-soft",
                  // Dark mode
                  "dark:bg-primary/10 dark:border dark:border-primary/30",
                  "dark:shadow-glow-primary"
                )}
              >
                <Store className="h-6 w-6 dark:text-primary" />
              </div>

              {/* Title and info */}
              <div>
                <div className="flex items-center gap-3 mb-1">
                  <h1
                    className={cn(
                      "text-xl font-semibold",
                      // Light mode
                      "text-foreground",
                      // Dark mode - subtle gradient
                      "dark:bg-gradient-to-r dark:from-foreground dark:to-foreground/70",
                      "dark:bg-clip-text dark:text-transparent"
                    )}
                  >
                    Business Dashboard
                  </h1>
                  <GlowingBadge
                    variant={getRoleBadgeVariant()}
                    pulse={profile.role === "super_admin"}
                    size="sm"
                  >
                    <RoleIcon className="h-3 w-3" />
                    {getRoleLabel()}
                  </GlowingBadge>
                </div>
                <p className="text-sm text-muted-foreground">
                  {profile.full_name} • Highland Mills Snack Shop Inc
                </p>
              </div>
            </div>

            {/* Right side - Actions */}
            <div className="flex items-center gap-3">
              <ThemeToggle />
              <NeonButton
                variant="outline"
                size="sm"
                onClick={handleLogout}
                className="gap-2"
              >
                <LogOut className="h-4 w-4" />
                <span className="hidden sm:inline">Logout</span>
              </NeonButton>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-6">
        <Tabs
          value={activeTab}
          onValueChange={setActiveTab}
          className="space-y-6"
        >
          {/* Tab Navigation */}
          <GlassCard className="p-1.5" variant="outline">
            <TabsList
              className={cn(
                "grid w-full h-auto bg-transparent",
                `grid-cols-${visibleTabs.length}`
              )}
              style={{
                gridTemplateColumns: `repeat(${visibleTabs.length}, minmax(0, 1fr))`,
              }}
            >
              {visibleTabs.map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.value;

                return (
                  <TabsTrigger
                    key={tab.value}
                    value={tab.value}
                    className={cn(
                      "relative py-3 px-4 rounded-lg",
                      "transition-all duration-200 ease-smooth",
                      "data-[state=active]:bg-transparent",
                      // Light mode
                      "text-muted-foreground",
                      "hover:text-foreground hover:bg-secondary/50",
                      "data-[state=active]:text-foreground",
                      "data-[state=active]:bg-secondary",
                      "data-[state=active]:shadow-soft",
                      // Dark mode
                      "dark:hover:bg-white/5",
                      "dark:data-[state=active]:bg-primary/10",
                      "dark:data-[state=active]:text-primary",
                      "dark:data-[state=active]:shadow-glow-subtle"
                    )}
                  >
                    <span className="flex items-center justify-center gap-2">
                      <Icon
                        className={cn(
                          "h-4 w-4 transition-colors",
                          isActive && "dark:text-primary"
                        )}
                      />
                      <span className="hidden sm:inline font-medium">
                        {tab.label}
                      </span>
                    </span>

                    {/* Active indicator line (dark mode) */}
                    {isActive && (
                      <span
                        className={cn(
                          "absolute bottom-0 left-1/2 -translate-x-1/2",
                          "w-8 h-0.5 rounded-full",
                          "bg-primary",
                          "hidden dark:block",
                          "animate-scale-in"
                        )}
                      />
                    )}
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </GlassCard>

          {/* Tab Content */}
          <div className="animate-fade-in">
            {hasPermission("orders") && (
              <TabsContent value="orders" className="mt-0 focus-visible:outline-none">
                <OrderManagement />
              </TabsContent>
            )}

            {hasPermission("menu") && (
              <TabsContent value="menu" className="mt-0 focus-visible:outline-none">
                <MenuManagement />
              </TabsContent>
            )}

            {hasPermission("analytics") && (
              <TabsContent value="analytics" className="mt-0 focus-visible:outline-none">
                <Analytics />
              </TabsContent>
            )}

            {(profile.role === "super_admin" || profile.role === "admin") && (
              <TabsContent value="marketing" className="mt-0 focus-visible:outline-none">
                <MarketingManagement />
              </TabsContent>
            )}

            {profile.role === "super_admin" && (
              <TabsContent value="locations" className="mt-0 focus-visible:outline-none">
                <MultiLocationDashboard />
              </TabsContent>
            )}

            {(profile.role === "super_admin" || profile.role === "admin") && (
              <TabsContent value="ai" className="mt-0 focus-visible:outline-none">
                <AIInsights />
              </TabsContent>
            )}

            {(profile.role === "super_admin" || profile.role === "admin") && (
              <TabsContent value="staff" className="mt-0 focus-visible:outline-none">
                <StaffManagement />
              </TabsContent>
            )}

            {hasPermission("settings") && (
              <TabsContent value="settings" className="mt-0 focus-visible:outline-none">
                <Settings onNavigateToStaff={() => setActiveTab("staff")} />
              </TabsContent>
            )}
          </div>

          {/* No permissions message */}
          {visibleTabs.length === 0 && (
            <GlassCard className="p-12 text-center">
              <div className="text-muted-foreground">
                <Shield className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p className="text-lg font-medium">No permissions assigned</p>
                <p className="text-sm mt-2">
                  Contact your administrator for access
                </p>
              </div>
            </GlassCard>
          )}
        </Tabs>
      </main>
    </div>
  );
};

export default Dashboard;
