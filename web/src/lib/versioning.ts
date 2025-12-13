/**
 * App Versioning & Compatibility Layer
 *
 * Ensures backward compatibility across:
 * - Business iOS app
 * - Customer iOS app
 * - Web Dashboard
 *
 * All clients must send version headers for API negotiation.
 */

// Current web app version (from package.json or env)
export const APP_VERSION = import.meta.env.VITE_APP_VERSION || '1.0.0';
export const APP_NAME = 'web';

// Supported API versions
export type ApiVersion = 'v1' | 'v2' | 'v3';
export const CURRENT_API_VERSION: ApiVersion = 'v3';
export const SUPPORTED_API_VERSIONS: ApiVersion[] = ['v1', 'v2', 'v3'];

// Version requirements for each API version
export const API_VERSION_REQUIREMENTS: Record<ApiVersion, string> = {
  v1: '1.0.0',
  v2: '1.2.0',
  v3: '1.4.0',
};

// App identifiers
export type AppName = 'web' | 'customer' | 'business';

/**
 * Version headers to include with all Supabase requests
 */
export function getVersionHeaders(): Record<string, string> {
  return {
    'X-App-Version': APP_VERSION,
    'X-App-Name': APP_NAME,
    'X-Api-Version': CURRENT_API_VERSION,
  };
}

/**
 * Parse semantic version string into components
 */
export function parseVersion(version: string): {
  major: number;
  minor: number;
  patch: number;
} {
  const [major = 0, minor = 0, patch = 0] = version
    .replace(/^v/, '')
    .split('.')
    .map(Number);

  return { major, minor, patch };
}

/**
 * Compare two semantic versions
 * Returns: -1 if a < b, 0 if a == b, 1 if a > b
 */
export function compareVersions(a: string, b: string): number {
  const vA = parseVersion(a);
  const vB = parseVersion(b);

  if (vA.major !== vB.major) return vA.major > vB.major ? 1 : -1;
  if (vA.minor !== vB.minor) return vA.minor > vB.minor ? 1 : -1;
  if (vA.patch !== vB.patch) return vA.patch > vB.patch ? 1 : -1;

  return 0;
}

/**
 * Check if version meets minimum requirement
 */
export function meetsMinVersion(current: string, minimum: string): boolean {
  return compareVersions(current, minimum) >= 0;
}

/**
 * Feature flags interface
 */
export interface FeatureFlag {
  feature: string;
  enabled: boolean;
  minVersion?: string;
}

/**
 * Cached feature flags
 */
let cachedFeatureFlags: FeatureFlag[] | null = null;
let featureFlagsFetchedAt: number = 0;
const FEATURE_FLAGS_CACHE_TTL = 5 * 60 * 1000; // 5 minutes

/**
 * Fetch feature flags for this app
 */
export async function fetchFeatureFlags(
  supabase: { rpc: (name: string, params: Record<string, unknown>) => Promise<{ data: FeatureFlag[] | null; error: unknown }> }
): Promise<FeatureFlag[]> {
  const now = Date.now();

  // Return cached if still valid
  if (cachedFeatureFlags && now - featureFlagsFetchedAt < FEATURE_FLAGS_CACHE_TTL) {
    return cachedFeatureFlags;
  }

  try {
    const { data, error } = await supabase.rpc('get_feature_flags', {
      p_app_name: APP_NAME,
      p_app_version: APP_VERSION,
    });

    if (error) {
      console.warn('[Versioning] Failed to fetch feature flags:', error);
      return cachedFeatureFlags || [];
    }

    cachedFeatureFlags = data || [];
    featureFlagsFetchedAt = now;

    return cachedFeatureFlags;
  } catch (err) {
    console.warn('[Versioning] Error fetching feature flags:', err);
    return cachedFeatureFlags || [];
  }
}

/**
 * Check if a feature is enabled
 */
export function isFeatureEnabled(
  featureFlags: FeatureFlag[],
  featureName: string
): boolean {
  const flag = featureFlags.find((f) => f.feature === featureName);

  if (!flag) {
    return false; // Feature not found = disabled
  }

  if (!flag.enabled) {
    return false;
  }

  // Check version requirement if specified
  if (flag.minVersion && !meetsMinVersion(APP_VERSION, flag.minVersion)) {
    return false;
  }

  return true;
}

/**
 * Schema compatibility check result
 */
export interface CompatibilityResult {
  compatible: boolean;
  requiredVersion?: string;
  breakingChanges?: string[];
}

