import { useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Megaphone,
  Mail,
  MessageSquare,
  Users,
  Tag,
  Gift,
  Zap,
  Plus,
  Search,
  Edit,
  Trash2,
  Send,
  Clock,
  CheckCircle,
  XCircle,
  BarChart3,
  Eye,
  MousePointer,
  DollarSign,
  Calendar,
  Filter,
  Copy,
  Play,
  Pause,
  Target,
  TrendingUp,
  Percent,
  ArrowRight,
} from "lucide-react";
import { cn } from "@/lib/utils";

// Types
interface Campaign {
  id: string;
  name: string;
  type: "email" | "sms" | "push";
  status: "draft" | "scheduled" | "active" | "completed" | "paused";
  subject?: string;
  content: string;
  segment: string;
  scheduledAt?: string;
  sentAt?: string;
  stats: {
    sent: number;
    delivered: number;
    opened: number;
    clicked: number;
    converted: number;
    revenue: number;
  };
}

interface Segment {
  id: string;
  name: string;
  description: string;
  criteria: string[];
  customerCount: number;
  lastUpdated: string;
}

interface Promotion {
  id: string;
  name: string;
  code: string;
  type: "percentage" | "fixed" | "bogo" | "freeItem";
  value: number;
  minOrder?: number;
  maxDiscount?: number;
  startDate: string;
  endDate: string;
  usageLimit?: number;
  usedCount: number;
  status: "active" | "scheduled" | "expired" | "disabled";
}

interface Automation {
  id: string;
  name: string;
  trigger: string;
  actions: string[];
  status: "active" | "paused";
  triggered: number;
  converted: number;
}

// Mock Data
const mockCampaigns: Campaign[] = [
  {
    id: "1",
    name: "Weekend Special Blast",
    type: "email",
    status: "completed",
    subject: "🔥 20% Off This Weekend Only!",
    content: "Don't miss our exclusive weekend deals...",
    segment: "All Customers",
    sentAt: "2025-11-23T10:00:00",
    stats: { sent: 1250, delivered: 1180, opened: 472, clicked: 156, converted: 45, revenue: 1890 },
  },
  {
    id: "2",
    name: "New Menu Alert",
    type: "sms",
    status: "active",
    content: "Try our new Philly Cheesesteak! Order now & get free fries.",
    segment: "Frequent Buyers",
    sentAt: "2025-11-24T14:00:00",
    stats: { sent: 850, delivered: 842, opened: 758, clicked: 234, converted: 67, revenue: 2340 },
  },
  {
    id: "3",
    name: "Win-Back Campaign",
    type: "email",
    status: "scheduled",
    subject: "We Miss You! Here's 15% Off",
    content: "It's been a while since your last visit...",
    segment: "Lapsed Customers",
    scheduledAt: "2025-11-26T09:00:00",
    stats: { sent: 0, delivered: 0, opened: 0, clicked: 0, converted: 0, revenue: 0 },
  },
  {
    id: "4",
    name: "Holiday Promo",
    type: "email",
    status: "draft",
    subject: "Holiday Specials Are Here!",
    content: "Celebrate the season with our festive menu...",
    segment: "All Customers",
    stats: { sent: 0, delivered: 0, opened: 0, clicked: 0, converted: 0, revenue: 0 },
  },
];

const mockSegments: Segment[] = [
  { id: "1", name: "All Customers", description: "Every customer in the database", criteria: ["All"], customerCount: 2450, lastUpdated: "2025-11-25" },
  { id: "2", name: "Frequent Buyers", description: "Ordered 5+ times in last 30 days", criteria: ["orders >= 5", "last 30 days"], customerCount: 385, lastUpdated: "2025-11-25" },
  { id: "3", name: "High Spenders", description: "Spent $200+ total", criteria: ["total_spent >= 200"], customerCount: 156, lastUpdated: "2025-11-25" },
  { id: "4", name: "Lapsed Customers", description: "No order in 60+ days", criteria: ["last_order > 60 days"], customerCount: 423, lastUpdated: "2025-11-25" },
  { id: "5", name: "New Customers", description: "First order in last 7 days", criteria: ["first_order < 7 days"], customerCount: 89, lastUpdated: "2025-11-25" },
  { id: "6", name: "Birthday This Month", description: "Customers with birthday this month", criteria: ["birthday_month = current"], customerCount: 67, lastUpdated: "2025-11-25" },
];

