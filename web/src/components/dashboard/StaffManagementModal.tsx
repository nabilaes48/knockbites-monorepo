import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
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
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Edit, Trash2, Shield, Users, Briefcase, User, ChefHat, ShoppingCart, Package, Truck, Crown, X, Check, Info } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { locations } from "@/data/locations";
import { cn } from "@/lib/utils";
import { StatusPulse } from "@/components/ui/StatusPulse";

interface StaffMember {
  id: number;
  name: string;
  email: string;
  role: string;
  storeId?: number;
  storeName?: string;
  active: boolean;
}

const initialStaff: StaffMember[] = [
  {
    id: 1,
    name: "Sarah Manager",
    email: "manager@knockbites.com",
    role: "manager",
    storeId: 1,
    storeName: "Highland Mills Snack Shop Inc - Highland Mills",
    active: true,
  },
  {
    id: 2,
    name: "Mike Staff",
    email: "staff@knockbites.com",
    role: "staff",
    storeId: 1,
    storeName: "Highland Mills Snack Shop Inc - Highland Mills",
    active: true,
  },
  {
    id: 3,
    name: "Chef Maria",
    email: "kitchen@knockbites.com",
    role: "kitchen",
    storeId: 1,
    storeName: "Highland Mills Snack Shop Inc - Highland Mills",
    active: true,
  },
  {
    id: 4,
    name: "Tom Assistant",
    email: "assistant@knockbites.com",
    role: "assistant-manager",
    storeId: 1,
    storeName: "Highland Mills Snack Shop Inc - Highland Mills",
    active: true,
  },
  {
    id: 5,
    name: "Lisa Cashier",
    email: "cashier@knockbites.com",
    role: "cashier",
    storeId: 1,
    storeName: "Highland Mills Snack Shop Inc - Highland Mills",
    active: true,
  },
];

interface StaffManagementModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const StaffManagementModal = ({ isOpen, onClose }: StaffManagementModalProps) => {
  const { toast } = useToast();
  const [staff, setStaff] = useState<StaffMember[]>(initialStaff);
  const [activeTab, setActiveTab] = useState("all");
  const [isAddingStaff, setIsAddingStaff] = useState(false);
  const [newStaff, setNewStaff] = useState({
    name: "",
    email: "",
    role: "staff",
    storeId: 1,
  });

  const getRoleIcon = (role: string) => {
    switch (role) {
      case "super_admin":
        return Crown;
      case "admin":
        return Shield;
      case "manager":
        return Briefcase;
      case "assistant-manager":
        return Briefcase;
      case "staff":
        return Users;
      case "kitchen":
        return ChefHat;
      case "cashier":
        return ShoppingCart;
      case "inventory":
        return Package;
      case "delivery":
        return Truck;
      default:
        return User;
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case "super_admin":
        return {
          light: "bg-purple-100 text-purple-700 border-purple-200",
          dark: "dark:bg-neon-purple/20 dark:text-neon-purple dark:border-neon-purple/30",
        };
      case "admin":
        return {
          light: "bg-blue-100 text-blue-700 border-blue-200",
          dark: "dark:bg-neon-blue/20 dark:text-neon-blue dark:border-neon-blue/30",
        };
      case "manager":
        return {
          light: "bg-green-100 text-green-700 border-green-200",
          dark: "dark:bg-neon-green/20 dark:text-neon-green dark:border-neon-green/30",
        };
      case "assistant-manager":
        return {
          light: "bg-violet-100 text-violet-700 border-violet-200",
          dark: "dark:bg-neon-purple/20 dark:text-neon-purple dark:border-neon-purple/30",
        };
      case "staff":
        return {
          light: "bg-sky-100 text-sky-700 border-sky-200",
          dark: "dark:bg-neon-cyan/20 dark:text-neon-cyan dark:border-neon-cyan/30",
        };
      case "kitchen":
        return {
          light: "bg-orange-100 text-orange-700 border-orange-200",
          dark: "dark:bg-neon-orange/20 dark:text-neon-orange dark:border-neon-orange/30",
        };
      case "cashier":
        return {
          light: "bg-cyan-100 text-cyan-700 border-cyan-200",
          dark: "dark:bg-neon-cyan/20 dark:text-neon-cyan dark:border-neon-cyan/30",
        };
      case "inventory":
        return {
          light: "bg-amber-100 text-amber-700 border-amber-200",
          dark: "dark:bg-neon-orange/20 dark:text-neon-orange dark:border-neon-orange/30",
        };
      case "delivery":
        return {
          light: "bg-teal-100 text-teal-700 border-teal-200",
          dark: "dark:bg-neon-green/20 dark:text-neon-green dark:border-neon-green/30",
        };
      default:
        return {
          light: "bg-gray-100 text-gray-700 border-gray-200",
          dark: "dark:bg-white/10 dark:text-white dark:border-white/20",
        };
    }
  };

