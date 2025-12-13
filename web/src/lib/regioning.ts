/**
 * Multi-Region Utilities for KnockBites
 *
 * Provides region-aware routing, read replica selection,
 * and cross-region coordination for global deployments.
 */

import { supabase } from './supabase';

// ============================================================================
// Region Configuration
// ============================================================================

export type Region = 'us-east-1' | 'us-west-2' | 'eu-west-1' | 'ap-southeast-1';

export interface RegionConfig {
  id: Region;
  name: string;
  supabaseUrl: string;
  isPrimary: boolean;
  readReplica: boolean;
  latencyMs?: number;
}

// Region endpoints - in production these would be separate Supabase projects
const REGION_CONFIGS: Record<Region, RegionConfig> = {
  'us-east-1': {
    id: 'us-east-1',
    name: 'US East (N. Virginia)',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL || '',
    isPrimary: true,
    readReplica: false,
  },
  'us-west-2': {
    id: 'us-west-2',
    name: 'US West (Oregon)',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_US_WEST || import.meta.env.VITE_SUPABASE_URL || '',
    isPrimary: false,
    readReplica: true,
  },
  'eu-west-1': {
    id: 'eu-west-1',
    name: 'EU (Ireland)',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_EU || import.meta.env.VITE_SUPABASE_URL || '',
    isPrimary: false,
    readReplica: true,
  },
  'ap-southeast-1': {
    id: 'ap-southeast-1',
    name: 'Asia Pacific (Singapore)',
    supabaseUrl: import.meta.env.VITE_SUPABASE_URL_AP || import.meta.env.VITE_SUPABASE_URL || '',
    isPrimary: false,
    readReplica: true,
  },
};

// Default/current region
const DEFAULT_REGION: Region = 'us-east-1';

// ============================================================================
// Region Detection
// ============================================================================

/**
 * Detect user's closest region based on timezone or IP geolocation
 */
export function detectUserRegion(): Region {
  // Use timezone as a proxy for region detection
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  if (timezone.startsWith('America/New_York') || timezone.startsWith('America/Toronto') || timezone.startsWith('America/Chicago')) {
    return 'us-east-1';
  }

  if (timezone.startsWith('America/Los_Angeles') || timezone.startsWith('America/Denver') || timezone.startsWith('America/Phoenix')) {
    return 'us-west-2';
  }

  if (timezone.startsWith('Europe/') || timezone.startsWith('Africa/')) {
    return 'eu-west-1';
  }

  if (timezone.startsWith('Asia/') || timezone.startsWith('Australia/') || timezone.startsWith('Pacific/')) {
    return 'ap-southeast-1';
  }

  // Default to US East for KnockBites (NY-based business)
  return DEFAULT_REGION;
}

/**
 * Get user's region from local storage or detect it
 */
export function getUserRegion(): Region {
  const stored = localStorage.getItem('knockbites_region');
  if (stored && isValidRegion(stored)) {
    return stored as Region;
  }
  return detectUserRegion();
}

/**
 * Set user's preferred region
 */
export function setUserRegion(region: Region): void {
  localStorage.setItem('knockbites_region', region);
}

/**
 * Validate region string
 */
export function isValidRegion(region: string): region is Region {
  return region in REGION_CONFIGS;
}

// ============================================================================
// Region Routing
// ============================================================================

/**
 * Get configuration for a specific region
 */
export function getRegionConfig(region: Region): RegionConfig {
  return REGION_CONFIGS[region];
}

/**
 * Get all available regions
 */
export function getAllRegions(): RegionConfig[] {
  return Object.values(REGION_CONFIGS);
}

/**
 * Get the primary (write) region
 */
export function getPrimaryRegion(): RegionConfig {
  return Object.values(REGION_CONFIGS).find(r => r.isPrimary) || REGION_CONFIGS[DEFAULT_REGION];
}

/**
 * Get all read replica regions
 */
export function getReadReplicas(): RegionConfig[] {
  return Object.values(REGION_CONFIGS).filter(r => r.readReplica);
}

/**
 * Determine optimal region for a request based on operation type
 */
export function getOptimalRegion(operationType: 'read' | 'write'): Region {
  if (operationType === 'write') {
    // Writes always go to primary
    return getPrimaryRegion().id;
  }

  // For reads, use closest replica
  const userRegion = getUserRegion();
  const regionConfig = REGION_CONFIGS[userRegion];

  // If user's region has a replica, use it; otherwise use primary
  if (regionConfig.readReplica || regionConfig.isPrimary) {
    return userRegion;
  }

  return DEFAULT_REGION;
}

// ============================================================================
// Latency Measurement
// ============================================================================

interface LatencyResult {
  region: Region;
  latencyMs: number;
  available: boolean;
}

/**
 * Measure latency to a specific region
 */
export async function measureRegionLatency(region: Region): Promise<LatencyResult> {
  const config = REGION_CONFIGS[region];
  const start = performance.now();

  try {
    // Simple health check ping
    const response = await fetch(`${config.supabaseUrl}/rest/v1/`, {
      method: 'HEAD',
      headers: {
        'apikey': import.meta.env.VITE_SUPABASE_ANON_KEY || '',
      },
    });

    const latencyMs = Math.round(performance.now() - start);

    return {
      region,
      latencyMs,
      available: response.ok,
    };
  } catch {
    return {
      region,
      latencyMs: -1,
      available: false,
    };
  }
}

