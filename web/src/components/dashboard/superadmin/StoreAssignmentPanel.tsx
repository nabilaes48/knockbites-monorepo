import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { Building2 } from "lucide-react";
import { locations } from "@/data/locations";
import { Badge } from "@/components/ui/badge";

export function StoreAssignmentPanel() {
  const [assignments, setAssignments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAssignments();
  }, []);

  const fetchAssignments = async () => {
    try {
      const { data, error } = await supabase
        .from("store_assignments")
        .select(`
          *,
          staff_profiles (full_name, role),
          stores (name, city)
        `)
        .order("created_at", { ascending: false });

      if (error) throw error;
      setAssignments(data || []);
    } catch (error) {
      console.error("Error fetching assignments:", error);
    } finally {
      setLoading(false);
    }
  };

  const activeStores = locations;

  if (loading) {
    return (
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-8">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500 mx-auto"></div>
          <p className="mt-4 text-gray-300">Loading store assignments...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2 mb-4">
          <Building2 className="h-6 w-6 text-purple-400" />
          Store Assignment Management
        </h2>
        <p className="text-gray-400">
          Manage which admins have access to which stores
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {activeStores.map((store) => {
          const storeAssignments = assignments.filter((a) => a.store_id === store.id);

          return (
            <div
              key={store.id}
              className="bg-gray-800/50 border border-gray-700 rounded-lg p-4 hover:border-purple-500/50 transition-colors"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-bold text-white">#{store.id} {store.name}</h3>
                  <p className="text-sm text-gray-400">{store.city}</p>
                </div>
                <Badge variant="outline" className="border-green-500 text-green-400">
                  {storeAssignments.length} admin{storeAssignments.length !== 1 ? "s" : ""}
                </Badge>
              </div>
              <div className="space-y-1">
                {storeAssignments.length === 0 ? (
                  <p className="text-xs text-gray-500">No admins assigned</p>
                ) : (
                  storeAssignments.map((assignment) => (
                    <div
                      key={assignment.id}
                      className="text-sm text-gray-300 flex items-center gap-2"
                    >
                      <div className="w-2 h-2 bg-purple-400 rounded-full"></div>
                      {(assignment.staff_profiles as any)?.full_name}
                      {assignment.is_primary_store && (
                        <Badge className="text-xs bg-purple-600">Primary</Badge>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
