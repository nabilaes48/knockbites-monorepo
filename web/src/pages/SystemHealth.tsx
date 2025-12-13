/**
 * System Health Dashboard
 *
 * Super admin-only page for monitoring system health:
 * - Recent errors
 * - API latency metrics
 * - Alert history
 * - Order health
 * - Deployment history
 */

import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/lib/supabase';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  Activity,
  Server,
  RefreshCw,
  AlertCircle,
  Zap,
  Database,
  Rocket,
} from 'lucide-react';

interface ErrorEntry {
  id: number;
  created_at: string;
  session_id: string;
  error_type: string;
  message: string;
  url: string;
  event_data: Record<string, unknown>;
}

interface LatencyStats {
  endpoint: string;
  avg_latency_ms: number;
  p50_latency_ms: number;
  p95_latency_ms: number;
  p99_latency_ms: number;
  request_count: number;
  error_count: number;
}

interface MetricsSummary {
  event_type: string;
  event_count: number;
  unique_sessions: number;
  unique_users: number;
  first_event: string;
  last_event: string;
}

interface AlertEntry {
  id: number;
  triggered_at: string;
  status: string;
  severity: string;
  message: string;
  metric_value: number;
  threshold_value: number;
}

interface DeploymentEntry {
  id: number;
  deployment_id: string;
  environment: string;
  version: string;
  commit_sha: string;
  deployed_at: string;
  status: string;
  smoke_test_passed: boolean;
}

interface OrderHealth {
  total_orders: number;
  completed_orders: number;
  cancelled_orders: number;
  active_orders: number;
  stuck_preparing: number;
  stuck_ready: number;
  completion_rate: number;
  avg_completion_minutes: number;
  avg_order_value: number;
}