/**
 * Check if client is compatible with current schema
 */
export async function checkSchemaCompatibility(
  supabase: { rpc: (name: string, params: Record<string, unknown>) => Promise<{ data: boolean | null; error: unknown }> }
): Promise<CompatibilityResult> {
  try {
    const { data, error } = await supabase.rpc('can_client_use_schema', {
      p_app_version: APP_VERSION,
    });

    if (error) {
      console.warn('[Versioning] Schema compatibility check failed:', error);
      return { compatible: true }; // Assume compatible on error
    }

    return {
      compatible: data === true,
    };
  } catch (err) {
    console.warn('[Versioning] Error checking schema compatibility:', err);
    return { compatible: true };
  }
}

/**
 * API dispatch options
 */
export interface DispatchOptions {
  version?: ApiVersion;
  timeout?: number;
}

/**
 * Call versioned RPC through the dispatch system
 */
export async function dispatchRpc<T>(
  supabase: { rpc: (name: string, params: Record<string, unknown>) => Promise<{ data: T | null; error: unknown }> },
  rpcName: string,
  payload: Record<string, unknown>,
  options: DispatchOptions = {}
): Promise<{ data: T | null; error: unknown }> {
  const version = options.version || CURRENT_API_VERSION;

  // Determine dispatch function based on version
  let dispatchFunction: string;
  switch (version) {
    case 'v1':
      dispatchFunction = 'rpc_v1_dispatch';
      break;
    case 'v2':
      dispatchFunction = 'rpc_v2_dispatch';
      break;
    case 'v3':
      dispatchFunction = 'rpc_v3_dispatch';
      break;
    default:
      dispatchFunction = 'rpc_v3_dispatch';
  }

  return supabase.rpc(dispatchFunction, {
    p_name: rpcName,
    p_payload: payload,
  });
}

/**
 * Use the universal router which auto-selects version
 */
export async function routeApiCall<T>(
  supabase: { rpc: (name: string, params: Record<string, unknown>) => Promise<{ data: T | null; error: unknown }> },
  rpcName: string,
  payload: Record<string, unknown>,
  requestedVersion?: ApiVersion
): Promise<{ data: T | null; error: unknown }> {
  return supabase.rpc('route_api_call', {
    p_name: rpcName,
    p_payload: payload,
    p_requested_version: requestedVersion || null,
  });
}

/**
 * Get best API version for current app
 */
export function getBestApiVersion(): ApiVersion {
  // Check which version this app supports
  for (const version of ['v3', 'v2', 'v1'] as ApiVersion[]) {
    const required = API_VERSION_REQUIREMENTS[version];
    if (meetsMinVersion(APP_VERSION, required)) {
      return version;
    }
  }
  return 'v1';
}

/**
 * Check if specific API version is available for this app
 */
export function canUseApiVersion(version: ApiVersion): boolean {
  const required = API_VERSION_REQUIREMENTS[version];
  return meetsMinVersion(APP_VERSION, required);
}

/**
 * Version info for debugging
 */
export function getVersionInfo(): {
  appVersion: string;
  appName: string;
  apiVersion: string;
  supportedVersions: string[];
} {
  return {
    appVersion: APP_VERSION,
    appName: APP_NAME,
    apiVersion: CURRENT_API_VERSION,
    supportedVersions: SUPPORTED_API_VERSIONS,
  };
}

/**
 * Initialize versioning (call at app startup)
 */
export async function initVersioning(
  supabase: { rpc: (name: string, params: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> }
): Promise<{
  compatible: boolean;
  features: FeatureFlag[];
}> {
  // Check compatibility
  const compatibility = await checkSchemaCompatibility(supabase);

  if (!compatibility.compatible) {
    console.error(
      '[Versioning] App version incompatible with schema. Required:',
      compatibility.requiredVersion
    );
  }

  // Fetch feature flags
  const features = await fetchFeatureFlags(supabase);

  return {
    compatible: compatibility.compatible,
    features,
  };
}

// Export default for convenience
export default {
  APP_VERSION,
  APP_NAME,
  CURRENT_API_VERSION,
  API_VERSION_REQUIREMENTS,
  getVersionHeaders,
  parseVersion,
  compareVersions,
  meetsMinVersion,
  fetchFeatureFlags,
  isFeatureEnabled,
  checkSchemaCompatibility,
  dispatchRpc,
  routeApiCall,
  getBestApiVersion,
  canUseApiVersion,
  getVersionInfo,
  initVersioning,
};
