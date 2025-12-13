import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LogOut, Crown, Users, Building2, BarChart3, FileText, Settings as SettingsIcon } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import { SuperAdminGate } from "@/components/PermissionGate";
import { UserManagementPanel } from "@/components/dashboard/superadmin/UserManagementPanel";
import { StoreAssignmentPanel } from "@/components/dashboard/superadmin/StoreAssignmentPanel";
import { SystemAnalytics } from "@/components/dashboard/superadmin/SystemAnalytics";
import { AuditLogViewer } from "@/components/dashboard/superadmin/AuditLogViewer";
import { SystemSettings } from "@/components/dashboard/superadmin/SystemSettings";

const SuperAdminDashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { user, profile, loading, signOut } = useAuth();
  const [activeTab, setActiveTab] = useState("users");

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

  // Show loading state
  if (loading) {
    return (
      <div className="dark min-h-screen bg-gradient-to-br from-gray-900 via-slate-900 to-gray-950 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500 mx-auto"></div>
          <p className="mt-4 text-gray-300">Loading...</p>
        </div>
      </div>
    );
  }

  // Redirect if not authenticated
  if (!user || !profile) {
    return <Navigate to="/dashboard/login" replace />;
  }

  return (
    <SuperAdminGate
      fallback={
        <div className="dark min-h-screen bg-gradient-to-br from-gray-900 via-slate-900 to-gray-950 flex items-center justify-center">
          <div className="text-center max-w-md p-8 bg-gray-800/50 rounded-lg border border-red-500/50">
            <Crown className="h-16 w-16 text-red-500 mx-auto mb-4" />
            <h1 className="text-2xl font-bold text-white mb-2">Access Denied</h1>
            <p className="text-gray-300 mb-4">
              This area is restricted to Super Admins only.
            </p>
            <Button onClick={() => navigate("/dashboard")} variant="outline">
              Return to Dashboard
            </Button>
          </div>
        </div>
      }
    >
      <div className="dark min-h-screen bg-gradient-to-br from-gray-900 via-slate-900 to-gray-950">
        {/* Header */}
        <header className="bg-gray-950 border-b-2 border-purple-800/50 sticky top-0 z-50 shadow-md shadow-purple-500/20">
          <div className="container mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="bg-gradient-to-br from-purple-500 via-pink-500 to-purple-600 p-2 rounded-lg shadow-lg shadow-purple-500/50 animate-pulse">
                  <Crown className="h-7 w-7 text-white" />
                </div>
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-400 via-pink-400 to-purple-400 bg-clip-text text-transparent">
                      Super Admin Dashboard
                    </h1>
                    <Badge className="bg-gradient-to-r from-purple-600 via-pink-600 to-purple-600 text-white shadow-lg shadow-purple-500/50 animate-pulse">
                      <Crown className="h-3 w-3 mr-1" />
                      Super Admin
                    </Badge>
                  </div>
                  <p className="text-sm text-gray-400">System-Wide Management</p>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right hidden sm:block">
                  <p className="text-sm font-medium text-gray-200">{profile.full_name}</p>
                  <p className="text-xs text-gray-400">{user.email}</p>
                </div>
                <Button
                  onClick={handleLogout}
                  variant="outline"
                  className="border-gray-700 hover:bg-gray-800 text-gray-300 hover:text-white"
                >
                  <LogOut className="h-4 w-4 mr-2" />
                  Logout
                </Button>
              </div>
            </div>
          </div>
        </header>

        {/* Main Content */}
        <main className="container mx-auto px-4 py-8">
          <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
            {/* Tab Navigation */}
            <TabsList className="bg-gray-800/50 border border-gray-700 p-1 grid grid-cols-2 md:grid-cols-5 gap-1">
              <TabsTrigger
                value="users"
                className="data-[state=active]:bg-purple-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-purple-500/50"
              >
                <Users className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Users</span>
              </TabsTrigger>
              <TabsTrigger
                value="stores"
                className="data-[state=active]:bg-purple-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-purple-500/50"
              >
                <Building2 className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Stores</span>
              </TabsTrigger>
              <TabsTrigger
                value="analytics"
                className="data-[state=active]:bg-purple-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-purple-500/50"
              >
                <BarChart3 className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Analytics</span>
              </TabsTrigger>
              <TabsTrigger
                value="audit"
                className="data-[state=active]:bg-purple-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-purple-500/50"
              >
                <FileText className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Audit Logs</span>
              </TabsTrigger>
              <TabsTrigger
                value="settings"
                className="data-[state=active]:bg-purple-600 data-[state=active]:text-white data-[state=active]:shadow-lg data-[state=active]:shadow-purple-500/50"
              >
                <SettingsIcon className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Settings</span>
              </TabsTrigger>
            </TabsList>

            {/* Tab Content */}
            <TabsContent value="users" className="space-y-4">
              <UserManagementPanel />
            </TabsContent>

            <TabsContent value="stores" className="space-y-4">
              <StoreAssignmentPanel />
            </TabsContent>

            <TabsContent value="analytics" className="space-y-4">
              <SystemAnalytics />
            </TabsContent>

            <TabsContent value="audit" className="space-y-4">
              <AuditLogViewer />
            </TabsContent>

            <TabsContent value="settings" className="space-y-4">
              <SystemSettings />
            </TabsContent>
          </Tabs>
        </main>
      </div>
    </SuperAdminGate>
  );
};

export default SuperAdminDashboard;
