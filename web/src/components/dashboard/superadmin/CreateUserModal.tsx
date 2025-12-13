import { useState } from "react";
import { supabase } from "@/lib/supabase";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { locations } from "@/data/locations";
import { Loader2 } from "lucide-react";

interface CreateUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function CreateUserModal({ isOpen, onClose, onSuccess }: CreateUserModalProps) {
  const { toast } = useToast();
  const { profile } = useAuth();
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    email: "",
    password: "",
    full_name: "",
    phone: "",
    role: "staff" as "admin" | "manager" | "staff",
    store_id: "",
    assigned_stores: [] as number[],
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Validate form
      if (!formData.email || !formData.password || !formData.full_name || !formData.role) {
        throw new Error("Please fill in all required fields");
      }

      if (formData.password.length < 6) {
        throw new Error("Password must be at least 6 characters");
      }

      // Create auth user
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: formData.email,
        password: formData.password,
        email_confirm: true,
        user_metadata: {
          full_name: formData.full_name,
          phone: formData.phone,
        },
      });

      if (authError) throw authError;
      if (!authData.user) throw new Error("Failed to create user");

      // Prepare profile data
      const profileData: any = {
        id: authData.user.id,
        role: formData.role,
        full_name: formData.full_name,
        phone: formData.phone || null,
        is_active: true,
        is_system_admin: false,
        created_by: profile?.id,
      };

      // Add store assignments based on role
      if (formData.role === "admin") {
        // Admin can have multiple stores
        if (formData.assigned_stores.length > 0) {
          profileData.assigned_stores = formData.assigned_stores;
          profileData.store_id = formData.assigned_stores[0]; // Primary store
        }
        profileData.can_hire_roles = ["manager", "staff"];
      } else if (formData.role === "manager") {
        // Manager has single store
        if (formData.store_id) {
          profileData.store_id = parseInt(formData.store_id);
          profileData.assigned_stores = [parseInt(formData.store_id)];
        }
        profileData.can_hire_roles = ["staff"];
      } else if (formData.role === "staff") {
        // Staff has single store
        if (formData.store_id) {
          profileData.store_id = parseInt(formData.store_id);
          profileData.assigned_stores = [parseInt(formData.store_id)];
        }
        profileData.can_hire_roles = [];
      }

      // Set default permissions based on role
      if (formData.role === "admin") {
        profileData.detailed_permissions = {
          orders: { manage: true },
          menu: { manage: true },
          analytics: { view: true, financial: true },
          users: { manage: true },
          settings: { manage: true },
          stores: { view: true, update: true },
          inventory: { manage: true },
        };
      } else if (formData.role === "manager") {
        profileData.detailed_permissions = {
          orders: { view: true, update: true },
          menu: { view: true, update: true },
          analytics: { view: true },
          inventory: { view: true, update: true },
          settings: { view: true },
        };
      } else if (formData.role === "staff") {
        profileData.detailed_permissions = {
          orders: { view: true, update: true },
          menu: { view: true },
        };
      }

      // Create user profile
      const { error: profileError } = await supabase
        .from("user_profiles")
        .insert(profileData);

      if (profileError) {
        // If profile creation fails, delete the auth user
        await supabase.auth.admin.deleteUser(authData.user.id);
        throw profileError;
      }

      toast({
        title: "User created",
        description: `${formData.full_name} has been created successfully`,
      });

      // Reset form and close
      setFormData({
        email: "",
        password: "",
        full_name: "",
        phone: "",
        role: "staff",
        store_id: "",
        assigned_stores: [],
      });

      onSuccess();
      onClose();
    } catch (error: any) {
      console.error("Error creating user:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to create user",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleStoreToggle = (storeId: number) => {
    if (formData.assigned_stores.includes(storeId)) {
      setFormData({
        ...formData,
        assigned_stores: formData.assigned_stores.filter((id) => id !== storeId),
      });
    } else {
      setFormData({
        ...formData,
        assigned_stores: [...formData.assigned_stores, storeId],
      });
    }
  };

  // Get all stores
  const activeStores = locations;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="dark bg-gray-800 border-gray-700 max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-white">Create New User</DialogTitle>
          <DialogDescription className="text-gray-400">
            Add a new user to the system with specified role and permissions
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Email */}
          <div className="space-y-2">
            <Label htmlFor="email" className="text-gray-300">
              Email *
            </Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              placeholder="user@example.com"
              required
              className="bg-gray-700 border-gray-600 text-white"
            />
          </div>

          {/* Password */}
          <div className="space-y-2">
            <Label htmlFor="password" className="text-gray-300">
              Password *
            </Label>
            <Input
              id="password"
              type="password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              placeholder="Minimum 6 characters"
              required
              minLength={6}
              className="bg-gray-700 border-gray-600 text-white"
            />
          </div>

          {/* Full Name */}
          <div className="space-y-2">
            <Label htmlFor="full_name" className="text-gray-300">
              Full Name *
            </Label>
            <Input
              id="full_name"
              type="text"
              value={formData.full_name}
              onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
              placeholder="John Doe"
              required
              className="bg-gray-700 border-gray-600 text-white"
            />
          </div>

          {/* Phone */}
          <div className="space-y-2">
            <Label htmlFor="phone" className="text-gray-300">
              Phone
            </Label>
            <Input
              id="phone"
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              placeholder="555-0100"
              className="bg-gray-700 border-gray-600 text-white"
            />
          </div>

          {/* Role */}
          <div className="space-y-2">
            <Label htmlFor="role" className="text-gray-300">
              Role *
            </Label>
            <Select
              value={formData.role}
              onValueChange={(value: any) =>
                setFormData({ ...formData, role: value, assigned_stores: [], store_id: "" })
              }
            >
              <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                <SelectValue placeholder="Select role" />
              </SelectTrigger>
              <SelectContent className="bg-gray-700 border-gray-600">
                <SelectItem value="admin">Admin (Multi-Store)</SelectItem>
                <SelectItem value="manager">Manager (Single Store)</SelectItem>
                <SelectItem value="staff">Staff (Single Store)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Store Assignment - Admin (Multi-Select) */}
          {formData.role === "admin" && (
            <div className="space-y-2">
              <Label className="text-gray-300">Assigned Stores (Select Multiple)</Label>
              <div className="grid grid-cols-2 gap-2 max-h-48 overflow-y-auto p-2 bg-gray-700/50 rounded border border-gray-600">
                {activeStores.map((store) => (
                  <label
                    key={store.id}
                    className="flex items-center gap-2 p-2 rounded hover:bg-gray-600 cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      checked={formData.assigned_stores.includes(store.id)}
                      onChange={() => handleStoreToggle(store.id)}
                      className="rounded"
                    />
                    <span className="text-sm text-gray-300">
                      #{store.id} - {store.name}
                    </span>
                  </label>
                ))}
              </div>
              <p className="text-xs text-gray-400">
                Selected: {formData.assigned_stores.length} store(s)
              </p>
            </div>
          )}

          {/* Store Assignment - Manager/Staff (Single Select) */}
          {(formData.role === "manager" || formData.role === "staff") && (
            <div className="space-y-2">
              <Label htmlFor="store_id" className="text-gray-300">
                Assigned Store *
              </Label>
              <Select value={formData.store_id} onValueChange={(value) => setFormData({ ...formData, store_id: value })}>
                <SelectTrigger className="bg-gray-700 border-gray-600 text-white">
                  <SelectValue placeholder="Select store" />
                </SelectTrigger>
                <SelectContent className="bg-gray-700 border-gray-600">
                  {activeStores.map((store) => (
                    <SelectItem key={store.id} value={store.id.toString()}>
                      #{store.id} - {store.name} ({store.city})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              disabled={loading}
              className="border-gray-600 hover:bg-gray-700"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading}
              className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Creating...
                </>
              ) : (
                "Create User"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
