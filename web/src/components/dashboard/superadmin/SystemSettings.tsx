import { Settings } from "lucide-react";

export function SystemSettings() {
  return (
    <div className="space-y-4">
      <div className="bg-gray-800/50 border border-gray-700 rounded-lg p-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2 mb-4">
          <Settings className="h-6 w-6 text-purple-400" />
          System Settings
        </h2>
        <p className="text-gray-400 mb-6">
          Configure system-wide settings and feature flags
        </p>

        <div className="space-y-4">
          <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600">
            <h3 className="text-white font-semibold mb-2">Coming Soon</h3>
            <p className="text-gray-400 text-sm">
              System settings panel will include:
            </p>
            <ul className="list-disc list-inside text-gray-400 text-sm mt-2 space-y-1">
              <li>Feature flags management</li>
              <li>Email notification settings</li>
              <li>System-wide configurations</li>
              <li>Security settings</li>
              <li>API key management</li>
              <li>Backup & restore options</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
