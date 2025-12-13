/**
 * Autonomous Operations Dashboard Component
 *
 * Displays dynamic pricing, kitchen load, staffing recommendations,
 * menu profitability, and operational health metrics.
 */

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import {
  Activity,
  AlertTriangle,
  ChefHat,
  Clock,
  DollarSign,
  TrendingUp,
  TrendingDown,
  Users,
  Zap,
  RefreshCw,
  Settings,
  CheckCircle,
  XCircle,
  Loader2,
  Play,
  Pause,
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import {
  useAutonomousOps,
  useDynamicPricing,
  useMenuProfitability,
  useStaffingRecommendations,
  updateStoreOpsSettings,
  runAutonomousCycle,
  type OperationalHealth,
  type KitchenLoad,
  type OpsAlerts,
  type DynamicPricingItem,
  type MenuProfitability,
  type StaffingRecommendation,
  type StoreOpsSettings,
} from '@/lib/autonomous-ops';

const COLORS = ['#22c55e', '#eab308', '#f97316', '#ef4444'];

export default function AutonomousOps() {
  const { profile } = useAuth();
  const storeId = profile?.store_id || 1;

  const [activeTab, setActiveTab] = useState('overview');
  const [settings, setSettings] = useState<StoreOpsSettings | null>(null);
  const [isRunningCycle, setIsRunningCycle] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [cycleResult, setCycleResult] = useState<Record<string, any> | null>(null);

  const { loading, error, health, alerts, kitchenLoad, refresh, getSettings } = useAutonomousOps(storeId);
  const { pricing } = useDynamicPricing(storeId);
  const { profitability } = useMenuProfitability(storeId);
  const { recommendations: staffing } = useStaffingRecommendations(storeId);

  useEffect(() => {
    getSettings().then(setSettings);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storeId]);

  const handleRunCycle = async (dryRun: boolean = true) => {
    setIsRunningCycle(true);
    try {
      const result = await runAutonomousCycle(storeId, dryRun);
      setCycleResult(result);
    } finally {
      setIsRunningCycle(false);
    }
  };

  const handleToggleSetting = async (key: keyof StoreOpsSettings, value: boolean) => {
    if (!settings) return;
    const updated = await updateStoreOpsSettings(storeId, { [key]: value });
    setSettings(updated);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertTriangle className="h-4 w-4" />
        <AlertTitle>Error</AlertTitle>
        <AlertDescription>{error.message}</AlertDescription>
      </Alert>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Autonomous Operations</h2>
          <p className="text-muted-foreground">
            AI-powered dynamic pricing, kitchen optimization, and staffing recommendations
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={refresh}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
          <Button
            size="sm"
            variant={isRunningCycle ? 'secondary' : 'default'}
            onClick={() => handleRunCycle(true)}
            disabled={isRunningCycle}
          >
            {isRunningCycle ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <Play className="h-4 w-4 mr-2" />
            )}
            Run Cycle (Dry Run)
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <HealthScoreCard health={health} />
        <KitchenLoadCard load={kitchenLoad} />
        <AlertsCard alerts={alerts} />
        <PricingCard pricing={pricing} />
      </div>

      {/* Main Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="pricing">Pricing</TabsTrigger>
          <TabsTrigger value="kitchen">Kitchen</TabsTrigger>
          <TabsTrigger value="staffing">Staffing</TabsTrigger>
          <TabsTrigger value="profitability">Profitability</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <OverviewTab
            health={health}
            alerts={alerts}
            kitchenLoad={kitchenLoad}
            cycleResult={cycleResult}
          />
        </TabsContent>

        <TabsContent value="pricing" className="space-y-4">
          <PricingTab pricing={pricing} storeId={storeId} />
        </TabsContent>

        <TabsContent value="kitchen" className="space-y-4">
          <KitchenTab load={kitchenLoad} storeId={storeId} />
        </TabsContent>

        <TabsContent value="staffing" className="space-y-4">
          <StaffingTab recommendations={staffing} />
        </TabsContent>

        <TabsContent value="profitability" className="space-y-4">
          <ProfitabilityTab profitability={profitability} />
        </TabsContent>

        <TabsContent value="settings" className="space-y-4">
          <SettingsTab settings={settings} onToggle={handleToggleSetting} />
        </TabsContent>
      </Tabs>
    </div>
  );
}

// ============================================================================
// STAT CARDS
// ============================================================================

function HealthScoreCard({ health }: { health: OperationalHealth | null }) {
  if (!health) return null;

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <Activity className="h-4 w-4" />
          Operational Health
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-baseline gap-2">
          <span
            className="text-4xl font-bold"
            style={{ color: health.grade_color }}
          >
            {health.grade}
          </span>
          <span className="text-2xl text-muted-foreground">
            {health.overall_score}%
          </span>
        </div>
        <Progress value={health.overall_score} className="mt-2" />
      </CardContent>
    </Card>
  );
}

function KitchenLoadCard({ load }: { load: KitchenLoad | null }) {
  if (!load) return null;

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <ChefHat className="h-4 w-4" />
          Kitchen Load
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-baseline gap-2">
          <span
            className="text-2xl font-bold capitalize"
            style={{ color: load.color }}
          >
            {load.load_level}
          </span>
        </div>
        <div className="flex items-center gap-2 mt-2">
          <Progress value={load.capacity_percentage} className="flex-1" />
          <span className="text-sm text-muted-foreground">
            {load.capacity_percentage}%
          </span>
        </div>
        {load.is_critical && (
          <Badge variant="destructive" className="mt-2">
            Action Required
          </Badge>
        )}
      </CardContent>
    </Card>
  );
}

function AlertsCard({ alerts }: { alerts: OpsAlerts | null }) {
  if (!alerts) return null;

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          Active Alerts
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{alerts.total_unresolved}</div>
        <div className="flex gap-2 mt-2">
          {alerts.critical.length > 0 && (
            <Badge variant="destructive">{alerts.critical.length} Critical</Badge>
          )}
          {alerts.warning.length > 0 && (
            <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-600">
              {alerts.warning.length} Warning
            </Badge>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

function PricingCard({ pricing }: { pricing: DynamicPricingItem[] }) {
  const activePricing = pricing.filter((p) => p.price_multiplier !== 1.0);

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <DollarSign className="h-4 w-4" />
          Dynamic Pricing
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold">{activePricing.length}</div>
        <p className="text-sm text-muted-foreground mt-1">
          Items with adjusted pricing
        </p>
        {activePricing.length > 0 && (
          <div className="flex gap-1 mt-2">
            {activePricing.slice(0, 3).map((p) => (
              <Badge
                key={p.item_id}
                variant={p.price_multiplier > 1 ? 'default' : 'secondary'}
              >
                {p.price_multiplier > 1 ? '+' : ''}
                {((p.price_multiplier - 1) * 100).toFixed(0)}%
              </Badge>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ============================================================================
// TAB CONTENT COMPONENTS
// ============================================================================

function OverviewTab({
  health,
  alerts,
  kitchenLoad,
  cycleResult,
}: {
  health: OperationalHealth | null;
  alerts: OpsAlerts | null;
  kitchenLoad: KitchenLoad | null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  cycleResult: Record<string, any> | null;
}) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Health Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>Health Breakdown</CardTitle>
        </CardHeader>
        <CardContent>
          {health && (
            <div className="space-y-4">
              {health.breakdown.map((item) => (
                <div key={item.name} className="flex items-center justify-between">
                  <span className="text-sm font-medium">{item.name}</span>
                  <div className="flex items-center gap-2">
                    <Progress value={item.score} className="w-24" />
                    <span className="text-sm text-muted-foreground w-12 text-right">
                      {item.score}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Recent Alerts */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Alerts</CardTitle>
        </CardHeader>
        <CardContent>
          <ScrollArea className="h-64">
            {alerts && alerts.all.length > 0 ? (
              <div className="space-y-2">
                {alerts.all.slice(0, 10).map((alert) => (
                  <div
                    key={alert.id}
                    className="flex items-start gap-2 p-2 rounded-lg bg-muted/50"
                  >
                    {alert.severity === 'critical' ? (
                      <XCircle className="h-4 w-4 text-red-500 mt-0.5" />
                    ) : alert.severity === 'warning' ? (
                      <AlertTriangle className="h-4 w-4 text-yellow-500 mt-0.5" />
                    ) : (
                      <CheckCircle className="h-4 w-4 text-blue-500 mt-0.5" />
                    )}
                    <div className="flex-1">
                      <p className="text-sm font-medium">{alert.title}</p>
                      <p className="text-xs text-muted-foreground">{alert.message}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No recent alerts</p>
            )}
          </ScrollArea>
        </CardContent>
      </Card>

      {/* Recommendations */}
      <Card className="md:col-span-2">
        <CardHeader>
          <CardTitle>AI Recommendations</CardTitle>
        </CardHeader>
        <CardContent>
          {health && health.recommendations.length > 0 ? (
            <ul className="space-y-2">
              {health.recommendations.map((rec, i) => (
                <li key={i} className="flex items-center gap-2">
                  <Zap className="h-4 w-4 text-primary" />
                  <span className="text-sm">{rec}</span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground">
              All systems operating optimally
            </p>
          )}
        </CardContent>
      </Card>

      {/* Cycle Result */}
      {cycleResult && (
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>
              Last Autonomous Cycle
              {cycleResult.dry_run && (
                <Badge variant="outline" className="ml-2">
                  Dry Run
                </Badge>
              )}
            </CardTitle>
            <CardDescription>
              {new Date(cycleResult.timestamp).toLocaleString()}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {cycleResult.actions.length > 0 ? (
              <ul className="space-y-2">
                {cycleResult.actions.map((action: { applied: boolean; description: string; type: string }, i: number) => (
                  <li key={i} className="flex items-center gap-2">
                    {action.applied ? (
                      <CheckCircle className="h-4 w-4 text-green-500" />
                    ) : (
                      <Clock className="h-4 w-4 text-muted-foreground" />
                    )}
                    <span className="text-sm">{action.description}</span>
                    <Badge variant="outline" className="ml-auto">
                      {action.type}
                    </Badge>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted-foreground">No actions required</p>
            )}
            {cycleResult.errors.length > 0 && (
              <Alert variant="destructive" className="mt-4">
                <AlertTitle>Errors</AlertTitle>
                <AlertDescription>
                  {cycleResult.errors.join(', ')}
                </AlertDescription>
              </Alert>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function PricingTab({ pricing, storeId }: { pricing: DynamicPricingItem[]; storeId: number }) {
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>Dynamic Pricing Rules</CardTitle>
          <CardDescription>
            AI-suggested prices based on demand, inventory, and time factors
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Item</TableHead>
                <TableHead>Base Price</TableHead>
                <TableHead>Suggested Price</TableHead>
                <TableHead>Multiplier</TableHead>
                <TableHead>Confidence</TableHead>
                <TableHead>Reason</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pricing.length > 0 ? (
                pricing.map((item) => (
                  <TableRow key={item.item_id}>
                    <TableCell className="font-medium">{item.item_name}</TableCell>
                    <TableCell>${item.base_price.toFixed(2)}</TableCell>
                    <TableCell>
                      <span
                        className={
                          item.suggested_price > item.base_price
                            ? 'text-green-600'
                            : item.suggested_price < item.base_price
                            ? 'text-red-600'
                            : ''
                        }
                      >
                        ${item.suggested_price.toFixed(2)}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={item.price_multiplier !== 1 ? 'default' : 'outline'}
                      >
                        {item.price_multiplier > 1 ? '+' : ''}
                        {((item.price_multiplier - 1) * 100).toFixed(0)}%
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Progress value={item.confidence * 100} className="w-16" />
                    </TableCell>
                    <TableCell className="max-w-[200px] truncate">
                      {item.reason}
                    </TableCell>
                    <TableCell>
                      {item.is_safe ? (
                        <Badge variant="outline" className="text-green-600">
                          Safe
                        </Badge>
                      ) : (
                        <Badge variant="destructive">Review</Badge>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={7} className="text-center text-muted-foreground">
                    No pricing rules configured
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

function KitchenTab({ load, storeId }: { load: KitchenLoad | null; storeId: number }) {
  if (!load) return null;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      <Card>
        <CardHeader>
          <CardTitle>Current Kitchen Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span>Load Level</span>
              <Badge
                style={{ backgroundColor: load.color, color: 'white' }}
                className="capitalize"
              >
                {load.load_level}
              </Badge>
            </div>
            <div className="flex items-center justify-between">
              <span>Capacity</span>
              <div className="flex items-center gap-2">
                <Progress value={load.capacity_percentage} className="w-24" />
                <span>{load.capacity_percentage}%</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span>Predicted Orders</span>
              <span className="font-bold">{load.predicted_orders}</span>
            </div>
            <div className="flex items-center justify-between">
              <span>Est. Prep Time</span>
              <span className="font-bold">{load.predicted_prep_time} min</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recommendation</CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant={load.is_critical ? 'destructive' : 'default'}>
            <AlertTitle>{load.is_critical ? 'Action Required' : 'Status'}</AlertTitle>
            <AlertDescription>{load.recommendation}</AlertDescription>
          </Alert>
          {load.bottleneck_items.length > 0 && (
            <div className="mt-4">
              <p className="text-sm font-medium mb-2">Bottleneck Items:</p>
              <div className="flex flex-wrap gap-2">
                {load.bottleneck_items.map((itemId) => (
                  <Badge key={itemId} variant="outline">
                    Item #{itemId}
                  </Badge>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function StaffingTab({ recommendations }: { recommendations: StaffingRecommendation[] }) {
  const chartData = recommendations.map((rec) => ({
    hour: rec.hour_label,
    current: rec.current_staff,
    recommended: rec.recommended_staff,
    orders: rec.predicted_orders,
  }));

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>Staffing Recommendations</CardTitle>
          <CardDescription>
            AI-generated staffing levels based on predicted demand
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="hour" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="current" name="Current Staff" fill="#6b7280" />
              <Bar dataKey="recommended" name="Recommended" fill="#22c55e" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Hourly Breakdown</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Hour</TableHead>
                <TableHead>Current</TableHead>
                <TableHead>Recommended</TableHead>
                <TableHead>Delta</TableHead>
                <TableHead>Predicted Orders</TableHead>
                <TableHead>Cost Impact</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {recommendations.map((rec) => (
                <TableRow key={rec.hour_of_day}>
                  <TableCell>{rec.hour_label}</TableCell>
                  <TableCell>{rec.current_staff}</TableCell>
                  <TableCell className="font-medium">{rec.recommended_staff}</TableCell>
                  <TableCell>
                    {rec.is_understaffed ? (
                      <Badge variant="destructive">+{rec.staff_delta}</Badge>
                    ) : rec.is_overstaffed ? (
                      <Badge variant="secondary">{rec.staff_delta}</Badge>
                    ) : (
                      <Badge variant="outline">0</Badge>
                    )}
                  </TableCell>
                  <TableCell>{rec.predicted_orders}</TableCell>
                  <TableCell
                    className={rec.cost_impact.amount > 0 ? 'text-red-600' : 'text-green-600'}
                  >
                    {rec.cost_impact.label}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

function ProfitabilityTab({ profitability }: { profitability: MenuProfitability | null }) {
  if (!profitability) return null;

  const pieData = [
    { name: 'Stars', value: profitability.stars.length, color: '#22c55e' },
    { name: 'Puzzles', value: profitability.puzzles.length, color: '#eab308' },
    { name: 'Plowhorses', value: profitability.plowhorses.length, color: '#f97316' },
    { name: 'Dogs', value: profitability.dogs.length, color: '#ef4444' },
  ].filter((d) => d.value > 0);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Total Items</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{profitability.summary.total_items}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Avg Margin</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {profitability.summary.avg_margin.toFixed(1)}%
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Total Profit</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              ${profitability.summary.total_profit.toFixed(2)}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Stars</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600">
              {profitability.stars.length}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Menu Matrix</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ name, value }) => `${name}: ${value}`}
                >
                  {pieData.map((entry, index) => (
                    <Cell key={index} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recommendations</CardTitle>
          </CardHeader>
          <CardContent>
            {profitability.recommendations.length > 0 ? (
              <ul className="space-y-2">
                {profitability.recommendations.map((rec, i) => (
                  <li key={i} className="flex items-center gap-2">
                    <TrendingUp className="h-4 w-4 text-primary" />
                    <span className="text-sm">{rec}</span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-muted-foreground">Menu is well optimized</p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Items Needing Attention</CardTitle>
          <CardDescription>Low-margin, low-volume items (Dogs)</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Item</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Quantity Sold</TableHead>
                <TableHead>Revenue</TableHead>
                <TableHead>Margin</TableHead>
                <TableHead>Trend</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {profitability.dogs.slice(0, 10).map((item) => (
                <TableRow key={item.item_id}>
                  <TableCell className="font-medium">{item.item_name}</TableCell>
                  <TableCell>{item.category}</TableCell>
                  <TableCell>{item.total_quantity}</TableCell>
                  <TableCell>${item.total_revenue.toFixed(2)}</TableCell>
                  <TableCell>
                    <Badge variant="destructive">
                      {item.margin_percentage.toFixed(1)}%
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {item.trend === 'rising' ? (
                      <TrendingUp className="h-4 w-4 text-green-500" />
                    ) : item.trend === 'falling' ? (
                      <TrendingDown className="h-4 w-4 text-red-500" />
                    ) : (
                      <span className="text-muted-foreground">-</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
              {profitability.dogs.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-muted-foreground">
                    No low-performing items
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

function SettingsTab({
  settings,
  onToggle,
}: {
  settings: StoreOpsSettings | null;
  onToggle: (key: keyof StoreOpsSettings, value: boolean) => void;
}) {
  if (!settings) return null;

  const toggleSettings = [
    {
      key: 'dynamic_pricing_enabled' as const,
      label: 'Dynamic Pricing',
      description: 'Allow AI to suggest price adjustments based on demand',
    },
    {
      key: 'auto_hide_slow_items' as const,
      label: 'Auto-Hide Slow Items',
      description: 'Automatically hide slow-prep items during peak load',
    },
    {
      key: 'alert_on_critical_load' as const,
      label: 'Critical Load Alerts',
      description: 'Send alerts when kitchen load reaches critical levels',
    },
    {
      key: 'auto_staffing_suggestions' as const,
      label: 'Staffing Suggestions',
      description: 'Generate automatic staffing recommendations',
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Settings className="h-5 w-5" />
          Autonomous Operations Settings
        </CardTitle>
        <CardDescription>
          Configure AI automation features for this store
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {toggleSettings.map((setting) => (
          <div
            key={setting.key}
            className="flex items-center justify-between space-x-4"
          >
            <div className="space-y-0.5">
              <label className="text-sm font-medium">{setting.label}</label>
              <p className="text-sm text-muted-foreground">
                {setting.description}
              </p>
            </div>
            <Switch
              checked={settings[setting.key] as boolean}
              onCheckedChange={(checked) => onToggle(setting.key, checked)}
            />
          </div>
        ))}

        <div className="pt-4 border-t">
          <h4 className="text-sm font-medium mb-4">Safety Limits</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">
                Max Price Increase
              </label>
              <p className="text-lg font-medium">
                {settings.max_price_increase_pct}%
              </p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">
                Max Price Decrease
              </label>
              <p className="text-lg font-medium">
                {settings.max_price_decrease_pct}%
              </p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">
                Kitchen Capacity/Hour
              </label>
              <p className="text-lg font-medium">
                {settings.kitchen_capacity_per_hour} orders
              </p>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">
                Min Confidence Threshold
              </label>
              <p className="text-lg font-medium">
                {(settings.min_confidence_threshold * 100).toFixed(0)}%
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
