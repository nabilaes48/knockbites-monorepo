import { supabase } from '@/lib/supabase'

/**
 * Permission types for granular access control
 */
export type Permission =
  | 'orders.view'
  | 'orders.create'
  | 'orders.update'
  | 'orders.delete'
  | 'menu.view'
  | 'menu.create'
  | 'menu.update'
  | 'menu.delete'
  | 'analytics.view'
  | 'analytics.financial'
  | 'settings.view'
  | 'settings.update'
  | 'users.view'
  | 'users.create'
  | 'users.update'
  | 'users.delete'
  | 'stores.view'
  | 'stores.update'
  | 'inventory.view'
  | 'inventory.update'

/**
 * Role hierarchy levels
 */
export const ROLE_LEVELS = {
  customer: 0,
  staff: 1,
  manager: 2,
  admin: 3,
  super_admin: 4,
} as const

export type Role = keyof typeof ROLE_LEVELS

/**
 * Extended user profile with RBAC fields
 */
export interface ExtendedUserProfile {
  id: string
  role: Role
  full_name: string
  phone: string | null
  store_id: number | null
  assigned_stores: number[]
  permissions: string[]
  detailed_permissions: Record<string, any>
  is_active: boolean
  is_system_admin: boolean
  created_by: string | null
  can_hire_roles: Role[]
  avatar_url: string | null
  created_at: string
  updated_at: string
}

/**
 * Action types for permission checking
 */
export type Action = 'view' | 'create' | 'update' | 'delete' | 'manage'

/**
 * Check if a user can perform an action on a resource
 */
export function canUserPerformAction(
  user: ExtendedUserProfile | null,
  permission: Permission,
  targetStoreId?: number
): boolean {
  if (!user || !user.is_active) return false

  // Super admins can do everything
  if (user.is_system_admin || user.role === 'super_admin') return true

  // Check store access if store-specific permission
  if (targetStoreId !== undefined) {
    if (!hasStoreAccess(user, targetStoreId)) return false
  }

  // Check detailed permissions
  if (user.detailed_permissions && typeof user.detailed_permissions === 'object') {
    const [resource, action] = permission.split('.')

    if (user.detailed_permissions[resource]) {
      const resourcePerms = user.detailed_permissions[resource]

      // Check if they have the specific action
      if (resourcePerms[action] === true) return true

      // Check if they have 'manage' which grants all actions
      if (action !== 'manage' && resourcePerms.manage === true) return true
    }
  }

  // Fall back to legacy permissions array
  if (user.permissions && user.permissions.includes(permission)) return true

  // Role-based defaults
  return hasRolePermission(user.role, permission)
}

/**
 * Get role-based default permissions
 */
function hasRolePermission(role: Role, permission: Permission): boolean {
  const [resource, action] = permission.split('.')

  switch (role) {
    case 'super_admin':
      return true // Super admin has all permissions

    case 'admin':
      // Admins have full access except system-level settings
      return true

    case 'manager':
      // Managers have most permissions except user management
      if (resource === 'users' && action !== 'view') return false
      if (resource === 'stores' && action === 'update') return false
      if (permission === 'analytics.financial') return false
      return ['orders', 'menu', 'analytics', 'inventory', 'settings'].includes(resource)

    case 'staff':
      // Staff have limited permissions
      if (resource === 'orders') return ['view', 'update'].includes(action)
      if (resource === 'menu') return action === 'view'
      if (resource === 'inventory') return action === 'view'
      return false

    case 'customer':
      // Customers can only view menu and their own orders
      return false

    default:
      return false
  }
}

/**
 * Get all permissions for a user
 */
