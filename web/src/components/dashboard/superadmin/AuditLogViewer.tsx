import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { FileText, AlertCircle } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

export function AuditLogViewer() {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      const { data, error } = await supabase
        .from("permission_changes")
        .select(`
          *,
          changed_by_profile:changed_by (full_name),
          target_profile:target_user_id (full_name)
        `)
        .order("changed_at", { ascending: false })
        .limit(50);

      if (error) throw error;
      setLogs(data || []);
    } catch (error) {
      console.error("Error fetching logs:", error);
    } finally {
      setLoading(false);
    }
  };

  const getActionBadge = (action: string) => {
    const badges: Record<string, { color: string; label: string }> = {
      created: { color: "bg-green-600", label: "Created" },
      updated: { color: "bg-blue-600", label: "Updated" },
      deleted: { color: "bg-red-600", label: "Deleted" },
      role_changed: { color: "bg-purple-600", label: "Role Changed" },
      permissions_changed: { color: "bg-orange-600", label: "Permissions Changed" },
    };

    const badge = badges[action] || { color: "bg-gray-600", label: action };

    return (
      <Badge className={badge.color}>
        {badge.label}
      </Badge>
    );
  };

  if (loading) {
    return (
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-8">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500 mx-auto"></div>
          <p className="mt-4 text-gray-300">Loading audit logs...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2">
          <FileText className="h-6 w-6 text-purple-400" />
          Audit Log Viewer
        </h2>
        <p className="text-gray-400 mt-1">
          Track all permission changes and user modifications ({logs.length} recent events)
        </p>
      </div>

      <div className="bg-gray-800/50 border border-gray-700 rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-gray-700 hover:bg-gray-700/50">
              <TableHead className="text-gray-300">Timestamp</TableHead>
              <TableHead className="text-gray-300">Action</TableHead>
              <TableHead className="text-gray-300">Target User</TableHead>
              <TableHead className="text-gray-300">Changed By</TableHead>
              <TableHead className="text-gray-300">Details</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {logs.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-gray-400">
                  <AlertCircle className="h-8 w-8 mx-auto mb-2 text-gray-500" />
                  No audit logs found
                </TableCell>
              </TableRow>
            ) : (
              logs.map((log) => (
                <TableRow key={log.id} className="border-gray-700 hover:bg-gray-700/30">
                  <TableCell className="text-gray-400 text-sm">
                    {new Date(log.changed_at).toLocaleString()}
                  </TableCell>
                  <TableCell>{getActionBadge(log.action)}</TableCell>
                  <TableCell className="text-gray-300">
                    {(log.target_profile as any)?.full_name || "Unknown"}
                  </TableCell>
                  <TableCell className="text-gray-300">
                    {(log.changed_by_profile as any)?.full_name || "System"}
                  </TableCell>
                  <TableCell className="text-gray-400 text-sm max-w-xs truncate">
                    {log.old_role && log.new_role && (
                      <span>{log.old_role} → {log.new_role}</span>
                    )}
                    {log.reason && <span> - {log.reason}</span>}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
