import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/hooks/use-toast";
import {
  Mail,
  Calendar,
  Clock,
  Plus,
  MoreHorizontal,
  Edit2,
  Trash2,
  Pause,
  Play,
  Send,
  FileText,
  BarChart3,
  Users,
  DollarSign,
  ShoppingBag,
  CheckCircle2,
  XCircle,
  AlertCircle,
} from "lucide-react";
import { cn } from "@/lib/utils";

// Types for scheduled reports
interface ScheduledReport {
  id: string;
  name: string;
  description: string;
  frequency: "daily" | "weekly" | "monthly";
  dayOfWeek?: number; // 0-6 for weekly
  dayOfMonth?: number; // 1-31 for monthly
  time: string; // HH:MM format
  recipients: string[];
  reportTypes: string[];
  isActive: boolean;
  lastSent?: string;
  nextRun?: string;
  createdAt: string;
}

// Mock data
const mockReports: ScheduledReport[] = [
  {
    id: "1",
    name: "Daily Sales Digest",
    description: "Summary of yesterday's sales, orders, and top items",
    frequency: "daily",
    time: "07:00",
    recipients: ["owner@knockbites.com", "manager@knockbites.com"],
    reportTypes: ["summary", "revenue", "items"],
    isActive: true,
    lastSent: "2025-11-24T07:00:00Z",
    nextRun: "2025-11-25T07:00:00Z",
    createdAt: "2025-11-01T00:00:00Z",
  },
  {
    id: "2",
    name: "Weekly Performance Report",
    description: "Comprehensive weekly analytics with comparisons",
    frequency: "weekly",
    dayOfWeek: 1, // Monday
    time: "08:00",
    recipients: ["owner@knockbites.com"],
    reportTypes: ["summary", "revenue", "items", "customers"],
    isActive: true,
    lastSent: "2025-11-18T08:00:00Z",
    nextRun: "2025-11-25T08:00:00Z",
    createdAt: "2025-11-01T00:00:00Z",
  },
  {
    id: "3",
    name: "Monthly P&L Summary",
    description: "Monthly profit and loss statement with trends",
    frequency: "monthly",
    dayOfMonth: 1,
    time: "09:00",
    recipients: ["accounting@knockbites.com", "owner@knockbites.com"],
    reportTypes: ["summary", "revenue"],
    isActive: false,
    lastSent: "2025-11-01T09:00:00Z",
    nextRun: "2025-12-01T09:00:00Z",
    createdAt: "2025-10-15T00:00:00Z",
  },
];

const reportTypeOptions = [
  { id: "summary", label: "Summary Metrics", icon: BarChart3 },
  { id: "revenue", label: "Revenue Data", icon: DollarSign },
  { id: "items", label: "Item Performance", icon: ShoppingBag },
  { id: "customers", label: "Customer Analytics", icon: Users },
];

const daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export const ScheduledReports = () => {
  const { toast } = useToast();
  const [reports, setReports] = useState<ScheduledReport[]>(mockReports);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingReport, setEditingReport] = useState<ScheduledReport | null>(null);

  // Form state
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    frequency: "daily" as "daily" | "weekly" | "monthly",
    dayOfWeek: 1,
    dayOfMonth: 1,
    time: "07:00",
    recipients: "",
    reportTypes: ["summary"],
    isActive: true,
  });

  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      frequency: "daily",
      dayOfWeek: 1,
      dayOfMonth: 1,
      time: "07:00",
      recipients: "",
      reportTypes: ["summary"],
      isActive: true,
    });
    setEditingReport(null);
  };

  const openEditDialog = (report: ScheduledReport) => {
    setEditingReport(report);
    setFormData({
      name: report.name,
      description: report.description,
      frequency: report.frequency,
      dayOfWeek: report.dayOfWeek || 1,
      dayOfMonth: report.dayOfMonth || 1,
      time: report.time,
      recipients: report.recipients.join(", "),
      reportTypes: report.reportTypes,
      isActive: report.isActive,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const recipientList = formData.recipients
      .split(",")
      .map((e) => e.trim())
      .filter((e) => e.length > 0);

    if (!formData.name || recipientList.length === 0) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    const now = new Date();
    const newReport: ScheduledReport = {
      id: editingReport?.id || Date.now().toString(),
      name: formData.name,
      description: formData.description,
      frequency: formData.frequency,
      dayOfWeek: formData.frequency === "weekly" ? formData.dayOfWeek : undefined,
      dayOfMonth: formData.frequency === "monthly" ? formData.dayOfMonth : undefined,
      time: formData.time,
      recipients: recipientList,
      reportTypes: formData.reportTypes,
      isActive: formData.isActive,
      lastSent: editingReport?.lastSent,
      nextRun: calculateNextRun(formData),
      createdAt: editingReport?.createdAt || now.toISOString(),
    };

    if (editingReport) {
      setReports(reports.map((r) => (r.id === editingReport.id ? newReport : r)));
      toast({
        title: "Report Updated",
        description: `"${newReport.name}" has been updated successfully.`,
      });
    } else {
      setReports([...reports, newReport]);
      toast({
        title: "Report Scheduled",
        description: `"${newReport.name}" has been created and will run ${newReport.frequency}.`,
      });
    }

    setIsDialogOpen(false);
    resetForm();
  };

  const calculateNextRun = (data: typeof formData): string => {
    const now = new Date();
    const [hours, minutes] = data.time.split(":").map(Number);
    const next = new Date(now);
    next.setHours(hours, minutes, 0, 0);

    if (next <= now) {
      next.setDate(next.getDate() + 1);
    }

    if (data.frequency === "weekly") {
      const currentDay = next.getDay();
      const daysUntil = (data.dayOfWeek - currentDay + 7) % 7;
      next.setDate(next.getDate() + (daysUntil === 0 && next <= now ? 7 : daysUntil));
    } else if (data.frequency === "monthly") {
      next.setDate(data.dayOfMonth);
      if (next <= now) {
        next.setMonth(next.getMonth() + 1);
      }
    }

    return next.toISOString();
  };

  const toggleReportStatus = (reportId: string) => {
    setReports(
      reports.map((r) => {
        if (r.id === reportId) {
          const updated = { ...r, isActive: !r.isActive };
          toast({
            title: updated.isActive ? "Report Activated" : "Report Paused",
            description: `"${r.name}" is now ${updated.isActive ? "active" : "paused"}.`,
          });
          return updated;
        }
        return r;
      })
    );
  };

  const deleteReport = (reportId: string) => {
    const report = reports.find((r) => r.id === reportId);
    setReports(reports.filter((r) => r.id !== reportId));
    toast({
      title: "Report Deleted",
      description: `"${report?.name}" has been removed.`,
    });
  };

  const sendTestEmail = (report: ScheduledReport) => {
    toast({
      title: "Test Email Sent",
      description: `A test report has been sent to ${report.recipients[0]}`,
    });
  };

  const formatNextRun = (dateString?: string) => {
    if (!dateString) return "Not scheduled";
    const date = new Date(dateString);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (date.toDateString() === today.toDateString()) {
      return `Today at ${date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
    }
    if (date.toDateString() === tomorrow.toDateString()) {
      return `Tomorrow at ${date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
    }
    return date.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" }) +
      ` at ${date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
  };

  const getFrequencyLabel = (report: ScheduledReport) => {
    switch (report.frequency) {
      case "daily":
        return `Daily at ${report.time}`;
      case "weekly":
        return `Every ${daysOfWeek[report.dayOfWeek || 0]} at ${report.time}`;
      case "monthly":
        return `Monthly on day ${report.dayOfMonth} at ${report.time}`;
      default:
        return report.frequency;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-gradient-to-br from-[#2196F3] to-[#9C27B0] text-white shadow-lg">
              <Mail className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-foreground">Scheduled Reports</h2>
              <p className="text-sm text-muted-foreground">
                Automated email reports delivered to your inbox
              </p>
            </div>
          </div>
        </div>

        <Dialog open={isDialogOpen} onOpenChange={(open) => {
          setIsDialogOpen(open);
          if (!open) resetForm();
        }}>
          <DialogTrigger asChild>
            <NeonButton variant="primary" className="gap-2">
              <Plus className="h-4 w-4" />
              New Report Schedule
            </NeonButton>
          </DialogTrigger>
          <DialogContent className="max-w-lg">
            <DialogHeader>
              <DialogTitle>
                {editingReport ? "Edit Scheduled Report" : "Create Scheduled Report"}
              </DialogTitle>
              <DialogDescription>
                Configure when and what analytics to receive via email
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="name">Report Name *</Label>
                <Input
                  id="name"
                  placeholder="e.g., Daily Sales Digest"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Input
                  id="description"
                  placeholder="Brief description of this report"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Frequency</Label>
                  <Select
                    value={formData.frequency}
                    onValueChange={(value: "daily" | "weekly" | "monthly") =>
                      setFormData({ ...formData, frequency: value })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="daily">Daily</SelectItem>
                      <SelectItem value="weekly">Weekly</SelectItem>
                      <SelectItem value="monthly">Monthly</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Time</Label>
                  <Input
                    type="time"
                    value={formData.time}
                    onChange={(e) => setFormData({ ...formData, time: e.target.value })}
                  />
                </div>
              </div>

              {formData.frequency === "weekly" && (
                <div className="space-y-2">
                  <Label>Day of Week</Label>
                  <Select
                    value={formData.dayOfWeek.toString()}
                    onValueChange={(value) =>
                      setFormData({ ...formData, dayOfWeek: parseInt(value) })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {daysOfWeek.map((day, index) => (
                        <SelectItem key={index} value={index.toString()}>
                          {day}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              {formData.frequency === "monthly" && (
                <div className="space-y-2">
                  <Label>Day of Month</Label>
                  <Select
                    value={formData.dayOfMonth.toString()}
                    onValueChange={(value) =>
                      setFormData({ ...formData, dayOfMonth: parseInt(value) })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {Array.from({ length: 28 }, (_, i) => i + 1).map((day) => (
                        <SelectItem key={day} value={day.toString()}>
                          {day}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="recipients">Recipients *</Label>
                <Input
                  id="recipients"
                  placeholder="email1@example.com, email2@example.com"
                  value={formData.recipients}
                  onChange={(e) => setFormData({ ...formData, recipients: e.target.value })}
                />
                <p className="text-xs text-muted-foreground">
                  Separate multiple emails with commas
                </p>
              </div>

              <div className="space-y-3">
                <Label>Report Contents</Label>
                <div className="grid grid-cols-2 gap-3">
                  {reportTypeOptions.map((option) => (
                    <div
                      key={option.id}
                      className={cn(
                        "flex items-center gap-2 p-3 rounded-lg border cursor-pointer transition-colors",
                        formData.reportTypes.includes(option.id)
                          ? "border-primary bg-primary/10"
                          : "border-border hover:bg-muted/50"
                      )}
                      onClick={() => {
                        const newTypes = formData.reportTypes.includes(option.id)
                          ? formData.reportTypes.filter((t) => t !== option.id)
                          : [...formData.reportTypes, option.id];
                        setFormData({ ...formData, reportTypes: newTypes });
                      }}
                    >
                      <Checkbox
                        checked={formData.reportTypes.includes(option.id)}
                        className="pointer-events-none"
                      />
                      <option.icon className="h-4 w-4 text-muted-foreground" />
                      <span className="text-sm">{option.label}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
                <div className="flex items-center gap-2">
                  <Play className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm font-medium">Activate immediately</span>
                </div>
                <Switch
                  checked={formData.isActive}
                  onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                Cancel
              </Button>
              <NeonButton variant="primary" onClick={handleSave}>
                {editingReport ? "Update Schedule" : "Create Schedule"}
              </NeonButton>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <GlassCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-500/20 text-blue-600">
              <FileText className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold">{reports.length}</p>
              <p className="text-xs text-muted-foreground">Total Schedules</p>
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/20 text-green-600">
              <CheckCircle2 className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold">{reports.filter((r) => r.isActive).length}</p>
              <p className="text-xs text-muted-foreground">Active</p>
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-orange-500/20 text-orange-600">
              <Clock className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold">{reports.filter((r) => r.frequency === "daily").length}</p>
              <p className="text-xs text-muted-foreground">Daily Reports</p>
            </div>
          </div>
        </GlassCard>

        <GlassCard className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-purple-500/20 text-purple-600">
              <Send className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold">
                {reports.reduce((acc, r) => acc + r.recipients.length, 0)}
              </p>
              <p className="text-xs text-muted-foreground">Recipients</p>
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Reports List */}
      <GlassCard className="p-0 overflow-hidden">
        <div className="p-4 border-b border-border">
          <h3 className="font-semibold">Scheduled Reports</h3>
          <p className="text-sm text-muted-foreground">
            Manage your automated email report schedules
          </p>
        </div>

        {reports.length === 0 ? (
          <div className="p-12 text-center">
            <Mail className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="font-semibold mb-2">No Scheduled Reports</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Create your first scheduled report to receive analytics via email
            </p>
            <NeonButton variant="primary" onClick={() => setIsDialogOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Create Schedule
            </NeonButton>
          </div>
        ) : (
          <div className="divide-y divide-border">
            {reports.map((report) => (
              <div
                key={report.id}
                className={cn(
                  "p-4 hover:bg-muted/30 transition-colors",
                  !report.isActive && "opacity-60"
                )}
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="font-semibold truncate">{report.name}</h4>
                      <Badge
                        variant={report.isActive ? "default" : "secondary"}
                        className={cn(
                          "text-xs",
                          report.isActive && "bg-green-500/20 text-green-700 dark:text-green-400"
                        )}
                      >
                        {report.isActive ? "Active" : "Paused"}
                      </Badge>
                      <Badge variant="outline" className="text-xs capitalize">
                        {report.frequency}
                      </Badge>
                    </div>

                    <p className="text-sm text-muted-foreground mb-2">{report.description}</p>

                    <div className="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        <span>{getFrequencyLabel(report)}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Mail className="h-3 w-3" />
                        <span>{report.recipients.length} recipient(s)</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        <span>Next: {formatNextRun(report.nextRun)}</span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-1 mt-2">
                      {report.reportTypes.map((type) => {
                        const option = reportTypeOptions.find((o) => o.id === type);
                        return option ? (
                          <Badge key={type} variant="secondary" className="text-xs gap-1">
                            <option.icon className="h-3 w-3" />
                            {option.label}
                          </Badge>
                        ) : null;
                      })}
                    </div>
                  </div>

                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon">
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => openEditDialog(report)}>
                        <Edit2 className="h-4 w-4 mr-2" />
                        Edit Schedule
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => sendTestEmail(report)}>
                        <Send className="h-4 w-4 mr-2" />
                        Send Test Email
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => toggleReportStatus(report.id)}>
                        {report.isActive ? (
                          <>
                            <Pause className="h-4 w-4 mr-2" />
                            Pause Schedule
                          </>
                        ) : (
                          <>
                            <Play className="h-4 w-4 mr-2" />
                            Activate Schedule
                          </>
                        )}
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={() => deleteReport(report.id)}
                        className="text-destructive focus:text-destructive"
                      >
                        <Trash2 className="h-4 w-4 mr-2" />
                        Delete Schedule
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            ))}
          </div>
        )}
      </GlassCard>

      {/* Info Card */}
      <GlassCard className="p-4">
        <div className="flex items-start gap-3">
          <div className="p-2 rounded-lg bg-blue-500/20 text-blue-600">
            <AlertCircle className="h-5 w-5" />
          </div>
          <div>
            <h4 className="font-semibold mb-1">About Scheduled Reports</h4>
            <p className="text-sm text-muted-foreground">
              Scheduled reports are sent automatically at the configured times. Reports include data
              from the previous period (e.g., daily reports contain yesterday's data). All times are
              in your local timezone. Make sure recipients have valid email addresses to receive
              reports.
            </p>
          </div>
        </div>
      </GlassCard>
    </div>
  );
};

export default ScheduledReports;
