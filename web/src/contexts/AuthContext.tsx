import { createContext, useContext, useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

// Business user profile (staff, manager, admin, super_admin)
export interface UserProfile {
  id: string
  role: 'super_admin' | 'admin' | 'manager' | 'staff'
  full_name: string
  phone: string | null
  store_id: number | null
  assigned_stores: number[]
  permissions: string[]
  detailed_permissions: Record<string, any>
  is_active: boolean
  is_system_admin: boolean
  created_by: string | null
  can_hire_roles: string[]
  avatar_url: string | null
  created_at: string
  updated_at: string
}

// Customer profile (from customers table)
export interface CustomerProfile {
  id: string
  role: 'customer'
  full_name: string | null
  email: string | null
  phone: string | null
  avatar_url: string | null
  created_at: string
  updated_at: string
}

// Union type for both profile types
export type Profile = UserProfile | CustomerProfile

interface AuthContextType {
  user: User | null
  profile: Profile | null
  session: Session | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, fullName: string, phone: string) => Promise<void>
  signOut: () => Promise<void>
  isStaff: boolean
  isManager: boolean
  isAdmin: boolean
  isSuperAdmin: boolean
  isCustomer: boolean
  hasPermission: (permission: string) => boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) {
        fetchProfile(session.user.id)
      } else {
        setLoading(false)
      }
    })

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      setSession(session)
      setUser(session?.user ?? null)

      // Only fetch profile on actual sign-in, not on every auth event
      if (event === 'SIGNED_IN' && session?.user) {
        setLoading(true)
        fetchProfile(session.user.id)
      } else if (event === 'SIGNED_OUT') {
        setProfile(null)
        setLoading(false)
      }
      // Ignore other events like TOKEN_REFRESHED, INITIAL_SESSION (handled by getSession)
    })

    return () => subscription.unsubscribe()
  }, [])

  const fetchProfile = async (userId: string) => {
    try {
      // First, try to fetch from staff_profiles (business users) as it's more common for dashboard access
      // Using maybeSingle() instead of single() to avoid 406 errors when no rows found
      const { data: businessData, error: businessError } = await supabase
        .from('staff_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle()

      // If business user found, set business profile
      if (businessData && !businessError) {
        // Ensure all RBAC fields are properly initialized for business users
        const profileData: UserProfile = {
          ...businessData,
          permissions: Array.isArray(businessData.permissions) ? businessData.permissions : [],
          assigned_stores: Array.isArray(businessData.assigned_stores) ? businessData.assigned_stores : [],
          detailed_permissions: businessData.detailed_permissions || {},
          can_hire_roles: Array.isArray(businessData.can_hire_roles) ? businessData.can_hire_roles : [],
          is_system_admin: businessData.is_system_admin || false,
        }
        setProfile(profileData)
        setLoading(false)
        return
      }

      // If not a business user, try to fetch from customers table
      // Using maybeSingle() instead of single() to avoid 406 errors when no rows found
      const { data: customerData, error: customerError } = await supabase
        .from('customers')
        .select('*')
        .eq('id', userId)
        .maybeSingle()

      // If customer found, set customer profile
      if (customerData && !customerError) {
        const customerProfile: CustomerProfile = {
          ...customerData,
          role: 'customer',
        }
        setProfile(customerProfile)
        setLoading(false)
        return
      }

      // If neither profile exists, silently fall through
      // This is expected for users who exist in auth but not yet in profile tables

    } catch (error) {
      console.error('Error fetching profile:', error)
      // If profile doesn't exist in either table, it might still be creating
      // Don't treat this as a fatal error for new signups
    } finally {
      setLoading(false)
    }
  }

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (error) throw error
  }

  const signUp = async (email: string, password: string, fullName: string, phone: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          phone: phone,
        },
      },
    })
    if (error) throw error
  }

  const signOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  const hasPermission = (permission: string): boolean => {
    if (!profile) return false
    // Customers don't have permissions
    if (profile.role === 'customer') return false
    // Super admin and admin have all permissions
    if (profile.role === 'super_admin' || profile.role === 'admin') return true
    return (profile as UserProfile).permissions.includes(permission)
  }

  const value = {
    user,
    profile,
    session,
    loading,
    signIn,
    signUp,
    signOut,
    isStaff: profile?.role === 'staff',
    isManager: profile?.role === 'manager',
    isAdmin: profile?.role === 'admin',
    isSuperAdmin: profile?.role === 'super_admin',
    isCustomer: profile?.role === 'customer',
    hasPermission,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
