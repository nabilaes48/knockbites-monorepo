import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Crown,
  Shield,
  Briefcase,
  Users,
  UserPlus,
  Edit,
  Trash2,
  AlertCircle,
  CheckCircle,
  XCircle,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { CreateUserModal } from "./CreateUserModal";
import { EditUserModal } from "./EditUserModal";
import { useAuth } from "@/contexts/AuthContext";

interface UserProfile {
  id: string;
  role: string;
  full_name: string;
  phone: string | null;
  store_id: number | null;
  assigned_stores: number[];
  is_active: boolean;
  is_system_admin: boolean;
  created_at: string;
  email?: string;
}

export function UserManagementPanel() {
  const { toast } = useToast();
  const { profile } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);

      // Fetch user profiles
      const { data: profiles, error: profilesError } = await supabase
        .from("staff_profiles")
        .select("*")
        .order("created_at", { ascending: false });

      if (profilesError) throw profilesError;

      // Fetch corresponding emails from auth.users
      const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();

      if (authError) {
        console.error("Error fetching auth users:", authError);
        // Continue with profiles even if we can't get emails
        setUsers(profiles || []);
      } else if (authUsers && authUsers.users) {
        // Merge email data with profiles
        const usersWithEmails = (profiles || []).map((profile) => {
          const authUser = authUsers.users.find((u: any) => u.id === profile.id);
          return {
            ...profile,
            email: authUser?.email,
          };
        });
        setUsers(usersWithEmails);
      } else {
        setUsers(profiles || []);
      }
    } catch (error: any) {
      console.error("Error fetching users:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to fetch users",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEditUser = (user: UserProfile) => {
    setSelectedUser(user);
    setEditModalOpen(true);
  };

  const handleDeleteUser = async (userId: string, userName: string) => {
    if (!confirm(`Are you sure you want to delete ${userName}? This action cannot be undone.`)) {
      return;
    }

    try {
      // Deactivate user instead of deleting
      const { error } = await supabase
        .from("staff_profiles")
        .update({ is_active: false })
        .eq("id", userId);

      if (error) throw error;

      toast({
        title: "User deactivated",
        description: `${userName} has been deactivated`,
      });

      fetchUsers();
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to deactivate user",
        variant: "destructive",
      });
    }
  };

  const handleToggleActive = async (user: UserProfile) => {
    try {
      const { error } = await supabase
        .from("staff_profiles")
        .update({ is_active: !user.is_active })
        .eq("id", user.id);

      if (error) throw error;

      toast({
        title: user.is_active ? "User deactivated" : "User activated",
        description: `${user.full_name} has been ${user.is_active ? "deactivated" : "activated"}`,
      });

      fetchUsers();
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to update user status",
        variant: "destructive",
      });
    }
  };

  const getRoleBadge = (role: string, isSystemAdmin: boolean) => {
    const badges = {
      super_admin: {
        label: "Super Admin",
        icon: Crown,
        className: "bg-gradient-to-r from-purple-600 via-pink-600 to-purple-600 text-white",
      },
      admin: {
        label: "Admin",
        icon: Shield,
        className: "bg-gradient-to-r from-blue-600 to-indigo-600 text-white",
      },
      manager: {
        label: "Manager",
        icon: Briefcase,
        className: "bg-gradient-to-r from-green-600 to-emerald-600 text-white",
      },
      staff: {
        label: "Staff",
        icon: Users,
        className: "bg-gradient-to-r from-gray-600 to-slate-600 text-white",
      },
      customer: {
        label: "Customer",
        icon: Users,
        className: "bg-gradient-to-r from-slate-500 to-gray-500 text-white",
      },
    };

    const badge = badges[role as keyof typeof badges] || badges.customer;
    const Icon = badge.icon;

    return (
      <Badge className={badge.className}>
        <Icon className="h-3 w-3 mr-1" />
        {badge.label}
        {isSystemAdmin && <Crown className="h-3 w-3 ml-1 animate-pulse" />}
      </Badge>
    );
  };

  const getStoreCount = (user: UserProfile) => {
    if (user.role === "super_admin") return "All Stores";
    if (user.assigned_stores && user.assigned_stores.length > 0) {
      return `${user.assigned_stores.length} store${user.assigned_stores.length > 1 ? "s" : ""}`;
    }
    if (user.store_id) return `Store #${user.store_id}`;
    return "No assignment";
  };

  if (loading) {
    return (
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-8">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500 mx-auto"></div>
          <p className="mt-4 text-gray-300">Loading users...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              <Users className="h-6 w-6 text-purple-400" />
              User Management
            </h2>
            <p className="text-gray-400 mt-1">
              Manage all users across the system ({users.length} total)
            </p>
          </div>
          <Button
            onClick={() => setCreateModalOpen(true)}
            className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700"
          >
            <UserPlus className="h-4 w-4 mr-2" />
            Create User
          </Button>
        </div>
      </div>

      {/* User Table */}
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-gray-700 hover:bg-gray-700/50">
              <TableHead className="text-gray-300">User</TableHead>
              <TableHead className="text-gray-300">Role</TableHead>
              <TableHead className="text-gray-300">Store Assignment</TableHead>
              <TableHead className="text-gray-300">Status</TableHead>
              <TableHead className="text-gray-300">Created</TableHead>
              <TableHead className="text-gray-300 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-8 text-gray-400">
                  <AlertCircle className="h-8 w-8 mx-auto mb-2 text-gray-500" />
                  No users found
                </TableCell>
              </TableRow>
            ) : (
              users.map((user) => (
                <TableRow
                  key={user.id}
                  className="border-gray-700 hover:bg-gray-700/30"
                >
                  <TableCell>
                    <div>
                      <p className="font-medium text-white">{user.full_name}</p>
                      <p className="text-sm text-gray-400">{user.email || "No email"}</p>
                      {user.phone && (
                        <p className="text-xs text-gray-500">{user.phone}</p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>{getRoleBadge(user.role, user.is_system_admin)}</TableCell>
                  <TableCell className="text-gray-300">{getStoreCount(user)}</TableCell>
                  <TableCell>
                    {user.is_active ? (
                      <Badge variant="outline" className="border-green-500 text-green-400">
                        <CheckCircle className="h-3 w-3 mr-1" />
                        Active
                      </Badge>
                    ) : (
                      <Badge variant="outline" className="border-red-500 text-red-400">
                        <XCircle className="h-3 w-3 mr-1" />
                        Inactive
                      </Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-gray-400 text-sm">
                    {new Date(user.created_at).toLocaleDateString()}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEditUser(user)}
                        className="border-gray-600 hover:bg-gray-700"
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleToggleActive(user)}
                        className={
                          user.is_active
                            ? "border-red-600 text-red-400 hover:bg-red-900/20"
                            : "border-green-600 text-green-400 hover:bg-green-900/20"
                        }
                      >
                        {user.is_active ? (
                          <XCircle className="h-4 w-4" />
                        ) : (
                          <CheckCircle className="h-4 w-4" />
                        )}
                      </Button>
                      {user.id !== profile?.id && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDeleteUser(user.id, user.full_name)}
                          className="border-red-600 text-red-400 hover:bg-red-900/20"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Modals */}
      <CreateUserModal
        isOpen={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        onSuccess={fetchUsers}
      />

      {selectedUser && (
        <EditUserModal
          isOpen={editModalOpen}
          onClose={() => {
            setEditModalOpen(false);
            setSelectedUser(null);
          }}
          user={selectedUser}
          onSuccess={fetchUsers}
        />
      )}
    </div>
  );
}
