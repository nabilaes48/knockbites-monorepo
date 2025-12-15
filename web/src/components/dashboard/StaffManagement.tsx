import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter } from "@/components/ui/AnimatedCounter";
import { StatusPulse } from "@/components/ui/StatusPulse";
import {
  Users,
  Crown,
  Shield,
  Briefcase,
  UserPlus,
  Edit,
  Trash2,
  Search,
  Star,
  TrendingUp,
  Store,
  Mail,
  Phone,
  Calendar,
  Loader2,
  Send,
  RefreshCw,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { locations } from "@/data/locations";
import { cn } from "@/lib/utils";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/contexts/AuthContext";

interface Staff {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: "super_admin" | "admin" | "manager" | "staff";
  storeId?: string;
  storeName?: string;
  permissions: string[];
  status: "active" | "inactive" | "invited";
  hireDate: string;
  emailConfirmed: boolean;
  performance: {
    ordersHandled: number;
    avgResponseTime: number;
    rating: number;
  };
}

export const StaffManagement = () => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [staff, setStaff] = useState<Staff[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [filterRole, setFilterRole] = useState<string>("all");
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isInviting, setIsInviting] = useState(false);

  const [newStaff, setNewStaff] = useState({
    name: "",
    email: "",
    phone: "",
    role: "staff" as "admin" | "manager" | "staff",
    storeId: "",
  });
  const [resendingId, setResendingId] = useState<string | null>(null);

  // Fetch staff from database
  useEffect(() => {
    fetchStaff();
  }, []);

  const fetchStaff = async () => {
    try {
      setLoading(true);

      // Fetch user_profiles with their auth user data
      const { data: profiles, error } = await supabase
        .from("user_profiles")
        .select("*")
        .in("role", ["super_admin", "admin", "manager", "staff"])
        .order("created_at", { ascending: false });

      if (error) throw error;

      // Map profiles to staff list with proper invite status tracking
      const staffList: Staff[] = (profiles || []).map((profile: any) => {
        const store = profile.store_id
          ? locations.find(l => l.id === profile.store_id)
          : null;

        // Determine status: invited (pending), active, or inactive
        let status: "active" | "inactive" | "invited" = "active";
        if (!profile.is_active) {
          status = "inactive";
        } else if (profile.invite_status === "pending") {
          status = "invited";
        }

        return {
          id: profile.id,
          name: profile.full_name || "Unknown",
          email: profile.email || "",
          phone: profile.phone || "",
          role: profile.role,
          storeId: profile.store_id?.toString(),
          storeName: store?.name || (profile.assigned_stores?.length > 0 ? "Multiple Stores" : undefined),
          permissions: Array.isArray(profile.permissions) ? profile.permissions : [],
          status,
          hireDate: profile.created_at?.split("T")[0] || new Date().toISOString().split("T")[0],
          emailConfirmed: profile.invite_status !== "pending",
          performance: {
            ordersHandled: 0,
            avgResponseTime: 0,
            rating: 5.0,
          },
        };
      });

      setStaff(staffList);
    } catch (err) {
      console.error("Error fetching staff:", err);
      toast({
        title: "Error",
        description: "Failed to load staff members",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  // Invite new staff member
  const handleInviteStaff = async () => {
    if (!newStaff.name || !newStaff.email || !newStaff.role) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    setIsInviting(true);

    try {
      // Get current session token
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error("Not authenticated");
      }

      // Call the invite-staff Edge Function
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/invite-staff`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            email: newStaff.email,
            full_name: newStaff.name,
            phone: newStaff.phone || undefined,
            role: newStaff.role,
            store_id: newStaff.storeId ? parseInt(newStaff.storeId) : undefined,
            assigned_stores: newStaff.storeId ? [parseInt(newStaff.storeId)] : [],
          }),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || "Failed to send invitation");
      }

      // Add to local state with appropriate status
      const store = newStaff.storeId
        ? locations.find(l => l.id.toString() === newStaff.storeId)
        : null;

      const isExistingCustomer = result.user?.isExistingCustomer || false;

      const addedStaff: Staff = {
        id: result.user?.id || Date.now().toString(),
        name: newStaff.name,
        email: newStaff.email,
        phone: newStaff.phone || "",
        role: newStaff.role,
        storeId: newStaff.storeId,
        storeName: store?.name,
        permissions: getDefaultPermissions(newStaff.role),
        status: isExistingCustomer ? "active" : "invited",
        hireDate: new Date().toISOString().split("T")[0],
        emailConfirmed: isExistingCustomer,
        performance: { ordersHandled: 0, avgResponseTime: 0, rating: 5.0 },
      };

      setStaff([addedStaff, ...staff]);
      setIsAddDialogOpen(false);
      setNewStaff({
        name: "",
        email: "",
        phone: "",
        role: "staff",
        storeId: "",
      });

      toast({
        title: isExistingCustomer ? "Staff Added!" : "Invitation Sent!",
        description: result.message || (isExistingCustomer
          ? `${newStaff.name} can now log in with their existing password`
          : `${newStaff.name} will receive an email to set up their account`),
      });
    } catch (err: any) {
      console.error("Error inviting staff:", err);
      toast({
        title: "Invitation Failed",
        description: err.message || "Failed to send invitation",
        variant: "destructive",
      });
    } finally {
      setIsInviting(false);
    }
  };

  const getDefaultPermissions = (role: string): string[] => {
    switch (role) {
      case "super_admin":
        return ["orders", "menu", "analytics", "settings", "staff", "all-stores"];
      case "admin":
        return ["orders", "menu", "analytics", "settings", "staff"];
      case "manager":
        return ["orders", "menu", "analytics", "settings"];
      case "staff":
        return ["orders"];
      default:
        return ["orders"];
    }
  };

  const roleConfig = {
    super_admin: {
      label: "Super Admin",
      icon: Crown,
      variant: "vip" as const,
      defaultPermissions: ["orders", "menu", "analytics", "settings", "staff", "all-stores"],
    },
    admin: {
      label: "Admin",
      icon: Shield,
      variant: "info" as const,
      defaultPermissions: ["orders", "menu", "analytics", "settings", "staff"],
    },
    manager: {
      label: "Manager",
      icon: Briefcase,
      variant: "success" as const,
      defaultPermissions: ["orders", "menu", "analytics", "settings"],
    },
    staff: {
      label: "Staff",
      icon: Users,
      variant: "default" as const,
      defaultPermissions: ["orders"],
    },
  };

  const filteredStaff = staff.filter((member) => {
    const matchesSearch =
      !searchQuery ||
      member.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      member.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      member.phone.includes(searchQuery);
    const matchesRole = filterRole === "all" || member.role === filterRole;
    return matchesSearch && matchesRole;
  });

  const stats = {
    total: staff.length,
    admins: staff.filter((s) => s.role === "admin").length,
    managers: staff.filter((s) => s.role === "manager").length,
    staffCount: staff.filter((s) => s.role === "staff").length,
    active: staff.filter((s) => s.status === "active").length,
    invited: staff.filter((s) => s.status === "invited").length,
  };

  const handleDeleteStaff = (id: string) => {
    const member = staff.find((s) => s.id === id);
    if (!member) return;

    if (window.confirm(`Are you sure you want to remove ${member.name}?`)) {
      setStaff(staff.filter((s) => s.id !== id));
      toast({
        title: "Staff Removed",
        description: `${member.name} has been removed from the system`,
      });
    }
  };

  const handleToggleStatus = (id: string) => {
    setStaff(
      staff.map((s) => {
        if (s.id === id) {
          const newStatus = s.status === "active" ? "inactive" : "active";
          toast({
            title: "Status Updated",
            description: `${s.name} is now ${newStatus}`,
          });
          return { ...s, status: newStatus };
        }
        return s;
      })
    );
  };

  // Resend invitation email
  const handleResendInvite = async (member: Staff) => {
    setResendingId(member.id);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error("Not authenticated");
      }

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/resend-invitation`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            user_id: member.id,
          }),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || "Failed to resend invitation");
      }

      toast({
        title: "Invitation Resent",
        description: `A new invitation email has been sent to ${member.email}`,
      });
    } catch (err: any) {
      console.error("Error resending invite:", err);
      toast({
        title: "Failed to Resend",
        description: err.message || "Could not resend invitation",
        variant: "destructive",
      });
    } finally {
      setResendingId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Super Admin Banner */}
      <GlassCard glowColor="purple" gradient="purple" className="overflow-hidden">
        <div
          className={cn(
            "p-5",
            "bg-gradient-to-r from-ios-purple/20 to-ios-pink/20",
            "dark:from-neon-purple/10 dark:to-neon-pink/10"
          )}
        >
          <div className="flex items-center gap-3">
            <div
              className={cn(
                "p-3 rounded-xl",
                "bg-ios-purple/20 text-ios-purple",
                "dark:bg-neon-purple/20 dark:text-neon-purple",
                "dark:shadow-glow-purple"
              )}
            >
              <Crown className="h-6 w-6" />
            </div>
            <div>
              <h3 className="font-bold text-lg">Super Admin Privileges</h3>
              <p className="text-sm text-muted-foreground">
                Full control: Add/Remove Admins, Manage all stores, Assign roles
              </p>
            </div>
          </div>
        </div>
      </GlassCard>

      {/* Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold flex items-center gap-2 text-foreground">
            <div
              className={cn(
                "p-2 rounded-lg",
                "bg-ios-purple/10 text-ios-purple",
                "dark:bg-neon-purple/10 dark:text-neon-purple"
              )}
            >
              <Users className="h-5 w-5" />
            </div>
            Staff Management
          </h2>
          <p className="text-muted-foreground mt-1">
            Manage staff across all KnockBites locations
          </p>
        </div>

        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <NeonButton className="gap-2 whitespace-nowrap" glow>
              <UserPlus className="h-4 w-4" />
              Add Staff / Admin
            </NeonButton>
          </DialogTrigger>
          <DialogContent
            className={cn(
              "max-w-2xl",
              "bg-card border-border/50",
              "dark:bg-card/95 dark:backdrop-blur-xl dark:border-primary/10"
            )}
          >
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Crown className="h-5 w-5 text-ios-purple dark:text-neon-purple" />
                Add New Staff Member
              </DialogTitle>
              <DialogDescription>
                Create accounts with any role including Admins with full store access
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="name" className="text-sm">Full Name *</Label>
                  <Input
                    id="name"
                    placeholder="John Doe"
                    value={newStaff.name}
                    onChange={(e) => setNewStaff({ ...newStaff, name: e.target.value })}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10"
                    )}
                  />
                </div>
                <div>
                  <Label htmlFor="email" className="text-sm">Email *</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="john@knockbites.com"
                    value={newStaff.email}
                    onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10"
                    )}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="phone" className="text-sm">Phone</Label>
                  <Input
                    id="phone"
                    placeholder="(555) 123-4567"
                    value={newStaff.phone}
                    onChange={(e) => setNewStaff({ ...newStaff, phone: e.target.value })}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10"
                    )}
                  />
                </div>
                <div>
                  <Label htmlFor="role" className="text-sm">Role *</Label>
                  <Select
                    value={newStaff.role}
                    onValueChange={(value) =>
                      setNewStaff({ ...newStaff, role: value as Staff["role"] })
                    }
                  >
                    <SelectTrigger
                      className={cn(
                        "mt-1.5",
                        "bg-secondary/50 border-border/50",
                        "dark:bg-card/50 dark:border-primary/10"
                      )}
                    >
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="staff">Staff</SelectItem>
                      <SelectItem value="manager">Manager</SelectItem>
                      <SelectItem value="admin">Admin</SelectItem>
                      <SelectItem value="super_admin">Super Admin</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {newStaff.role !== "super_admin" && (
                <div>
                  <Label htmlFor="store" className="text-sm">Assigned Store *</Label>
                  <Select
                    value={newStaff.storeId}
                    onValueChange={(value) => setNewStaff({ ...newStaff, storeId: value })}
                  >
                    <SelectTrigger
                      className={cn(
                        "mt-1.5",
                        "bg-secondary/50 border-border/50",
                        "dark:bg-card/50 dark:border-primary/10"
                      )}
                    >
                      <SelectValue placeholder="Select a store" />
                    </SelectTrigger>
                    <SelectContent className="max-h-[300px]">
                      {locations.map((location) => (
                        <SelectItem key={location.id} value={location.id.toString()}>
                          {location.name} - {location.city}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              <div
                className={cn(
                  "rounded-lg p-3",
                  "bg-primary/10 border border-primary/20"
                )}
              >
                <p className="text-sm font-semibold text-primary mb-1">Permissions</p>
                <p className="text-xs text-muted-foreground">
                  {newStaff.role &&
                    roleConfig[newStaff.role as keyof typeof roleConfig].defaultPermissions.join(
                      ", "
                    )}
                </p>
              </div>
            </div>

            <DialogFooter>
              <NeonButton variant="ghost" onClick={() => setIsAddDialogOpen(false)} disabled={isInviting}>
                Cancel
              </NeonButton>
              <NeonButton onClick={handleInviteStaff} glow disabled={isInviting}>
                {isInviting ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Sending Invite...
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4 mr-2" />
                    Send Invitation
                  </>
                )}
              </NeonButton>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <GlassCard glowColor="purple" gradient="purple" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Total Staff</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.total} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-purple/20 to-ios-pink/10 text-ios-purple",
                "dark:from-neon-purple/20 dark:to-neon-pink/10 dark:text-neon-purple",
                "shadow-[0_4px_12px_rgba(175,82,222,0.2)] dark:shadow-[0_4px_15px_rgba(168,85,247,0.3)]"
              )}
            >
              <Users className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="cyan" gradient="blue" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Admins</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.admins} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-blue/20 to-ios-teal/10 text-ios-blue",
                "dark:from-neon-cyan/20 dark:to-neon-blue/10 dark:text-neon-cyan",
                "shadow-[0_4px_12px_rgba(0,122,255,0.2)] dark:shadow-[0_4px_15px_rgba(0,255,255,0.3)]"
              )}
            >
              <Shield className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="accent" gradient="green" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Managers</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.managers} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-green/20 to-ios-teal/10 text-ios-green",
                "dark:from-neon-green/20 dark:to-neon-cyan/10 dark:text-neon-green",
                "shadow-[0_4px_12px_rgba(52,199,89,0.2)] dark:shadow-[0_4px_15px_rgba(0,255,136,0.3)]"
              )}
            >
              <Briefcase className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>

        <GlassCard glowColor="orange" gradient="orange" className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-muted-foreground">Active</p>
              <h3 className="text-2xl font-bold mt-1">
                <AnimatedCounter value={stats.active} />
              </h3>
            </div>
            <div
              className={cn(
                "h-10 w-10 rounded-xl flex items-center justify-center",
                "bg-gradient-to-br from-ios-orange/20 to-ios-yellow/10 text-ios-orange",
                "dark:from-neon-orange/20 dark:to-amber-500/10 dark:text-neon-orange",
                "shadow-[0_4px_12px_rgba(255,149,0,0.2)] dark:shadow-[0_4px_15px_rgba(255,136,0,0.3)]"
              )}
            >
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Filters */}
      <GlassCard className="p-4" gradient="cyan" intensity="subtle">
        <div className="grid md:grid-cols-3 gap-4">
          <div className="relative md:col-span-2">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search by name, email, or phone..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className={cn(
                "pl-10",
                "bg-secondary/50 border-border/50",
                "dark:bg-card/50 dark:border-primary/10"
              )}
            />
          </div>

          <Select value={filterRole} onValueChange={setFilterRole}>
            <SelectTrigger
              className={cn(
                "bg-secondary/50 border-border/50",
                "dark:bg-card/50 dark:border-primary/10"
              )}
            >
              <SelectValue placeholder="Filter by role" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Roles</SelectItem>
              <SelectItem value="admin">Admin</SelectItem>
              <SelectItem value="manager">Manager</SelectItem>
              <SelectItem value="staff">Staff</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </GlassCard>

      {/* Staff List */}
      <div className="grid gap-4">
        {!loading && filteredStaff.map((member) => {
          const RoleIcon = roleConfig[member.role].icon;
          const roleVariant = roleConfig[member.role].variant;

          return (
            <GlassCard
              key={member.id}
              hoverable
              glowColor={member.role === "admin" || member.role === "super_admin" ? "purple" : "none"}
            >
              <div className="p-4">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex items-start gap-4 flex-1">
                    <div
                      className={cn(
                        "p-3 rounded-xl",
                        roleVariant === "vip" && "bg-ios-purple/10 text-ios-purple dark:bg-neon-purple/10 dark:text-neon-purple dark:shadow-glow-purple",
                        roleVariant === "info" && "bg-primary/10 text-primary dark:shadow-glow-primary",
                        roleVariant === "success" && "bg-accent/10 text-accent dark:bg-neon-green/10 dark:text-neon-green",
                        roleVariant === "default" && "bg-muted text-muted-foreground"
                      )}
                    >
                      <RoleIcon className="h-6 w-6" />
                    </div>

                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="font-semibold">{member.name}</h3>
                        <GlowingBadge variant={roleVariant}>
                          {roleConfig[member.role].label}
                        </GlowingBadge>
                        {member.status === "invited" ? (
                          <GlowingBadge variant="warning">
                            Invited
                          </GlowingBadge>
                        ) : (
                          <StatusPulse
                            variant={member.status === "active" ? "online" : "offline"}
                            size="sm"
                          />
                        )}
                      </div>

                      <div className="grid md:grid-cols-2 gap-2 text-sm text-muted-foreground">
                        <div className="flex items-center gap-2">
                          <Mail className="h-3 w-3" />
                          {member.email}
                        </div>
                        <div className="flex items-center gap-2">
                          <Phone className="h-3 w-3" />
                          {member.phone}
                        </div>
                        {member.storeName && (
                          <div className="flex items-center gap-2">
                            <Store className="h-3 w-3" />
                            {member.storeName}
                          </div>
                        )}
                        <div className="flex items-center gap-2">
                          <Calendar className="h-3 w-3" />
                          Hired: {new Date(member.hireDate).toLocaleDateString()}
                        </div>
                      </div>

                      {member.role !== "super_admin" && (
                        <div className="mt-3 flex flex-wrap gap-4 text-xs">
                          <div className="flex items-center gap-1">
                            <span className="text-muted-foreground">Orders:</span>
                            <span className="font-semibold text-primary">
                              {member.performance.ordersHandled}
                            </span>
                          </div>
                          <div className="flex items-center gap-1">
                            <span className="text-muted-foreground">Avg Time:</span>
                            <span className="font-semibold text-accent dark:text-neon-green">
                              {member.performance.avgResponseTime}m
                            </span>
                          </div>
                          <div className="flex items-center gap-1">
                            <Star className="h-3 w-3 text-ios-yellow dark:text-neon-orange fill-current" />
                            <span className="font-semibold">
                              {member.performance.rating}/5.0
                            </span>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="flex gap-2">
                    {member.status === "invited" ? (
                      <NeonButton
                        variant="secondary"
                        size="sm"
                        onClick={() => handleResendInvite(member)}
                        disabled={resendingId === member.id}
                        className="gap-1"
                      >
                        {resendingId === member.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <RefreshCw className="h-4 w-4" />
                        )}
                        Resend Invite
                      </NeonButton>
                    ) : (
                      <NeonButton
                        variant="secondary"
                        size="sm"
                        onClick={() => handleToggleStatus(member.id)}
                      >
                        {member.status === "active" ? "Deactivate" : "Activate"}
                      </NeonButton>
                    )}
                    <NeonButton variant="secondary" size="icon">
                      <Edit className="h-4 w-4" />
                    </NeonButton>
                    {member.role !== "super_admin" && (
                      <NeonButton
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDeleteStaff(member.id)}
                        className="text-destructive hover:bg-destructive/10"
                      >
                        <Trash2 className="h-4 w-4" />
                      </NeonButton>
                    )}
                  </div>
                </div>
              </div>
            </GlassCard>
          );
        })}
      </div>

      {loading && (
        <GlassCard className="py-12 text-center">
          <Loader2 className="h-12 w-12 text-primary mx-auto mb-3 animate-spin" />
          <p className="text-lg font-medium mb-1">Loading staff...</p>
        </GlassCard>
      )}

      {!loading && filteredStaff.length === 0 && (
        <GlassCard className="py-12 text-center">
          <Users className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium mb-1">No staff members found</p>
          <p className="text-sm text-muted-foreground">
            {staff.length === 0 ? "Invite your first team member to get started" : "Try adjusting your filters"}
          </p>
        </GlassCard>
      )}
    </div>
  );
};