export default function SystemHealth() {
  const { isSuperAdmin, loading: authLoading } = useAuth();
  const navigate = useNavigate();

  const [errors, setErrors] = useState<ErrorEntry[]>([]);
  const [latencyStats, setLatencyStats] = useState<LatencyStats[]>([]);
  const [metricsSummary, setMetricsSummary] = useState<MetricsSummary[]>([]);
  const [alerts, setAlerts] = useState<AlertEntry[]>([]);
  const [deployments, setDeployments] = useState<DeploymentEntry[]>([]);
  const [orderHealth, setOrderHealth] = useState<OrderHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Redirect if not super admin
  useEffect(() => {
    if (!authLoading && !isSuperAdmin) {
      navigate('/dashboard');
    }
  }, [authLoading, isSuperAdmin, navigate]);

  // Load data
  useEffect(() => {
    if (isSuperAdmin) {
      loadData();
    }
  }, [isSuperAdmin]);

  async function loadData() {
    setLoading(true);
    try {
      await Promise.all([
        loadErrors(),
        loadLatencyStats(),
        loadMetricsSummary(),
        loadAlerts(),
        loadDeployments(),
        loadOrderHealth(),
      ]);
    } catch (err) {
      console.error('Failed to load system health data:', err);
    } finally {
      setLoading(false);
    }
  }

  async function refreshData() {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }

  async function loadErrors() {
    const { data, error } = await supabase.rpc('get_recent_errors', {
      p_limit: 50,
      p_hours: 24,
    });
    if (!error && data) setErrors(data);
  }

  async function loadLatencyStats() {
    const { data, error } = await supabase.rpc('get_api_latency_stats', {
      p_hours: 24,
    });
    if (!error && data) setLatencyStats(data);
  }

  async function loadMetricsSummary() {
    const { data, error } = await supabase.rpc('get_metrics_summary', {
      p_hours: 24,
    });
    if (!error && data) setMetricsSummary(data);
  }

  async function loadAlerts() {
    const { data, error } = await supabase
      .from('alert_history')
      .select('*')
      .order('triggered_at', { ascending: false })
      .limit(50);
    if (!error && data) setAlerts(data);
  }

  async function loadDeployments() {
    const { data, error } = await supabase
      .from('deployment_log')
      .select('*')
      .order('deployed_at', { ascending: false })
      .limit(20);
    if (!error && data) setDeployments(data);
  }

  async function loadOrderHealth() {
    const { data, error } = await supabase.rpc('get_order_health_summary', {
      p_hours: 24,
    });
    if (!error && data && data.length > 0) setOrderHealth(data[0]);
  }

  async function acknowledgeAlert(alertId: number) {
    await supabase.rpc('acknowledge_alert', { p_alert_id: alertId });
    loadAlerts();
  }

  async function resolveAlert(alertId: number) {
    await supabase.rpc('resolve_alert', { p_alert_id: alertId });
    loadAlerts();
  }

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <RefreshCw className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!isSuperAdmin) {
    return null;
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">System Health</h1>
          <p className="text-muted-foreground">
            Monitor system performance, errors, and alerts
          </p>
        </div>
        <Button onClick={refreshData} disabled={refreshing}>
          <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Errors (24h)</CardTitle>
            <AlertTriangle className="h-4 w-4 text-destructive" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{errors.length}</div>
            <p className="text-xs text-muted-foreground">
              {metricsSummary.find((m) => m.event_type === 'error')?.unique_sessions || 0} sessions affected
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Active Alerts</CardTitle>
            <AlertCircle className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {alerts.filter((a) => a.status !== 'resolved').length}
            </div>
            <p className="text-xs text-muted-foreground">
              {alerts.filter((a) => a.severity === 'critical' && a.status !== 'resolved').length} critical
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Avg Latency</CardTitle>
            <Zap className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {latencyStats.length > 0
                ? Math.round(
                    latencyStats.reduce((sum, s) => sum + s.avg_latency_ms, 0) /
                      latencyStats.length
                  )
                : 0}
              ms
            </div>
            <p className="text-xs text-muted-foreground">
              P95: {latencyStats.length > 0
                ? Math.round(
                    latencyStats.reduce((sum, s) => sum + s.p95_latency_ms, 0) /
                      latencyStats.length
                  )
                : 0}ms
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Order Health</CardTitle>
            <Activity className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {orderHealth?.completion_rate || 0}%
            </div>
            <p className="text-xs text-muted-foreground">
              {(orderHealth?.stuck_preparing || 0) + (orderHealth?.stuck_ready || 0)} stuck orders
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="errors" className="space-y-4">
        <TabsList>
          <TabsTrigger value="errors">
            <AlertTriangle className="h-4 w-4 mr-2" />
            Errors
          </TabsTrigger>
          <TabsTrigger value="latency">
            <Clock className="h-4 w-4 mr-2" />
            Latency
          </TabsTrigger>
          <TabsTrigger value="alerts">
            <AlertCircle className="h-4 w-4 mr-2" />
            Alerts
          </TabsTrigger>
          <TabsTrigger value="orders">
            <Activity className="h-4 w-4 mr-2" />
            Orders
          </TabsTrigger>
          <TabsTrigger value="deployments">
            <Rocket className="h-4 w-4 mr-2" />
            Deployments
          </TabsTrigger>
        </TabsList>

        {/* Errors Tab */}
        <TabsContent value="errors">
          <Card>
            <CardHeader>
              <CardTitle>Recent Errors (24h)</CardTitle>
              <CardDescription>
                Unhandled errors and exceptions from web and Edge Functions
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[400px]">
                {errors.length === 0 ? (
                  <div className="flex items-center justify-center h-32 text-muted-foreground">
                    <CheckCircle className="h-5 w-5 mr-2" />
                    No errors in the last 24 hours
                  </div>
                ) : (
                  <div className="space-y-3">
                    {errors.map((error) => (
                      <div
                        key={error.id}
                        className="border rounded-lg p-3 space-y-2"
                      >
                        <div className="flex items-start justify-between">
                          <div>
                            <Badge variant="destructive" className="mb-1">
                              {error.error_type}
                            </Badge>
                            <p className="font-medium">{error.message}</p>
                          </div>
                          <span className="text-xs text-muted-foreground">
                            {new Date(error.created_at).toLocaleString()}
                          </span>
                        </div>
                        {error.url && (
                          <p className="text-xs text-muted-foreground">
                            URL: {error.url}
                          </p>
                        )}
                        <p className="text-xs text-muted-foreground">
                          Session: {error.session_id}
                        </p>
                      </div>
                    ))}
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Latency Tab */}
        <TabsContent value="latency">
          <Card>
            <CardHeader>
              <CardTitle>API Latency Statistics (24h)</CardTitle>
              <CardDescription>
                Response times by endpoint
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2">Endpoint</th>
                      <th className="text-right py-2">Avg</th>
                      <th className="text-right py-2">P50</th>
                      <th className="text-right py-2">P95</th>
                      <th className="text-right py-2">P99</th>
                      <th className="text-right py-2">Requests</th>
                      <th className="text-right py-2">Errors</th>
                    </tr>
                  </thead>
                  <tbody>
                    {latencyStats.map((stat) => (
                      <tr key={stat.endpoint} className="border-b">
                        <td className="py-2 font-mono text-xs">
                          {stat.endpoint}
                        </td>
                        <td className="text-right py-2">
                          {Math.round(stat.avg_latency_ms)}ms
                        </td>
                        <td className="text-right py-2">
                          {Math.round(stat.p50_latency_ms)}ms
                        </td>
                        <td className="text-right py-2">
                          <span
                            className={
                              stat.p95_latency_ms > 1000 ? 'text-orange-500' : ''
                            }
                          >
                            {Math.round(stat.p95_latency_ms)}ms
                          </span>
                        </td>
                        <td className="text-right py-2">
                          <span
                            className={
                              stat.p99_latency_ms > 2000 ? 'text-red-500' : ''
                            }
                          >
                            {Math.round(stat.p99_latency_ms)}ms
                          </span>
                        </td>
                        <td className="text-right py-2">{stat.request_count}</td>
                        <td className="text-right py-2">
                          <span
                            className={stat.error_count > 0 ? 'text-red-500' : ''}
                          >
                            {stat.error_count}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Alerts Tab */}
        <TabsContent value="alerts">
          <Card>
            <CardHeader>
              <CardTitle>Alert History</CardTitle>
              <CardDescription>
                Triggered alerts and their resolution status
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[400px]">
                {alerts.length === 0 ? (
                  <div className="flex items-center justify-center h-32 text-muted-foreground">
                    <CheckCircle className="h-5 w-5 mr-2" />
                    No alerts triggered
                  </div>
                ) : (
                  <div className="space-y-3">
                    {alerts.map((alert) => (
                      <div
                        key={alert.id}
                        className="border rounded-lg p-3 space-y-2"
                      >
                        <div className="flex items-start justify-between">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <Badge
                                variant={
                                  alert.severity === 'critical'
                                    ? 'destructive'
                                    : alert.severity === 'warning'
                                    ? 'default'
                                    : 'secondary'
                                }
                              >
                                {alert.severity}
                              </Badge>
                              <Badge
                                variant={
                                  alert.status === 'resolved'
                                    ? 'outline'
                                    : alert.status === 'acknowledged'
                                    ? 'secondary'
                                    : 'default'
                                }
                              >
                                {alert.status}
                              </Badge>
                            </div>
                            <p className="font-medium">{alert.message}</p>
                            <p className="text-xs text-muted-foreground">
                              Value: {alert.metric_value} (threshold:{' '}
                              {alert.threshold_value})
                            </p>
                          </div>
                          <span className="text-xs text-muted-foreground">
                            {new Date(alert.triggered_at).toLocaleString()}
                          </span>
                        </div>
                        {alert.status !== 'resolved' && (
                          <div className="flex gap-2">
                            {alert.status === 'triggered' && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => acknowledgeAlert(alert.id)}
                              >
                                Acknowledge
                              </Button>
                            )}
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => resolveAlert(alert.id)}
                            >
                              Resolve
                            </Button>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Orders Tab */}
        <TabsContent value="orders">
          <Card>
            <CardHeader>
              <CardTitle>Order Health (24h)</CardTitle>
              <CardDescription>
                Order processing metrics and stuck order detection
              </CardDescription>
            </CardHeader>
            <CardContent>
              {orderHealth ? (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Total Orders</p>
                    <p className="text-2xl font-bold">{orderHealth.total_orders}</p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Completed</p>
                    <p className="text-2xl font-bold text-green-600">
                      {orderHealth.completed_orders}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Cancelled</p>
                    <p className="text-2xl font-bold text-red-600">
                      {orderHealth.cancelled_orders}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Active</p>
                    <p className="text-2xl font-bold text-blue-600">
                      {orderHealth.active_orders}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Completion Rate</p>
                    <p className="text-2xl font-bold">{orderHealth.completion_rate}%</p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Stuck (Preparing)</p>
                    <p
                      className={`text-2xl font-bold ${
                        orderHealth.stuck_preparing > 0 ? 'text-orange-500' : ''
                      }`}
                    >
                      {orderHealth.stuck_preparing}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Stuck (Ready)</p>
                    <p
                      className={`text-2xl font-bold ${
                        orderHealth.stuck_ready > 0 ? 'text-orange-500' : ''
                      }`}
                    >
                      {orderHealth.stuck_ready}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Avg Completion</p>
                    <p className="text-2xl font-bold">
                      {Math.round(orderHealth.avg_completion_minutes || 0)}m
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-sm text-muted-foreground">Avg Order Value</p>
                    <p className="text-2xl font-bold">
                      ${orderHealth.avg_order_value?.toFixed(2) || '0.00'}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-center h-32 text-muted-foreground">
                  <Database className="h-5 w-5 mr-2" />
                  No order data available
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Deployments Tab */}
        <TabsContent value="deployments">
          <Card>
            <CardHeader>
              <CardTitle>Deployment History</CardTitle>
              <CardDescription>
                Recent deployments and their status
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[400px]">
                {deployments.length === 0 ? (
                  <div className="flex items-center justify-center h-32 text-muted-foreground">
                    <Server className="h-5 w-5 mr-2" />
                    No deployments recorded
                  </div>
                ) : (
                  <div className="space-y-3">
                    {deployments.map((deploy) => (
                      <div
                        key={deploy.id}
                        className="border rounded-lg p-3 space-y-2"
                      >
                        <div className="flex items-start justify-between">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <Badge
                                variant={
                                  deploy.status === 'success'
                                    ? 'default'
                                    : deploy.status === 'failed'
                                    ? 'destructive'
                                    : deploy.status === 'rolled_back'
                                    ? 'secondary'
                                    : 'outline'
                                }
                              >
                                {deploy.status}
                              </Badge>
                              <Badge variant="outline">{deploy.environment}</Badge>
                              {deploy.smoke_test_passed !== null && (
                                <Badge
                                  variant={
                                    deploy.smoke_test_passed
                                      ? 'default'
                                      : 'destructive'
                                  }
                                >
                                  {deploy.smoke_test_passed ? 'Tests Passed' : 'Tests Failed'}
                                </Badge>
                              )}
                            </div>
                            <p className="font-mono text-xs">
                              {deploy.deployment_id}
                            </p>
                            {deploy.version && (
                              <p className="text-sm">Version: {deploy.version}</p>
                            )}
                            {deploy.commit_sha && (
                              <p className="text-xs text-muted-foreground font-mono">
                                {deploy.commit_sha.substring(0, 8)}
                              </p>
                            )}
                          </div>
                          <span className="text-xs text-muted-foreground">
                            {new Date(deploy.deployed_at).toLocaleString()}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
