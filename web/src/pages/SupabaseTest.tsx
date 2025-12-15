import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Button } from "@/components/ui/button";

export default function SupabaseTest() {
  const [status, setStatus] = useState("Testing...");
  const [stores, setStores] = useState<any[]>([]);
  const [error, setError] = useState("");
  const [authStatus, setAuthStatus] = useState("");
  const [authError, setAuthError] = useState("");
  const [profileData, setProfileData] = useState<any>(null);

  useEffect(() => {
    const testConnection = async () => {
      try {
        // Test 1: Check if Supabase client is initialized
        setStatus("✓ Supabase client initialized");

        // Test 2: Try to fetch stores
        const { data, error } = await supabase
          .from("stores")
          .select("id, name")
          .limit(5);

        if (error) {
          setError("Database Error: " + error.message);
          setStatus("✗ Failed to connect to database");
        } else {
          setStores(data || []);
          setStatus("✓ Successfully connected to Supabase!");
        }
      } catch (err: any) {
        setError("Connection Error: " + err.message);
        setStatus("✗ Failed to initialize");
      }
    };

    testConnection();
  }, []);

  const testAuth = async () => {
    setAuthStatus("Testing authentication...");
    setAuthError("");
    setProfileData(null);

    try {
      // Try to sign in
      const { data: authData, error: signInError } = await supabase.auth.signInWithPassword({
        email: 'admin@knockbites.com',
        password: 'admin123',
      });

      if (signInError) {
        setAuthError("Sign-in Error: " + signInError.message);
        setAuthStatus("✗ Sign-in failed");
        return;
      }

      setAuthStatus("✓ Sign-in successful! User ID: " + authData.user?.id);

      // Try to fetch profile
      const { data: profileData, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', authData.user?.id)
        .single();

      if (profileError) {
        setAuthError("Profile Fetch Error: " + profileError.message + " | Code: " + profileError.code + " | Details: " + profileError.details + " | Hint: " + profileError.hint);
        setAuthStatus("✗ Profile fetch failed");
      } else {
        setProfileData(profileData);
        setAuthStatus("✓ Profile fetched successfully!");
      }
    } catch (err: any) {
      setAuthError("Unexpected Error: " + err.message);
      setAuthStatus("✗ Test failed");
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Supabase Connection Test</h1>

        <div className="bg-white p-6 rounded-lg shadow-md space-y-4">
          <div>
            <h2 className="font-semibold text-lg mb-2">Status:</h2>
            <p className="text-lg">{status}</p>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 p-4 rounded">
              <h3 className="font-semibold text-red-800 mb-2">Error:</h3>
              <p className="text-red-600 text-sm font-mono">{error}</p>
            </div>
          )}

          {stores.length > 0 && (
            <div className="bg-green-50 border border-green-200 p-4 rounded">
              <h3 className="font-semibold text-green-800 mb-2">
                ✓ Found {stores.length} stores:
              </h3>
              <ul className="space-y-1">
                {stores.map((store) => (
                  <li key={store.id} className="text-sm text-green-700">
                    {store.id}. {store.name}
                  </li>
                ))}
              </ul>
            </div>
          )}

          <div className="border-t pt-4 mt-4">
            <h3 className="font-semibold mb-2">Environment Check:</h3>
            <div className="space-y-1 text-sm font-mono">
              <p>
                SUPABASE_URL:{" "}
                {import.meta.env.VITE_SUPABASE_URL ? "✓ Set" : "✗ Missing"}
              </p>
              <p>
                SUPABASE_KEY:{" "}
                {import.meta.env.VITE_SUPABASE_ANON_KEY ? "✓ Set" : "✗ Missing"}
              </p>
            </div>
          </div>
        </div>

        {/* Auth Test Section */}
        <div className="bg-white p-6 rounded-lg shadow-md space-y-4 mt-6">
          <div>
            <h2 className="font-semibold text-lg mb-4">Authentication Test</h2>
            <Button onClick={testAuth} className="w-full">
              Test Login with admin@knockbites.com
            </Button>
          </div>

          {authStatus && (
            <div className="mt-4">
              <h3 className="font-semibold mb-2">Auth Status:</h3>
              <p className="text-sm">{authStatus}</p>
            </div>
          )}

          {authError && (
            <div className="bg-red-50 border border-red-200 p-4 rounded">
              <h3 className="font-semibold text-red-800 mb-2">Auth Error:</h3>
              <p className="text-red-600 text-xs font-mono break-words">{authError}</p>
            </div>
          )}

          {profileData && (
            <div className="bg-green-50 border border-green-200 p-4 rounded">
              <h3 className="font-semibold text-green-800 mb-2">
                ✓ Profile Data:
              </h3>
              <pre className="text-xs text-green-700 overflow-auto">
                {JSON.stringify(profileData, null, 2)}
              </pre>
            </div>
          )}
        </div>

        <div className="mt-6">
          <a
            href="/dashboard/login"
            className="text-blue-600 hover:underline"
          >
            ← Back to Login
          </a>
        </div>
      </div>
    </div>
  );
}