const mockPromotions: Promotion[] = [
  { id: "1", name: "Weekend 20% Off", code: "WEEKEND20", type: "percentage", value: 20, minOrder: 15, startDate: "2025-11-23", endDate: "2025-11-24", usageLimit: 500, usedCount: 234, status: "expired" },
  { id: "2", name: "Free Fries", code: "FREEFRIES", type: "freeItem", value: 0, minOrder: 10, startDate: "2025-11-20", endDate: "2025-12-01", usedCount: 156, status: "active" },
  { id: "3", name: "$5 Off First Order", code: "WELCOME5", type: "fixed", value: 5, startDate: "2025-01-01", endDate: "2025-12-31", usedCount: 892, status: "active" },
  { id: "4", name: "BOGO Burgers", code: "BOGOBURGER", type: "bogo", value: 0, startDate: "2025-12-01", endDate: "2025-12-07", usageLimit: 200, usedCount: 0, status: "scheduled" },
];

const mockAutomations: Automation[] = [
  { id: "1", name: "Welcome Series", trigger: "New customer signup", actions: ["Send welcome email", "Send 10% coupon after 3 days"], status: "active", triggered: 892, converted: 267 },
  { id: "2", name: "Abandoned Cart", trigger: "Cart abandoned for 1 hour", actions: ["Send reminder email", "Send SMS if no response"], status: "active", triggered: 456, converted: 123 },
  { id: "3", name: "Birthday Reward", trigger: "Customer birthday", actions: ["Send birthday email", "Apply free item coupon"], status: "active", triggered: 234, converted: 189 },
  { id: "4", name: "Win-Back Flow", trigger: "No order in 30 days", actions: ["Send miss-you email", "Send 15% coupon after 7 days"], status: "paused", triggered: 567, converted: 89 },
  { id: "5", name: "Review Request", trigger: "Order completed", actions: ["Wait 2 hours", "Send review request email"], status: "active", triggered: 1234, converted: 312 },
];

// Status Badge Component
const StatusBadge = ({ status }: { status: string }) => {
  const variants: Record<string, "success" | "warning" | "danger" | "info" | "default"> = {
    active: "success",
    completed: "success",
    scheduled: "warning",
    draft: "default",
    paused: "warning",
    expired: "danger",
    disabled: "danger",
  };
  return (
    <GlowingBadge variant={variants[status] || "default"} size="sm">
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </GlowingBadge>
  );
};

// Campaign Type Icon
const CampaignTypeIcon = ({ type }: { type: "email" | "sms" | "push" }) => {
  const icons = {
    email: <Mail className="h-4 w-4" />,
    sms: <MessageSquare className="h-4 w-4" />,
    push: <Megaphone className="h-4 w-4" />,
  };
  const colors = {
    email: "bg-blue-500/20 text-blue-600",
    sms: "bg-green-500/20 text-green-600",
    push: "bg-purple-500/20 text-purple-600",
  };
  return (
    <div className={cn("p-2 rounded-lg", colors[type])}>
      {icons[type]}
    </div>
  );
};

