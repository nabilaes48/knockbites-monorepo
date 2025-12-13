import { useState, useEffect } from "react";
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
import { locations } from "@/data/locations";
import { Loader2 } from "lucide-react";

interface EditUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: any;
  onSuccess: () => void;
}

export function EditUserModal({ isOpen, onClose, user, onSuccess }: EditUserModalProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    full_name: user.full_name || "",
    phone: user.phone || "",
    role: user.role || "staff",
    store_id: user.store_id?.toString() || "",
    assigned_stores: user.assigned_stores || [],
    is_active: user.is_active ?? true,
  });

  useEffect(() => {
    setFormData({
      full_name: user.full_name || "",
      phone: user.phone || "",
      role: user.role || "staff",
      store_id: user.store_id?.toString() || "",
      assigned_stores: user.assigned_stores || [],
      is_active: user.is_active ?? true,
    });
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Prepare update data
      const updateData: any = {
        full_name: formData.full_name,
        phone: formData.phone || null,
        role: formData.role,
        is_active: formData.is_active,
      };

      // Update store assignments based on role
      if (formData.role === "admin") {
        updateData.assigned_stores = formData.assigned_stores;
        updateData.store_id = formData.assigned_stores.length > 0 ? formData.assigned_stores[0] : null;
        updateData.can_hire_roles = ["manager", "staff"];
      } else if (formData.role === "manager") {
        const storeId = parseInt(formData.store_id);
        updateData.store_id = storeId;
        updateData.assigned_stores = [storeId];
        updateData.can_hire_roles = ["staff"];
      } else if (formData.role === "staff") {
        const storeId = parseInt(formData.store_id);
        updateData.store_id = storeId;
        updateData.assigned_stores = [storeId];
        updateData.can_hire_roles = [];
      }

      // Update permissions based on role
      if (formData.role === "admin") {
        updateData.detailed_permissions = {
          orders: { manage: true },
          menu: { manage: true },
          analytics: { view: true, financial: true },
          users: { manage: true },
          settings: { manage: true },
          stores: { view: true, update: true },
          inventory: { manage: true },
        };
      } else if (formData.role === "manager") {
        updateData.detailed_permissions = {
          orders: { view: true, update: true },
          menu: { view: true, update: true },
          analytics: { view: true },
          inventory: { view: true, update: true },
          settings: { view: true },
        };
      } else if (formData.role === "staff") {
        updateData.detailed_permissions = {
          orders: { view: true, update: true },
          menu: { view: true },
        };
      }

      // Update user profile
      const { error } = await supabase
        .from("user_profiles")
        .update(updateData)
        .eq("id", user.id);

      if (error) throw error;

      toast({
        title: "User updated",
        description: `${formData.full_name} has been updated successfully`,
      });

      onSuccess();
      onClose();
    } catch (error: any) {
      console.error("Error updating user:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to update user",
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
        assigned_stores: formData.assigned_stores.filter((id: number) => id !== storeId),
      });
    } else {
      setFormData({
        ...formData,
        assigned_stores: [...formData.assigned_stores, storeId],
      });
    }
  };

  const activeStores = locations;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="dark bg-gray-800 border-gray-700 max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-white">Edit User</DialogTitle>
          <DialogDescription className="text-gray-400">
            Update user information, role, and permissions
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
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
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-gray-700 border-gray-600">
                {user.role !== "super_admin" && (
                  <>
                    <SelectItem value="admin">Admin (Multi-Store)</SelectItem>
                    <SelectItem value="manager">Manager (Single Store)</SelectItem>
                    <SelectItem value="staff">Staff (Single Store)</SelectItem>
                  </>
                )}
                {user.role === "super_admin" && (
                  <SelectItem value="super_admin">Super Admin (All Stores)</SelectItem>
                )}
              </SelectContent>
            </Select>
          </div>

          {/* Admin Multi-Store Assignment */}
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

          {/* Manager/Staff Single Store Assignment */}
          {(formData.role === "manager" || formData.role === "staff") && (
            <div className="space-y-2">
              <Label htmlFor="store_id" className="text-gray-300">
                Assigned Store *
              </Label>
              <Select
                value={formData.store_id}
                onValueChange={(value) => setFormData({ ...formData, store_id: value })}
              >
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
                  Updating...
                </>
              ) : (
                "Update User"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
