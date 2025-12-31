import { Navigate } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { PageLoadingSkeleton } from '@/components/PageLoadingSkeleton'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredRole?: 'staff' | 'manager' | 'admin' | 'super_admin'
  requiredPermission?: string
  redirectTo?: string
}

export function ProtectedRoute({
  children,
  requiredRole,
  requiredPermission,
  redirectTo = '/dashboard/login',
}: ProtectedRouteProps) {
  const { user, profile, loading, hasPermission } = useAuth()

  // Show loading state while checking authentication
  if (loading) {
    return <PageLoadingSkeleton />
  }

  // Redirect to login if not authenticated
  if (!user) {
    return <Navigate to={redirectTo} replace />
  }

  // Wait for profile to load
  if (!profile) {
    return <PageLoadingSkeleton />
  }

  // Check if user has required role
  if (requiredRole) {
    const roleHierarchy = {
      staff: 1,
      manager: 2,
      admin: 3,
      super_admin: 4,
    }

    const userRoleLevel = roleHierarchy[profile.role as keyof typeof roleHierarchy] || 0
    const requiredRoleLevel = roleHierarchy[requiredRole] || 0

    // User must have equal or higher role level
    // Super admin always has access
    if (userRoleLevel < requiredRoleLevel && profile.role !== 'super_admin') {
      return <Navigate to="/dashboard" replace />
    }
  }

  // Check if user has required permission
  if (requiredPermission && !hasPermission(requiredPermission)) {
    return <Navigate to="/dashboard" replace />
  }

  // Check if user account is active (only for business users, not customers)
  // Customers don't have is_active field, so we check if it exists and is false
  if (profile.role !== 'customer' && 'is_active' in profile && !profile.is_active) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
          <h2 className="text-2xl font-bold text-red-600 mb-4">Account Inactive</h2>
          <p className="text-gray-600">
            Your account has been deactivated. Please contact your administrator for assistance.
          </p>
        </div>
      </div>
    )
  }

  return <>{children}</>
}
