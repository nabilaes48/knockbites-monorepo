import React from 'react'
import { usePermissions, useRole } from '@/hooks/usePermissions'
import type { Permission, Role } from '@/lib/permissions'

interface PermissionGateProps {
  children: React.ReactNode
  /**
   * Required permission to show the children
   */
  requires?: Permission
  /**
   * Required role (will show if user has this role or higher)
   */
  requireRole?: Role
  /**
   * Required store access
   */
  requireStoreAccess?: number
  /**
   * Show if user can hire this role
   */
  canHireRole?: Role
  /**
   * Custom permission check function
   */
  customCheck?: () => boolean
  /**
   * Fallback content to show when permission denied
   */
  fallback?: React.ReactNode
  /**
   * Invert the logic (show when permission is NOT granted)
   */
  invert?: boolean
}

/**
 * Permission Gate Component
 * Conditionally renders children based on user permissions
 *
 * @example
 * // Show only to users with orders.create permission
 * <PermissionGate requires="orders.create">
 *   <Button>Create Order</Button>
 * </PermissionGate>
 *
 * @example
 * // Show only to admins and above
 * <PermissionGate requireRole="admin">
 *   <AdminPanel />
 * </PermissionGate>
 *
 * @example
 * // Show only to users with access to store 1
 * <PermissionGate requireStoreAccess={1}>
 *   <StoreDetails />
 * </PermissionGate>
 *
 * @example
 * // Show only to users who can hire managers
 * <PermissionGate canHireRole="manager">
 *   <Button>Hire Manager</Button>
 * </PermissionGate>
 *
 * @example
 * // Show fallback content when permission denied
 * <PermissionGate
 *   requires="analytics.financial"
 *   fallback={<div>You don't have access to financial data</div>}
 * >
 *   <FinancialReport />
 * </PermissionGate>
 */
export function PermissionGate({
  children,
  requires,
  requireRole,
  requireStoreAccess,
  canHireRole,
  customCheck,
  fallback = null,
  invert = false,
}: PermissionGateProps) {
  const { can, hasAccess, canHire, isRoleOrHigher } = usePermissions()

  let hasPermission = true

  // Check required permission
  if (requires) {
    hasPermission = hasPermission && can(requires)
  }

  // Check required role
  if (requireRole) {
    hasPermission = hasPermission && isRoleOrHigher(requireRole)
  }

  // Check store access
  if (requireStoreAccess !== undefined) {
    hasPermission = hasPermission && hasAccess(requireStoreAccess)
  }

  // Check hiring permission
  if (canHireRole) {
    hasPermission = hasPermission && canHire(canHireRole)
  }

  // Custom check function
  if (customCheck) {
    hasPermission = hasPermission && customCheck()
  }

  // Invert logic if needed
  if (invert) {
    hasPermission = !hasPermission
  }

  // Render children or fallback
  return <>{hasPermission ? children : fallback}</>
}

/**
 * Role Gate Component
 * Shorthand for role-based permission checking
 */
export function RoleGate({
  children,
  role,
  fallback = null,
}: {
  children: React.ReactNode
  role: Role
  fallback?: React.ReactNode
}) {
  return (
    <PermissionGate requireRole={role} fallback={fallback}>
      {children}
    </PermissionGate>
  )
}

/**
 * Store Gate Component
 * Shorthand for store access checking
 */
export function StoreGate({
  children,
  storeId,
  fallback = null,
}: {
  children: React.ReactNode
  storeId: number
  fallback?: React.ReactNode
}) {
  return (
    <PermissionGate requireStoreAccess={storeId} fallback={fallback}>
      {children}
    </PermissionGate>
  )
}

/**
 * Super Admin Only Gate
 */
export function SuperAdminGate({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const { isSuperAdmin } = useRole()
  return <>{isSuperAdmin ? children : fallback}</>
}

/**
 * Admin Only Gate (includes super admin)
 */
export function AdminGate({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  return (
    <PermissionGate requireRole="admin" fallback={fallback}>
      {children}
    </PermissionGate>
  )
}

/**
 * Manager Only Gate (includes admin and super admin)
 */
export function ManagerGate({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  return (
    <PermissionGate requireRole="manager" fallback={fallback}>
      {children}
    </PermissionGate>
  )
}

/**
 * Staff Gate (includes manager, admin, and super admin)
 */
export function StaffGate({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  return (
    <PermissionGate requireRole="staff" fallback={fallback}>
      {children}
    </PermissionGate>
  )
}

/**
 * Customer Only Gate
 */
export function CustomerGate({
  children,
  fallback = null,
}: {
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const { isCustomer } = useRole()
  return <>{isCustomer ? children : fallback}</>
}

/**
 * Multiple Permissions Gate (AND logic)
 * All permissions must be granted
 */
export function AllPermissionsGate({
  children,
  permissions,
  fallback = null,
}: {
  children: React.ReactNode
  permissions: Permission[]
  fallback?: React.ReactNode
}) {
  const { can } = usePermissions()

  const hasAllPermissions = permissions.every((perm) => can(perm))

  return <>{hasAllPermissions ? children : fallback}</>
}

/**
 * Multiple Permissions Gate (OR logic)
 * At least one permission must be granted
 */
export function AnyPermissionGate({
  children,
  permissions,
  fallback = null,
}: {
  children: React.ReactNode
  permissions: Permission[]
  fallback?: React.ReactNode
}) {
  const { can } = usePermissions()

  const hasAnyPermission = permissions.some((perm) => can(perm))

  return <>{hasAnyPermission ? children : fallback}</>
}
