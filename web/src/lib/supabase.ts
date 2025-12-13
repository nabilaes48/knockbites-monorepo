import { createClient } from '@supabase/supabase-js'
import { getVersionHeaders, APP_VERSION, APP_NAME, CURRENT_API_VERSION } from './versioning'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing Supabase environment variables. Please check your .env.local file.'
  )
}

// Version headers for all requests
const versionHeaders = getVersionHeaders()

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: window.localStorage,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
  global: {
    headers: versionHeaders,
  },
})

// Export version info for debugging
export const clientVersionInfo = {
  appVersion: APP_VERSION,
  appName: APP_NAME,
  apiVersion: CURRENT_API_VERSION,
}

// Helper function to handle Supabase errors
export function handleSupabaseError(error: any) {
  if (error?.message) {
    console.error('Supabase error:', error.message)
    return error.message
  }
  return 'An unexpected error occurred'
}
