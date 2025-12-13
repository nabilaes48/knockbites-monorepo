import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import {
  canUserPerformAction,
  hasStoreAccess,
  canPromoteToRole,
  getAccessibleStores,
  canAccessFinancials,
  canModifyStoreSettings,
  getHireableRoles,
  getRoleLevel,
  type Permission,
  type Role,
  type ExtendedUserProfile,
} from '@/lib/permissions'

/**
 * React hook for permission checking
 */
export function usePermissions() {
  const { profile } = useAuth()
  const [accessibleStores, setAccessibleStores] = useState<number[]>([])
  const [loading, setLoading] = useState(true)

  // Fetch accessible stores on mount
  useEffect(() => {
    async function fetchStores() {
      if (!profile?.id) {
        setAccessibleStores([])
        setLoading(false)
        return
      }

      try {
        const stores = await getAccessibleStores(profile.id)
        setAccessibleStores(stores)
      } catch (error) {
        console.error('Error loading accessible stores:', error)
        setAccessibleStores([])
      } finally {
        setLoading(false)
      }
    }

    fetchStores()
  }, [profile?.id])

  /**
   * Check if user can perform an action
   */
  const can = useCallback(
    (permission: Permission, storeId?: number): boolean => {
      return canUserPerformAction(profile as ExtendedUserProfile, permission, storeId)
    },
    [profile]
  )

  /**
   * Check if user has access to a store
   */
  const hasAccess = useCallback(
    (storeId: number): boolean => {
      return hasStoreAccess(profile as ExtendedUserProfile, storeId)
    },
    [profile]
  )

  /**
   * Check if user can hire/promote to a role
   */
  const canHire = useCallback(
    (role: Role): boolean => {
      return canPromoteToRole(profile as ExtendedUserProfile, role)
    },
    [profile]
  )

  /**
   * Get list of roles user can hire
   */
  const hireableRoles = useCallback((): Role[] => {
    return getHireableRoles(profile as ExtendedUserProfile)
  }, [profile])

  /**
   * Check specific permissions
   */
  const canCreate = useCallback(
    (resource: string, storeId?: number): boolean => {
      return can(`${resource}.create` as Permission, storeId)
    },
    [can]
  )

  const canEdit = useCallback(
    (resource: string, storeId?: number): boolean => {
      return can(`${resource}.update` as Permission, storeId)
    },
    [can]
  )

  const canDelete = useCallback(
    (resource: string, storeId?: number): boolean => {
      return can(`${resource}.delete` as Permission, storeId)
    },
    [can]
  )

  const canView = useCallback(
    (resource: string, storeId?: number): boolean => {
      return can(`${resource}.view` as Permission, storeId)
    },
    [can]
  )

  /**
   * Check if user can access financial data
   */
  const canViewFinancials = useCallback((): boolean => {
    return canAccessFinancials(profile as ExtendedUserProfile)
  }, [profile])

  /**
   * Check if user can modify store settings
   */
  const canEditStoreSettings = useCallback(
    (storeId: number): boolean => {
      return canModifyStoreSettings(profile as ExtendedUserProfile, storeId)
    },
    [profile]
  )

  /**
   * Get user's role level
   */
  const roleLevel = profile ? getRoleLevel(profile.role as Role) : 0

  /**
   * Check if user is a specific role or higher
   */
  const isRoleOrHigher = useCallback(
    (role: Role): boolean => {
      if (!profile) return false
      return getRoleLevel(profile.role as Role) >= getRoleLevel(role)
    },
    [profile]
  )

  /**
   * Convenience flags for common role checks
   */
  const isSuperAdmin = profile?.role === 'super_admin'
  const isAdmin = profile?.role === 'admin' || isSuperAdmin
  const isManager = profile?.role === 'manager' || isAdmin
  const isStaff = profile?.role === 'staff' || isManager
  const isCustomer = profile?.role === 'customer'

  /**
   * Check if user has multiple store access
   */
  const hasMultipleStores = accessibleStores.length > 1

  /**
   * Get primary store ID
   */
  const primaryStoreId = profile?.store_id || null

  return {
    // Permission checks
    can,
    canCreate,
    canEdit,
    canDelete,
    canView,
    canHire,
    hasAccess,
    canViewFinancials,
    canEditStoreSettings,

    // Role information
    roleLevel,
    isRoleOrHigher,
    hireableRoles,

    // Role flags
    isSuperAdmin,
    isAdmin,
    isManager,
    isStaff,
    isCustomer,

    // Store access
    accessibleStores,
    hasMultipleStores,
    primaryStoreId,

    // Loading state
    loading,

    // Raw profile for advanced usage
    profile: profile as ExtendedUserProfile | null,
  }
}

/**
 * Hook for checking a single permission
 * Useful for conditional rendering
 */
export function usePermission(permission: Permission, storeId?: number): boolean {
  const { can } = usePermissions()
  return can(permission, storeId)
}

/**
 * Hook for checking store access
 */
export function useStoreAccess(storeId: number): boolean {
  const { hasAccess } = usePermissions()
  return hasAccess(storeId)
}

/**
 * Hook for role-based checks
 */
export function useRole() {
  const { profile } = useAuth()

  return {
    role: profile?.role as Role | null,
    isSuperAdmin: profile?.role === 'super_admin',
    isAdmin: profile?.role === 'admin',
    isManager: profile?.role === 'manager',
    isStaff: profile?.role === 'staff',
    isCustomer: profile?.role === 'customer',
    isSystemAdmin: (profile as any)?.is_system_admin || false,
  }
}

/**
 * Hook for getting accessible stores with details
 */
export function useAccessibleStores() {
  const { profile } = useAuth()
  const [stores, setStores] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchStores() {
      if (!profile?.id) {
        setStores([])
        setLoading(false)
        return
      }

      try {
        const { getAccessibleStoresDetails } = await import('@/lib/permissions')
        const storeData = await getAccessibleStoresDetails(profile.id)
        setStores(storeData)
      } catch (error) {
        console.error('Error loading store details:', error)
        setStores([])
      } finally {
        setLoading(false)
      }
    }

    fetchStores()
  }, [profile?.id])

  return { stores, loading }
}