/**
 * Measure latency to all regions and find the fastest
 */
export async function findFastestRegion(): Promise<LatencyResult[]> {
  const results = await Promise.all(
    Object.keys(REGION_CONFIGS).map(region => measureRegionLatency(region as Region))
  );

  // Sort by latency (unavailable regions last)
  return results.sort((a, b) => {
    if (!a.available) return 1;
    if (!b.available) return -1;
    return a.latencyMs - b.latencyMs;
  });
}

// ============================================================================
// Region Health & Failover
// ============================================================================

interface RegionHealth {
  region: Region;
  healthy: boolean;
  lastChecked: Date;
  consecutiveFailures: number;
}

const regionHealthCache: Map<Region, RegionHealth> = new Map();

/**
 * Check health of a specific region
 */
export async function checkRegionHealth(region: Region): Promise<RegionHealth> {
  const config = REGION_CONFIGS[region];
  const cached = regionHealthCache.get(region);

  try {
    const response = await fetch(`${config.supabaseUrl}/rest/v1/stores?select=id&limit=1`, {
      headers: {
        'apikey': import.meta.env.VITE_SUPABASE_ANON_KEY || '',
      },
    });

    const health: RegionHealth = {
      region,
      healthy: response.ok,
      lastChecked: new Date(),
      consecutiveFailures: response.ok ? 0 : (cached?.consecutiveFailures || 0) + 1,
    };

    regionHealthCache.set(region, health);
    return health;
  } catch {
    const health: RegionHealth = {
      region,
      healthy: false,
      lastChecked: new Date(),
      consecutiveFailures: (cached?.consecutiveFailures || 0) + 1,
    };

    regionHealthCache.set(region, health);
    return health;
  }
}

/**
 * Get failover region when primary is unhealthy
 */
export function getFailoverRegion(currentRegion: Region): Region | null {
  const allRegions = getAllRegions();
  const healthy = allRegions.find(r => {
    if (r.id === currentRegion) return false;
    const health = regionHealthCache.get(r.id);
    return health?.healthy !== false;
  });

  return healthy?.id || null;
}

// ============================================================================
// Cross-Region Coordination
// ============================================================================

export interface RegionSyncStatus {
  primaryRegion: Region;
  replicaLag: Record<Region, number>; // Lag in milliseconds
  lastSyncAt: Date;
}

/**
 * Get current replication lag status from database
 */
export async function getRegionSyncStatus(): Promise<RegionSyncStatus | null> {
  try {
    const { data, error } = await supabase.rpc('get_region_sync_status');

    if (error || !data) {
      return null;
    }

    return data as RegionSyncStatus;
  } catch {
    return null;
  }
}

/**
 * Register this client's region with the backend for telemetry
 */
export async function registerClientRegion(): Promise<void> {
  const region = getUserRegion();

  try {
    await supabase.rpc('register_client_region', {
      p_region: region,
      p_client_id: getClientId(),
    });
  } catch {
    // Silent failure - telemetry is non-critical
  }
}

/**
 * Get or generate a persistent client ID
 */
function getClientId(): string {
  let clientId = localStorage.getItem('knockbites_client_id');
  if (!clientId) {
    clientId = `web_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
    localStorage.setItem('knockbites_client_id', clientId);
  }
  return clientId;
}

// ============================================================================
// Region Headers for API Calls
// ============================================================================

/**
 * Get region-specific headers to include with API requests
 */
export function getRegionHeaders(): Record<string, string> {
  return {
    'X-Client-Region': getUserRegion(),
    'X-Client-Id': getClientId(),
  };
}

/**
 * Get full API gateway URL for the current region
 */
export function getApiGatewayUrl(): string {
  const region = getUserRegion();
  const config = REGION_CONFIGS[region];

  // All regions use the same gateway which routes internally
  return `${config.supabaseUrl}/functions/v1/api-gateway`;
}

// ============================================================================
// Initialization
// ============================================================================

let initialized = false;

/**
 * Initialize regioning system
 */
export async function initRegioning(): Promise<{
  region: Region;
  latency: number;
  healthy: boolean;
}> {
  if (initialized) {
    const region = getUserRegion();
    const health = regionHealthCache.get(region);
    return {
      region,
      latency: -1,
      healthy: health?.healthy ?? true,
    };
  }

  const region = getUserRegion();

  // Measure latency and check health in parallel
  const [latencyResult, healthResult] = await Promise.all([
    measureRegionLatency(region),
    checkRegionHealth(region),
  ]);

  // Register client region for telemetry
  registerClientRegion().catch(() => {});

  initialized = true;

  return {
    region,
    latency: latencyResult.latencyMs,
    healthy: healthResult.healthy,
  };
}

// ============================================================================
// Exports
// ============================================================================

export const regionUtils = {
  detect: detectUserRegion,
  get: getUserRegion,
  set: setUserRegion,
  getConfig: getRegionConfig,
  getAll: getAllRegions,
  getPrimary: getPrimaryRegion,
  getReplicas: getReadReplicas,
  getOptimal: getOptimalRegion,
  measureLatency: measureRegionLatency,
  findFastest: findFastestRegion,
  checkHealth: checkRegionHealth,
  getFailover: getFailoverRegion,
  getSyncStatus: getRegionSyncStatus,
  getHeaders: getRegionHeaders,
  getGatewayUrl: getApiGatewayUrl,
  init: initRegioning,
};

export default regionUtils;