export async function getUserPermissions(userId: string): Promise<ExtendedUserProfile | null> {
  try {
    const { data, error } = await supabase
      .from('staff_profiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (error) throw error

    return {
      ...data,
      permissions: Array.isArray(data.permissions) ? data.permissions : [],
      assigned_stores: Array.isArray(data.assigned_stores) ? data.assigned_stores : [],
      detailed_permissions: data.detailed_permissions || {},
      can_hire_roles: Array.isArray(data.can_hire_roles) ? data.can_hire_roles : [],
    } as ExtendedUserProfile
  } catch (error) {
    console.error('Error fetching user permissions:', error)
    return null
  }
}

/**
 * Check if user has access to a specific store
 */
export function hasStoreAccess(user: ExtendedUserProfile | null, storeId: number): boolean {
  if (!user || !user.is_active) return false

  // Super admins have access to all stores
  if (user.is_system_admin || user.role === 'super_admin') return true

  // Check if store is in assigned_stores array
  if (user.assigned_stores && user.assigned_stores.includes(storeId)) return true

  // Fallback to legacy store_id field
  if (user.store_id === storeId) return true

  return false
}

/**
 * Check if a manager can manage a target user
 */
export async function canManageUser(
  managerId: string,
  targetUserId: string
): Promise<boolean> {
  try {
    const { data: canManage, error } = await supabase
      .rpc('can_user_manage_target', {
        manager_id: managerId,
        target_id: targetUserId,
      })

    if (error) throw error
    return canManage
  } catch (error) {
    console.error('Error checking user management permission:', error)
    return false
  }
}

/**
 * Get list of stores accessible to a user
 */
export async function getAccessibleStores(userId: string): Promise<number[]> {
  try {
    const { data, error } = await supabase
      .rpc('get_user_accessible_stores', {
        p_user_id: userId,
      })

    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Error fetching accessible stores:', error)
    return []
  }
}

/**
 * Get detailed store information for accessible stores
 */
export async function getAccessibleStoresDetails(userId: string) {
  try {
    const storeIds = await getAccessibleStores(userId)

    if (storeIds.length === 0) return []

    const { data, error } = await supabase
      .from('stores')
      .select('*')
      .in('id', storeIds)
      .eq('status', 'active')

    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Error fetching store details:', error)
    return []
  }
}

/**
 * Check if a user can promote/hire someone to a specific role
 */
export function canPromoteToRole(
  user: ExtendedUserProfile | null,
  targetRole: Role
): boolean {
  if (!user || !user.is_active) return false

  // Super admins can promote anyone
  if (user.is_system_admin || user.role === 'super_admin') return true

  // Check can_hire_roles array
  if (user.can_hire_roles && user.can_hire_roles.includes(targetRole)) return true

  // Default role-based hiring rules
  const userLevel = ROLE_LEVELS[user.role]
  const targetLevel = ROLE_LEVELS[targetRole]

  // Can only hire roles below your level
  if (userLevel <= targetLevel) return false

  // Specific rules by role
  switch (user.role) {
    case 'admin':
      // Admins can hire managers and staff
      return ['manager', 'staff'].includes(targetRole)

    case 'manager':
      // Managers can only hire staff
      return targetRole === 'staff'

    case 'staff':
    case 'customer':
      // Staff and customers cannot hire anyone
      return false

    default:
      return false
  }
}

/**
 * Check if user has hierarchy permission over another user
 */
export async function hasHierarchyPermission(
  userId: string,
  targetUserId: string
): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .rpc('user_has_hierarchy_permission', {
        p_user_id: userId,
        p_target_id: targetUserId,
      })

    if (error) throw error
    return data || false
  } catch (error) {
    console.error('Error checking hierarchy permission:', error)
    return false
  }
}

/**
 * Get user's role level
 */
export function getRoleLevel(role: Role): number {
  return ROLE_LEVELS[role] || 0
}

/**
 * Check if one role is higher than another
 */
export function isRoleHigher(role1: Role, role2: Role): boolean {
  return ROLE_LEVELS[role1] > ROLE_LEVELS[role2]
}

/**
 * Get list of roles a user can hire
 */
export function getHireableRoles(user: ExtendedUserProfile | null): Role[] {
  if (!user || !user.is_active) return []

  // Use explicit can_hire_roles if set
  if (user.can_hire_roles && user.can_hire_roles.length > 0) {
    return user.can_hire_roles
  }

  // Default rules
  switch (user.role) {
    case 'super_admin':
      return ['admin', 'manager', 'staff']
    case 'admin':
      return ['manager', 'staff']
    case 'manager':
      return ['staff']
    default:
      return []
  }
}

/**
 * Check if user can access financial data
 */
export function canAccessFinancials(user: ExtendedUserProfile | null): boolean {
  if (!user || !user.is_active) return false

  // Only super_admin and admin can access financial data
  return user.role === 'super_admin' || user.role === 'admin'
}

/**
 * Check if user can modify store settings
 */
export function canModifyStoreSettings(
  user: ExtendedUserProfile | null,
  storeId: number
): boolean {
  if (!user || !user.is_active) return false

  // Must have store access
  if (!hasStoreAccess(user, storeId)) return false

  // Must be admin or higher
  return ROLE_LEVELS[user.role] >= ROLE_LEVELS.admin
}

/**
 * Get user's primary store
 */
export async function getPrimaryStore(userId: string): Promise<number | null> {
  try {
    const { data, error } = await supabase
      .from('store_assignments')
      .select('store_id')
      .eq('user_id', userId)
      .eq('is_primary_store', true)
      .single()

    if (error) throw error
    return data?.store_id || null
  } catch (error) {
    console.error('Error fetching primary store:', error)
    return null
  }
}

/**
 * Validate permission string format
 */
export function isValidPermission(permission: string): permission is Permission {
  const validPermissions: Permission[] = [
    'orders.view', 'orders.create', 'orders.update', 'orders.delete',
    'menu.view', 'menu.create', 'menu.update', 'menu.delete',
    'analytics.view', 'analytics.financial',
    'settings.view', 'settings.update',
    'users.view', 'users.create', 'users.update', 'users.delete',
    'stores.view', 'stores.update',
    'inventory.view', 'inventory.update',
  ]

  return validPermissions.includes(permission as Permission)
}
