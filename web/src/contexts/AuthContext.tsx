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

  // Track the current fetch to handle race conditions
  const fetchVersionRef = { current: 0 }

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

    // Track if we've already fetched profile for this user
    let currentUserId: string | null = null

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      console.log('Auth event:', event, 'User:', session?.user?.id)
      setSession(session)
      setUser(session?.user ?? null)

      if (session?.user) {
        // Only fetch profile if user changed or on sign-in
        if (session.user.id !== currentUserId || event === 'SIGNED_IN') {
          currentUserId = session.user.id
          setLoading(true)
          fetchProfile(session.user.id)
        }
      } else {
        currentUserId = null
        setProfile(null)
        setLoading(false)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  const fetchProfile = async (userId: string) => {
    // Increment version to track this fetch
    const thisVersion = ++fetchVersionRef.current
    console.log('fetchProfile starting, version:', thisVersion, 'userId:', userId)

    try {
      // First, try to fetch from staff_profiles (business users) as it's more common for dashboard access
      // Using maybeSingle() instead of single() to avoid 406 errors when no rows found
      const { data: businessData, error: businessError } = await supabase
        .from('staff_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle()

      // Check if this fetch is still current
      if (thisVersion !== fetchVersionRef.current) {
        console.log('Stale fetch (staff), ignoring. thisVersion:', thisVersion, 'current:', fetchVersionRef.current)
        return
      }

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
        console.log('Setting business profile, version:', thisVersion)
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

      console.log('Customer query result:', { customerData, customerError, userId })

      // Check if this fetch is still current
      if (thisVersion !== fetchVersionRef.current) {
        console.log('Stale fetch (customers), ignoring. thisVersion:', thisVersion, 'current:', fetchVersionRef.current)
        return
      }

      // If customer found, set customer profile
      if (customerData && !customerError) {
        const customerProfile: CustomerProfile = {
          ...customerData,
          role: 'customer',
        }
        console.log('Setting customer profile, version:', thisVersion)
        setProfile(customerProfile)
        setLoading(false)
        return
      }

      // If no profile exists, try to create a customer profile
      // This handles users who signed up before the trigger was in place
      console.log('No profile found, attempting to create customer profile for:', userId)

      // Get user email from auth
      const { data: { user: authUser } } = await supabase.auth.getUser()

      if (authUser && thisVersion === fetchVersionRef.current) {
        const { data: newCustomer, error: createError } = await supabase
          .from('customers')
          .insert({
            id: userId,
            email: authUser.email,
            full_name: authUser.user_metadata?.full_name || 'Customer',
            phone: authUser.user_metadata?.phone || null,
          })
          .select()
          .single()

        if (newCustomer && !createError) {
          console.log('Created customer profile:', newCustomer)
          const customerProfile: CustomerProfile = {
            ...newCustomer,
            role: 'customer',
          }
          setProfile(customerProfile)
          setLoading(false)
          return
        } else {
          console.log('Failed to create customer profile:', createError)
        }
      }

      // If still no profile, set loading false
      console.log('No profile found and could not create one, version:', thisVersion)
      setLoading(false)

    } catch (error) {
      console.error('Error fetching profile:', error)
      // Only set loading false if this is still the current fetch
      if (thisVersion === fetchVersionRef.current) {
        setLoading(false)
      }
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