export const MarketingManagement = () => {
  const [activeTab, setActiveTab] = useState("campaigns");
  const [searchQuery, setSearchQuery] = useState("");
  const [campaigns] = useState<Campaign[]>(mockCampaigns);
  const [segments] = useState<Segment[]>(mockSegments);
  const [promotions] = useState<Promotion[]>(mockPromotions);
  const [automations] = useState<Automation[]>(mockAutomations);
  const [showNewCampaign, setShowNewCampaign] = useState(false);
  const [showNewPromotion, setShowNewPromotion] = useState(false);
  const [showNewSegment, setShowNewSegment] = useState(false);

  // Calculate stats
  const totalSent = campaigns.reduce((sum, c) => sum + c.stats.sent, 0);
  const totalRevenue = campaigns.reduce((sum, c) => sum + c.stats.revenue, 0);
  const avgOpenRate = campaigns.filter(c => c.stats.sent > 0).reduce((sum, c) => sum + (c.stats.opened / c.stats.delivered * 100), 0) / campaigns.filter(c => c.stats.sent > 0).length || 0;
  const avgConversion = campaigns.filter(c => c.stats.sent > 0).reduce((sum, c) => sum + (c.stats.converted / c.stats.sent * 100), 0) / campaigns.filter(c => c.stats.sent > 0).length || 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-gradient-to-br from-[#2196F3] to-[#FF8C42] text-white shadow-lg">
            <Megaphone className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-foreground">Marketing Hub</h2>
            <p className="text-sm text-muted-foreground">Campaigns, promotions & customer engagement</p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 w-[200px]"
            />
          </div>
          <button
            onClick={() => setShowNewCampaign(true)}
            className="relative group inline-flex items-center justify-center gap-2 px-6 py-3 text-base font-semibold text-white rounded-xl overflow-hidden transition-all duration-300 hover:scale-105 active:scale-95"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-[#2196F3] to-[#FF8C42] transition-all duration-300" />
            <div className="absolute inset-0 bg-gradient-to-r from-[#FF8C42] to-[#2196F3] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            <div className="absolute inset-0 opacity-0 group-hover:opacity-30 bg-white transition-opacity duration-300" />
            <Plus className="relative h-5 w-5" />
            <span className="relative">New Campaign</span>
          </button>
        </div>
      </div>

      {/* Stats Overview - Glowing Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Messages Sent Card */}
        <div className="relative group">
          <div className="absolute -inset-0.5 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-2xl blur opacity-30 group-hover:opacity-50 transition duration-300 dark:opacity-50 dark:group-hover:opacity-70" />
          <div className="relative bg-background rounded-xl p-5 h-full flex flex-col">
            <div className="flex-1">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center text-white mb-4 shadow-lg shadow-blue-500/30">
                <Send className="h-7 w-7" />
              </div>
              <p className="text-sm font-medium text-muted-foreground">Messages Sent</p>
              <p className="text-3xl font-bold mt-1 bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">
                {totalSent.toLocaleString()}
              </p>
            </div>
            <p className="text-xs text-muted-foreground mt-3 pt-3 border-t border-border/50">This month</p>
          </div>
        </div>

        {/* Open Rate Card */}
        <div className="relative group">
          <div className="absolute -inset-0.5 bg-gradient-to-r from-green-500 to-emerald-500 rounded-2xl blur opacity-30 group-hover:opacity-50 transition duration-300 dark:opacity-50 dark:group-hover:opacity-70" />
          <div className="relative bg-background rounded-xl p-5 h-full flex flex-col">
            <div className="flex-1">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-green-500 to-emerald-500 flex items-center justify-center text-white mb-4 shadow-lg shadow-green-500/30">
                <Eye className="h-7 w-7" />
              </div>
              <p className="text-sm font-medium text-muted-foreground">Open Rate</p>
              <p className="text-3xl font-bold mt-1 bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                {avgOpenRate.toFixed(1)}%
              </p>
            </div>
            <p className="text-xs text-green-600 mt-3 pt-3 border-t border-border/50">+2.3% vs avg</p>
          </div>
        </div>

        {/* Conversion Rate Card */}
        <div className="relative group">
          <div className="absolute -inset-0.5 bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl blur opacity-30 group-hover:opacity-50 transition duration-300 dark:opacity-50 dark:group-hover:opacity-70" />
          <div className="relative bg-background rounded-xl p-5 h-full flex flex-col">
            <div className="flex-1">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center text-white mb-4 shadow-lg shadow-purple-500/30">
                <MousePointer className="h-7 w-7" />
              </div>
              <p className="text-sm font-medium text-muted-foreground">Conversion Rate</p>
              <p className="text-3xl font-bold mt-1 bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
                {avgConversion.toFixed(1)}%
              </p>
            </div>
            <p className="text-xs text-purple-600 mt-3 pt-3 border-t border-border/50">Above industry avg</p>
          </div>
        </div>

        {/* Revenue Card */}
        <div className="relative group">
          <div className="absolute -inset-0.5 bg-gradient-to-r from-orange-500 to-amber-500 rounded-2xl blur opacity-30 group-hover:opacity-50 transition duration-300 dark:opacity-50 dark:group-hover:opacity-70" />
          <div className="relative bg-background rounded-xl p-5 h-full flex flex-col">
            <div className="flex-1">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center text-white mb-4 shadow-lg shadow-orange-500/30">
                <DollarSign className="h-7 w-7" />
              </div>
              <p className="text-sm font-medium text-muted-foreground">Revenue Generated</p>
              <p className="text-3xl font-bold mt-1 bg-gradient-to-r from-orange-600 to-amber-600 bg-clip-text text-transparent">
                ${totalRevenue.toLocaleString()}
              </p>
            </div>
            <p className="text-xs text-orange-600 mt-3 pt-3 border-t border-border/50">From campaigns</p>
          </div>
        </div>
      </div>

      {/* Main Tabs */}
      <GlassCard className="p-1.5">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="bg-transparent h-auto flex flex-wrap gap-1 p-1">
            <TabsTrigger value="campaigns" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              <Mail className="h-4 w-4 mr-2" />
              Campaigns
            </TabsTrigger>
            <TabsTrigger value="segments" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              <Users className="h-4 w-4 mr-2" />
              Segments
            </TabsTrigger>
            <TabsTrigger value="promotions" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              <Tag className="h-4 w-4 mr-2" />
              Promotions
            </TabsTrigger>
            <TabsTrigger value="automations" className="px-4 py-2 rounded-lg data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              <Zap className="h-4 w-4 mr-2" />
              Automations
            </TabsTrigger>
          </TabsList>

          {/* Campaigns Tab */}
          <TabsContent value="campaigns" className="p-4 space-y-4">
            <div className="flex justify-between items-center">
              <div className="flex gap-2">
                <Select defaultValue="all">
                  <SelectTrigger className="w-[140px]">
                    <Filter className="h-4 w-4 mr-2" />
                    <SelectValue placeholder="Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="scheduled">Scheduled</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="completed">Completed</SelectItem>
                  </SelectContent>
                </Select>
                <Select defaultValue="all">
                  <SelectTrigger className="w-[120px]">
                    <SelectValue placeholder="Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Types</SelectItem>
                    <SelectItem value="email">Email</SelectItem>
                    <SelectItem value="sms">SMS</SelectItem>
                    <SelectItem value="push">Push</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-3">
              {campaigns.map((campaign) => (
                <GlassCard key={campaign.id} className="p-4 hover:shadow-lg transition-shadow">
                  <div className="flex items-start gap-4">
                    <CampaignTypeIcon type={campaign.type} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold truncate">{campaign.name}</h3>
                        <StatusBadge status={campaign.status} />
                      </div>
                      {campaign.subject && (
                        <p className="text-sm text-muted-foreground truncate">{campaign.subject}</p>
                      )}
                      <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <Users className="h-3 w-3" />
                          {campaign.segment}
                        </span>
                        {campaign.sentAt && (
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            Sent {new Date(campaign.sentAt).toLocaleDateString()}
                          </span>
                        )}
                        {campaign.scheduledAt && (
                          <span className="flex items-center gap-1">
                            <Calendar className="h-3 w-3" />
                            Scheduled {new Date(campaign.scheduledAt).toLocaleDateString()}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="text-right space-y-1">
                      {campaign.stats.sent > 0 && (
                        <>
                          <p className="text-sm">
                            <span className="text-muted-foreground">Sent:</span>{" "}
                            <span className="font-medium">{campaign.stats.sent.toLocaleString()}</span>
                          </p>
                          <p className="text-sm">
                            <span className="text-muted-foreground">Opens:</span>{" "}
                            <span className="font-medium text-green-600">
                              {((campaign.stats.opened / campaign.stats.delivered) * 100).toFixed(1)}%
                            </span>
                          </p>
                          <p className="text-sm">
                            <span className="text-muted-foreground">Revenue:</span>{" "}
                            <span className="font-medium text-orange-600">${campaign.stats.revenue}</span>
                          </p>
                        </>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <NeonButton variant="secondary" size="icon">
                        <Edit className="h-4 w-4" />
                      </NeonButton>
                      <NeonButton variant="secondary" size="icon">
                        <Copy className="h-4 w-4" />
                      </NeonButton>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          </TabsContent>

          {/* Segments Tab */}
          <TabsContent value="segments" className="p-4 space-y-4">
            <div className="flex justify-end">
              <button
                onClick={() => setShowNewSegment(true)}
                className="relative group inline-flex items-center justify-center gap-2 px-5 py-2.5 text-sm font-semibold text-white rounded-xl overflow-hidden transition-all duration-300 hover:scale-105 active:scale-95"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300" />
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500 to-blue-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <Plus className="relative h-4 w-4" />
                <span className="relative">Create Segment</span>
              </button>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {segments.map((segment) => (
                <GlassCard key={segment.id} className="p-4 hover:shadow-lg transition-shadow cursor-pointer">
                  <div className="flex items-start justify-between mb-3">
                    <div className="p-2 rounded-lg bg-blue-500/20 text-blue-600">
                      <Users className="h-5 w-5" />
                    </div>
                    <NeonButton variant="secondary" size="sm">
                      <Target className="h-3 w-3 mr-1" />
                      Target
                    </NeonButton>
                  </div>
                  <h3 className="font-semibold mb-1">{segment.name}</h3>
                  <p className="text-sm text-muted-foreground mb-3">{segment.description}</p>
                  <div className="flex items-center justify-between">
                    <span className="text-2xl font-bold text-primary">{segment.customerCount.toLocaleString()}</span>
                    <span className="text-xs text-muted-foreground">customers</span>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-1">
                    {segment.criteria.map((c, i) => (
                      <span key={i} className="text-xs px-2 py-1 rounded-full bg-muted">{c}</span>
                    ))}
                  </div>
                </GlassCard>
              ))}
            </div>
          </TabsContent>

          {/* Promotions Tab */}
          <TabsContent value="promotions" className="p-4 space-y-4">
            <div className="flex justify-end">
              <button
                onClick={() => setShowNewPromotion(true)}
                className="relative group inline-flex items-center justify-center gap-2 px-5 py-2.5 text-sm font-semibold text-white rounded-xl overflow-hidden transition-all duration-300 hover:scale-105 active:scale-95"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-green-500 to-emerald-500 transition-all duration-300" />
                <div className="absolute inset-0 bg-gradient-to-r from-emerald-500 to-green-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <Plus className="relative h-4 w-4" />
                <span className="relative">Create Promotion</span>
              </button>
            </div>

            <div className="space-y-3">
              {promotions.map((promo) => (
                <GlassCard key={promo.id} className="p-4 hover:shadow-lg transition-shadow">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-3 rounded-xl",
                      promo.type === "percentage" ? "bg-green-500/20 text-green-600" :
                      promo.type === "fixed" ? "bg-blue-500/20 text-blue-600" :
                      promo.type === "bogo" ? "bg-purple-500/20 text-purple-600" :
                      "bg-orange-500/20 text-orange-600"
                    )}>
                      {promo.type === "percentage" ? <Percent className="h-5 w-5" /> :
                       promo.type === "fixed" ? <DollarSign className="h-5 w-5" /> :
                       promo.type === "bogo" ? <Gift className="h-5 w-5" /> :
                       <Gift className="h-5 w-5" />}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold">{promo.name}</h3>
                        <StatusBadge status={promo.status} />
                      </div>
                      <div className="flex items-center gap-4 text-sm">
                        <span className="font-mono bg-muted px-2 py-0.5 rounded">{promo.code}</span>
                        {promo.type === "percentage" && <span>{promo.value}% off</span>}
                        {promo.type === "fixed" && <span>${promo.value} off</span>}
                        {promo.type === "bogo" && <span>Buy One Get One</span>}
                        {promo.type === "freeItem" && <span>Free Item</span>}
                        {promo.minOrder && <span className="text-muted-foreground">Min ${promo.minOrder}</span>}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted-foreground">
                        {promo.startDate} - {promo.endDate}
                      </p>
                      <p className="text-sm">
                        <span className="font-semibold">{promo.usedCount}</span>
                        {promo.usageLimit && <span className="text-muted-foreground">/{promo.usageLimit}</span>} used
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <NeonButton variant="secondary" size="icon">
                        <Edit className="h-4 w-4" />
                      </NeonButton>
                      <NeonButton variant="secondary" size="icon">
                        <Copy className="h-4 w-4" />
                      </NeonButton>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          </TabsContent>

          {/* Automations Tab */}
          <TabsContent value="automations" className="p-4 space-y-4">
            <div className="flex justify-end">
              <NeonButton variant="secondary">
                <Plus className="h-4 w-4 mr-2" />
                Create Automation
              </NeonButton>
            </div>

            <div className="space-y-3">
              {automations.map((auto) => (
                <GlassCard key={auto.id} className="p-4 hover:shadow-lg transition-shadow">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-3 rounded-xl",
                      auto.status === "active" ? "bg-green-500/20 text-green-600" : "bg-yellow-500/20 text-yellow-600"
                    )}>
                      <Zap className="h-5 w-5" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold">{auto.name}</h3>
                        <StatusBadge status={auto.status} />
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">
                        <span className="font-medium">Trigger:</span> {auto.trigger}
                      </p>
                      <div className="flex items-center gap-2 text-xs">
                        {auto.actions.map((action, i) => (
                          <span key={i} className="flex items-center gap-1">
                            {i > 0 && <ArrowRight className="h-3 w-3 text-muted-foreground" />}
                            <span className="px-2 py-1 rounded-full bg-muted">{action}</span>
                          </span>
                        ))}
                      </div>
                    </div>
                    <div className="text-right space-y-1">
                      <p className="text-sm">
                        <span className="text-muted-foreground">Triggered:</span>{" "}
                        <span className="font-medium">{auto.triggered.toLocaleString()}</span>
                      </p>
                      <p className="text-sm">
                        <span className="text-muted-foreground">Converted:</span>{" "}
                        <span className="font-medium text-green-600">
                          {auto.converted} ({((auto.converted / auto.triggered) * 100).toFixed(1)}%)
                        </span>
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <NeonButton
                        variant={auto.status === "active" ? "secondary" : "primary"}
                        size="icon"
                        title={auto.status === "active" ? "Pause" : "Activate"}
                      >
                        {auto.status === "active" ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                      </NeonButton>
                      <NeonButton variant="secondary" size="icon">
                        <Edit className="h-4 w-4" />
                      </NeonButton>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </GlassCard>

      {/* New Campaign Dialog */}
      <Dialog open={showNewCampaign} onOpenChange={setShowNewCampaign}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Create New Campaign</DialogTitle>
            <DialogDescription>Set up a new marketing campaign to reach your customers.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="grid grid-cols-3 gap-3">
              <GlassCard className="p-4 cursor-pointer hover:shadow-lg transition-shadow border-2 border-transparent hover:border-primary">
                <Mail className="h-8 w-8 text-blue-600 mb-2" />
                <h4 className="font-semibold">Email</h4>
                <p className="text-xs text-muted-foreground">Rich content, images, links</p>
              </GlassCard>
              <GlassCard className="p-4 cursor-pointer hover:shadow-lg transition-shadow border-2 border-transparent hover:border-primary">
                <MessageSquare className="h-8 w-8 text-green-600 mb-2" />
                <h4 className="font-semibold">SMS</h4>
                <p className="text-xs text-muted-foreground">Short, direct messages</p>
              </GlassCard>
              <GlassCard className="p-4 cursor-pointer hover:shadow-lg transition-shadow border-2 border-transparent hover:border-primary">
                <Megaphone className="h-8 w-8 text-purple-600 mb-2" />
                <h4 className="font-semibold">Push</h4>
                <p className="text-xs text-muted-foreground">App notifications</p>
              </GlassCard>
            </div>
            <div className="space-y-3">
              <div>
                <Label>Campaign Name</Label>
                <Input placeholder="e.g., Holiday Special Blast" />
              </div>
              <div>
                <Label>Subject Line</Label>
                <Input placeholder="e.g., 🎉 Don't Miss Our Holiday Deals!" />
              </div>
              <div>
                <Label>Target Segment</Label>
                <Select>
                  <SelectTrigger>
                    <SelectValue placeholder="Select audience" />
                  </SelectTrigger>
                  <SelectContent>
                    {segments.map(s => (
                      <SelectItem key={s.id} value={s.id}>{s.name} ({s.customerCount})</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Message Content</Label>
                <Textarea placeholder="Write your message here..." rows={4} />
              </div>
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <Switch id="schedule" />
                  <Label htmlFor="schedule">Schedule for later</Label>
                </div>
              </div>
            </div>
          </div>
          <DialogFooter>
            <NeonButton variant="secondary" onClick={() => setShowNewCampaign(false)}>Cancel</NeonButton>
            <NeonButton variant="primary">
              <Send className="h-4 w-4 mr-2" />
              Create Campaign
            </NeonButton>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* New Promotion Dialog */}
      <Dialog open={showNewPromotion} onOpenChange={setShowNewPromotion}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Create New Promotion</DialogTitle>
            <DialogDescription>Set up a discount code or special offer.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label>Promotion Name</Label>
              <Input placeholder="e.g., Summer Sale" />
            </div>
            <div>
              <Label>Promo Code</Label>
              <Input placeholder="e.g., SUMMER20" className="font-mono uppercase" />
            </div>
            <div>
              <Label>Discount Type</Label>
              <Select>
                <SelectTrigger>
                  <SelectValue placeholder="Select type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="percentage">Percentage Off</SelectItem>
                  <SelectItem value="fixed">Fixed Amount Off</SelectItem>
                  <SelectItem value="bogo">Buy One Get One</SelectItem>
                  <SelectItem value="freeItem">Free Item</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label>Value</Label>
                <Input type="number" placeholder="20" />
              </div>
              <div>
                <Label>Min Order ($)</Label>
                <Input type="number" placeholder="15" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label>Start Date</Label>
                <Input type="date" />
              </div>
              <div>
                <Label>End Date</Label>
                <Input type="date" />
              </div>
            </div>
            <div>
              <Label>Usage Limit (optional)</Label>
              <Input type="number" placeholder="Leave empty for unlimited" />
            </div>
          </div>
          <DialogFooter>
            <NeonButton variant="secondary" onClick={() => setShowNewPromotion(false)}>Cancel</NeonButton>
            <NeonButton variant="primary">
              <Plus className="h-4 w-4 mr-2" />
              Create Promotion
            </NeonButton>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* New Segment Dialog */}
      <Dialog open={showNewSegment} onOpenChange={setShowNewSegment}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Create Customer Segment</DialogTitle>
            <DialogDescription>Define criteria to group your customers.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label>Segment Name</Label>
              <Input placeholder="e.g., VIP Customers" />
            </div>
            <div>
              <Label>Description</Label>
              <Input placeholder="e.g., Customers who spent over $500" />
            </div>
            <div>
              <Label>Criteria</Label>
              <div className="space-y-2">
                <div className="flex gap-2">
                  <Select>
                    <SelectTrigger className="w-[140px]">
                      <SelectValue placeholder="Field" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="total_spent">Total Spent</SelectItem>
                      <SelectItem value="order_count">Order Count</SelectItem>
                      <SelectItem value="last_order">Last Order</SelectItem>
                      <SelectItem value="signup_date">Signup Date</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select>
                    <SelectTrigger className="w-[100px]">
                      <SelectValue placeholder="Operator" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="gt">Greater than</SelectItem>
                      <SelectItem value="lt">Less than</SelectItem>
                      <SelectItem value="eq">Equals</SelectItem>
                    </SelectContent>
                  </Select>
                  <Input placeholder="Value" className="flex-1" />
                </div>
                <NeonButton variant="secondary" size="sm" className="w-full">
                  <Plus className="h-3 w-3 mr-1" />
                  Add Condition
                </NeonButton>
              </div>
            </div>
          </div>
          <DialogFooter>
            <NeonButton variant="secondary" onClick={() => setShowNewSegment(false)}>Cancel</NeonButton>
            <NeonButton variant="primary">
              <Plus className="h-4 w-4 mr-2" />
              Create Segment
            </NeonButton>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default MarketingManagement;