  const handleAddStaff = () => {
    if (!newStaff.name || !newStaff.email) {
      toast({
        title: "Missing Information",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    const selectedLocation = locations.find((loc) => loc.id === newStaff.storeId);

    const staffMember: StaffMember = {
      id: Date.now(),
      name: newStaff.name,
      email: newStaff.email,
      role: newStaff.role,
      storeId: newStaff.storeId,
      storeName: selectedLocation ? `${selectedLocation.name} - ${selectedLocation.city}` : "Unknown Store",
      active: true,
    };

    setStaff([...staff, staffMember]);
    setNewStaff({ name: "", email: "", role: "staff", storeId: 1 });
    setIsAddingStaff(false);

    toast({
      title: "Staff Added",
      description: `${staffMember.name} has been added to your team`,
    });
  };

  const handleRemoveStaff = (id: number) => {
    const member = staff.find((s) => s.id === id);
    setStaff(staff.filter((s) => s.id !== id));

    toast({
      title: "Staff Removed",
      description: `${member?.name} has been removed from your team`,
      variant: "destructive",
    });
  };

  const filteredStaff =
    activeTab === "all" ? staff : staff.filter((s) => s.role === activeTab);

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className={cn(
        "max-w-4xl max-h-[90vh] overflow-y-auto",
        // Light mode - Apple clean
        "bg-white/95 border-gray-200/80",
        // Dark mode - Glassmorphism
        "dark:bg-card/80 dark:backdrop-blur-xl dark:border-white/10",
        "dark:shadow-[0_0_50px_rgba(0,0,0,0.5)]"
      )}>
        {/* Header with gradient accent */}
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-ios-purple via-ios-pink to-ios-orange dark:from-neon-purple dark:via-neon-pink dark:to-neon-orange" />

        <DialogHeader className="pt-2">
          <DialogTitle className={cn(
            "text-2xl font-semibold flex items-center gap-3",
            "text-gray-900 dark:text-white"
          )}>
            <div className={cn(
              "p-2 rounded-xl",
              "bg-ios-purple/10 text-ios-purple",
              "dark:bg-neon-purple/20 dark:text-neon-purple"
            )}>
              <Users className="h-5 w-5" />
            </div>
            Staff Management
          </DialogTitle>
          <DialogDescription className="text-muted-foreground">
            Manage staff accounts, roles, and permissions
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {/* Stats */}
          <div className="grid grid-cols-3 gap-4">
            <div className={cn(
              "p-4 rounded-xl text-center",
              "bg-gray-50 border border-gray-200",
              "dark:bg-neon-purple/10 dark:border-neon-purple/30"
            )}>
              <div className={cn(
                "text-3xl font-bold",
                "text-gray-900 dark:text-neon-purple"
              )}>
                {staff.length}
              </div>
              <p className="text-sm text-muted-foreground mt-1">Total Staff</p>
            </div>
            <div className={cn(
              "p-4 rounded-xl text-center",
              "bg-gray-50 border border-gray-200",
              "dark:bg-neon-green/10 dark:border-neon-green/30"
            )}>
              <div className={cn(
                "text-3xl font-bold",
                "text-gray-900 dark:text-neon-green"
              )}>
                {staff.filter((s) => s.role === "manager").length}
              </div>
              <p className="text-sm text-muted-foreground mt-1">Managers</p>
            </div>
            <div className={cn(
              "p-4 rounded-xl text-center",
              "bg-gray-50 border border-gray-200",
              "dark:bg-neon-cyan/10 dark:border-neon-cyan/30"
            )}>
              <div className={cn(
                "text-3xl font-bold",
                "text-gray-900 dark:text-neon-cyan"
              )}>
                {staff.filter((s) => s.active).length}
              </div>
              <p className="text-sm text-muted-foreground mt-1">Active</p>
            </div>
          </div>

          {/* Add Staff Form */}
          {isAddingStaff ? (
            <div className={cn(
              "p-4 rounded-xl",
              "bg-gray-50 border border-gray-200",
              "dark:bg-white/5 dark:border-white/10"
            )}>
              <h3 className="font-semibold text-lg text-foreground mb-4 flex items-center gap-2">
                <Plus className="h-5 w-5" />
                Add New Staff Member
              </h3>

              <div className="grid md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="staffName" className="text-foreground">Full Name *</Label>
                  <Input
                    id="staffName"
                    placeholder="John Doe"
                    value={newStaff.name}
                    onChange={(e) => setNewStaff({ ...newStaff, name: e.target.value })}
                    className={cn(
                      "bg-white border-gray-300",
                      "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                    )}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="staffEmail" className="text-foreground">Email *</Label>
                  <Input
                    id="staffEmail"
                    type="email"
                    placeholder="john@knockbites.com"
                    value={newStaff.email}
                    onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                    className={cn(
                      "bg-white border-gray-300",
                      "dark:bg-white/5 dark:border-white/20 dark:focus:border-neon-cyan"
                    )}
                  />
                </div>
              </div>

              <div className="space-y-2 mt-4">
                <Label htmlFor="staffRole" className="text-foreground">Role *</Label>
                <Select
                  value={newStaff.role}
                  onValueChange={(value) => setNewStaff({ ...newStaff, role: value })}
                >
                  <SelectTrigger className={cn(
                    "bg-white border-gray-300",
                    "dark:bg-white/5 dark:border-white/20"
                  )}>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="dark:bg-card dark:border-white/10">
                    <SelectItem value="admin">Admin - Full store access & staff management</SelectItem>
                    <SelectItem value="manager">Manager - Full store access</SelectItem>
                    <SelectItem value="assistant-manager">Assistant Manager - Store operations</SelectItem>
                    <SelectItem value="staff">Staff - Orders & menu</SelectItem>
                    <SelectItem value="kitchen">Kitchen - Orders only</SelectItem>
                    <SelectItem value="cashier">Cashier - Point of sale</SelectItem>
                    <SelectItem value="inventory">Inventory Manager - Stock & supplies</SelectItem>
                    <SelectItem value="delivery">Delivery Driver - Order fulfillment</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2 mt-4">
                <Label htmlFor="staffStore" className="text-foreground">Assigned Store</Label>
                <Input
                  id="staffStore"
                  value="Highland Mills Snack Shop Inc - Highland Mills"
                  disabled
                  className={cn(
                    "bg-gray-100 border-gray-300",
                    "dark:bg-white/5 dark:border-white/10 dark:text-muted-foreground"
                  )}
                />
              </div>

              <div className="flex gap-2 justify-end mt-4">
                <Button
                  variant="outline"
                  onClick={() => setIsAddingStaff(false)}
                  className={cn(
                    "border-gray-300 hover:bg-gray-100",
                    "dark:border-white/20 dark:hover:bg-white/10"
                  )}
                >
                  <X className="h-4 w-4 mr-2" />
                  Cancel
                </Button>
                <Button
                  onClick={handleAddStaff}
                  className={cn(
                    "bg-ios-green hover:bg-ios-green/90 text-white",
                    "dark:bg-gradient-to-r dark:from-neon-green dark:to-neon-cyan dark:hover:opacity-90",
                    "dark:shadow-[0_0_20px_rgba(0,255,136,0.3)]"
                  )}
                >
                  <Check className="h-4 w-4 mr-2" />
                  Add Staff Member
                </Button>
              </div>
            </div>
          ) : (
            <Button
              onClick={() => setIsAddingStaff(true)}
              className={cn(
                "w-full bg-ios-blue hover:bg-ios-blue/90 text-white",
                "dark:bg-gradient-to-r dark:from-neon-cyan dark:to-neon-blue dark:hover:opacity-90",
                "dark:shadow-[0_0_20px_rgba(0,255,255,0.2)]"
              )}
            >
              <Plus className="h-4 w-4 mr-2" />
              Add New Staff Member
            </Button>
          )}

          {/* Staff List */}
          <div>
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className={cn(
                "grid w-full grid-cols-4",
                "bg-gray-100",
                "dark:bg-white/5"
              )}>
                <TabsTrigger
                  value="all"
                  className={cn(
                    "data-[state=active]:bg-white data-[state=active]:text-ios-blue",
                    "dark:data-[state=active]:bg-neon-cyan/20 dark:data-[state=active]:text-neon-cyan"
                  )}
                >
                  All ({staff.length})
                </TabsTrigger>
                <TabsTrigger
                  value="manager"
                  className={cn(
                    "data-[state=active]:bg-white data-[state=active]:text-ios-green",
                    "dark:data-[state=active]:bg-neon-green/20 dark:data-[state=active]:text-neon-green"
                  )}
                >
                  Managers ({staff.filter((s) => s.role === "manager").length})
                </TabsTrigger>
                <TabsTrigger
                  value="staff"
                  className={cn(
                    "data-[state=active]:bg-white data-[state=active]:text-ios-blue",
                    "dark:data-[state=active]:bg-neon-cyan/20 dark:data-[state=active]:text-neon-cyan"
                  )}
                >
                  Staff ({staff.filter((s) => s.role === "staff").length})
                </TabsTrigger>
                <TabsTrigger
                  value="kitchen"
                  className={cn(
                    "data-[state=active]:bg-white data-[state=active]:text-ios-orange",
                    "dark:data-[state=active]:bg-neon-orange/20 dark:data-[state=active]:text-neon-orange"
                  )}
                >
                  Kitchen ({staff.filter((s) => s.role === "kitchen").length})
                </TabsTrigger>
              </TabsList>

              <TabsContent value={activeTab} className="mt-4 space-y-3">
                {filteredStaff.length > 0 ? (
                  filteredStaff.map((member) => {
                    const Icon = getRoleIcon(member.role);
                    const colors = getRoleColor(member.role);
                    return (
                      <div
                        key={member.id}
                        className={cn(
                          "p-4 rounded-xl",
                          "bg-white border border-gray-200",
                          "dark:bg-white/5 dark:border-white/10",
                          "hover:shadow-md dark:hover:shadow-[0_0_15px_rgba(0,255,255,0.1)]",
                          "transition-all duration-200"
                        )}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-4">
                            <div className={cn(
                              "p-3 rounded-xl border",
                              colors.light,
                              colors.dark
                            )}>
                              <Icon className="h-5 w-5" />
                            </div>
                            <div>
                              <div className="flex items-center gap-2">
                                <h3 className="font-semibold text-foreground">{member.name}</h3>
                                <Badge
                                  variant="outline"
                                  className={cn(
                                    "capitalize",
                                    colors.light,
                                    colors.dark
                                  )}
                                >
                                  {member.role}
                                </Badge>
                                {member.active && (
                                  <StatusPulse variant="online" size="sm" />
                                )}
                              </div>
                              <p className="text-sm text-muted-foreground">{member.email}</p>
                              {member.storeName && (
                                <p className="text-xs text-muted-foreground mt-1">
                                  {member.storeName}
                                </p>
                              )}
                            </div>
                          </div>

                          <div className="flex gap-2">
                            <Button
                              variant="outline"
                              size="icon"
                              className={cn(
                                "border-gray-300 hover:bg-ios-blue/10 hover:text-ios-blue hover:border-ios-blue",
                                "dark:border-white/20 dark:hover:bg-neon-cyan/20 dark:hover:text-neon-cyan dark:hover:border-neon-cyan"
                              )}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="icon"
                              className={cn(
                                "text-destructive border-gray-300 hover:bg-destructive/10 hover:border-destructive",
                                "dark:border-white/20 dark:hover:bg-destructive/20"
                              )}
                              onClick={() => handleRemoveStaff(member.id)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <div className={cn(
                    "py-12 text-center rounded-xl border-2 border-dashed",
                    "border-gray-300 text-muted-foreground",
                    "dark:border-white/20"
                  )}>
                    <Users className="h-8 w-8 mx-auto mb-2 opacity-50" />
                    <p>No staff members in this category</p>
                  </div>
                )}
              </TabsContent>
            </Tabs>
          </div>

          {/* Permissions Info */}
          <div className={cn(
            "p-4 rounded-xl",
            "bg-ios-blue/5 border border-ios-blue/20",
            "dark:bg-neon-cyan/5 dark:border-neon-cyan/20"
          )}>
            <h3 className={cn(
              "font-semibold mb-3 text-lg flex items-center gap-2",
              "text-ios-blue dark:text-neon-cyan"
            )}>
              <Info className="h-5 w-5" />
              Role Permissions
            </h3>
            <div className="grid md:grid-cols-2 gap-3 text-sm">
              <p className="text-muted-foreground">
                <strong className="text-ios-blue dark:text-neon-blue">Admin:</strong> Full store access, staff management, all features
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-green dark:text-neon-green">Manager:</strong> Full store operations, staff management, analytics
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-purple dark:text-neon-purple">Assistant Manager:</strong> Store operations, inventory, scheduling
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-blue dark:text-neon-cyan">Staff:</strong> Orders and menu management only
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-orange dark:text-neon-orange">Kitchen:</strong> View and update orders only
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-teal dark:text-neon-cyan">Cashier:</strong> Point of sale, customer transactions
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-yellow dark:text-neon-orange">Inventory:</strong> Stock management, supplier orders
              </p>
              <p className="text-muted-foreground">
                <strong className="text-ios-green dark:text-neon-green">Delivery:</strong> Order fulfillment, delivery tracking
              </p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};
