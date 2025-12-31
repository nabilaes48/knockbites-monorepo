import { lazy, Suspense } from "react";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { CookieConsent } from "@/components/CookieConsent";
import ErrorBoundary, { PageLoadingSkeleton } from "@/components/system/ErrorBoundary";
import { AuthProvider } from "@/contexts/AuthContext";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import logger from "@/lib/logger";

// Lazy load all page components for code splitting
const Index = lazy(() => import("./pages/Index"));
const Menu = lazy(() => import("./pages/Menu"));
const Locations = lazy(() => import("./pages/Locations"));
const About = lazy(() => import("./pages/About"));
const Contact = lazy(() => import("./pages/Contact"));
const SignIn = lazy(() => import("./pages/SignIn"));
const SignUp = lazy(() => import("./pages/SignUp"));
const ForgotPassword = lazy(() => import("./pages/ForgotPassword"));
const Order = lazy(() => import("./pages/Order"));
const OrderTracking = lazy(() => import("./pages/OrderTracking"));
const Dashboard = lazy(() => import("./pages/Dashboard"));
const DashboardLogin = lazy(() => import("./pages/DashboardLogin"));
const DashboardForgotPassword = lazy(() => import("./pages/DashboardForgotPassword"));
const SuperAdminDashboard = lazy(() => import("./pages/SuperAdminDashboard"));
const RequestStaffAccess = lazy(() => import("./pages/RequestStaffAccess"));
const CustomerDashboard = lazy(() => import("./pages/CustomerDashboard"));
const PrivacyPolicy = lazy(() => import("./pages/Privacy"));
const TermsOfService = lazy(() => import("./pages/TermsOfService"));
const CookiePolicy = lazy(() => import("./pages/CookiePolicy"));
const FAQ = lazy(() => import("./pages/FAQ"));
const NotFound = lazy(() => import("./pages/NotFound"));
const SupabaseTest = lazy(() => import("./pages/SupabaseTest"));
const PremiumAnalyticsPage = lazy(() => import("./pages/PremiumAnalyticsPage"));
const SystemHealth = lazy(() => import("./pages/SystemHealth"));
const SetPassword = lazy(() => import("./pages/SetPassword"));

const queryClient = new QueryClient();

// Log app initialization
logger.info('App initializing', { version: import.meta.env.VITE_APP_VERSION });

const App = () => (
  <ErrorBoundary
    onError={(error, errorInfo) => {
      logger.error('Unhandled React error', error, {
        componentStack: errorInfo.componentStack,
      });
    }}
  >
    <AuthProvider>
      <QueryClientProvider client={queryClient}>
        <TooltipProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
            <Suspense fallback={<PageLoadingSkeleton />}>
              <Routes>
                <Route path="/" element={<Index />} />
                <Route path="/menu" element={<Menu />} />
                <Route path="/locations" element={<Locations />} />
                <Route path="/about" element={<About />} />
                <Route path="/contact" element={<Contact />} />
                <Route path="/signin" element={<SignIn />} />
                <Route path="/signup" element={<SignUp />} />
                <Route path="/forgot-password" element={<ForgotPassword />} />
                <Route path="/order" element={<Order />} />
                <Route path="/order/tracking/:orderId" element={<OrderTracking />} />
                <Route path="/dashboard" element={<ProtectedRoute requiredRole="staff"><Dashboard /></ProtectedRoute>} />
                <Route path="/dashboard/login" element={<DashboardLogin />} />
                <Route path="/dashboard/forgot-password" element={<DashboardForgotPassword />} />
                <Route path="/super-admin" element={<ProtectedRoute requiredRole="super_admin"><SuperAdminDashboard /></ProtectedRoute>} />
                <Route path="/request-staff-access" element={<RequestStaffAccess />} />
                <Route path="/customer/dashboard" element={<ProtectedRoute redirectTo="/signin"><CustomerDashboard /></ProtectedRoute>} />
                <Route path="/privacy-policy" element={<PrivacyPolicy />} />
                <Route path="/privacy" element={<PrivacyPolicy />} />
                <Route path="/terms-of-service" element={<TermsOfService />} />
                <Route path="/cookie-policy" element={<CookiePolicy />} />
                <Route path="/faq" element={<FAQ />} />
                <Route path="/supabase-test" element={<SupabaseTest />} />
                <Route path="/analytics" element={<ProtectedRoute requiredPermission="analytics"><PremiumAnalyticsPage /></ProtectedRoute>} />
                <Route path="/system-health" element={<ProtectedRoute requiredRole="super_admin"><SystemHealth /></ProtectedRoute>} />
                <Route path="/set-password" element={<SetPassword />} />
                <Route path="/reset-password" element={<SetPassword />} />
                {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
                <Route path="*" element={<NotFound />} />
              </Routes>
            </Suspense>
            <CookieConsent />
          </BrowserRouter>
        </TooltipProvider>
      </QueryClientProvider>
    </AuthProvider>
  </ErrorBoundary>
);

export default App;
