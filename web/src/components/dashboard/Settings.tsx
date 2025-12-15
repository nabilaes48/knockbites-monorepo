import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { GlassCard } from "@/components/ui/GlassCard";
import { GlowingBadge } from "@/components/ui/GlowingBadge";
import { NeonButton } from "@/components/ui/NeonButton";
import { AnimatedCounter } from "@/components/ui/AnimatedCounter";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase";
import {
  Settings as SettingsIcon,
  Store,
  Clock,
  Bell,
  Users,
  Save,
  X,
  Mail,
  Volume2,
  ArrowRight,
  UserCheck,
  Shield,
  Lock,
  Smartphone,
  CheckCircle,
  AlertCircle,
  Loader2,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface SettingsProps {
  onNavigateToStaff?: () => void;
}

export const Settings = ({ onNavigateToStaff }: SettingsProps) => {
  const { toast } = useToast();
  const { profile, user } = useAuth();
  const isSuperAdmin = profile?.role === "super_admin";
  const isAdmin = profile?.role === "admin";
  const isAdminOrHigher = isSuperAdmin || isAdmin;
  const [is24_7, setIs24_7] = useState(false);

  // MFA State
  const [mfaEnabled, setMfaEnabled] = useState(false);
  const [mfaLoading, setMfaLoading] = useState(true);
  const [mfaEnrolling, setMfaEnrolling] = useState(false);
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [totpSecret, setTotpSecret] = useState<string | null>(null);
  const [verifyCode, setVerifyCode] = useState("");
  const [factorId, setFactorId] = useState<string | null>(null);

  // Check MFA status on mount
  useEffect(() => {
    checkMfaStatus();
  }, [user]);

  const checkMfaStatus = async () => {
    if (!user) {
      setMfaLoading(false);
      return;
    }
    try {
      const { data, error } = await supabase.auth.mfa.listFactors();
      if (error) throw error;

      const totpFactor = data?.totp?.find(f => f.status === 'verified');
      setMfaEnabled(!!totpFactor);
      if (totpFactor) {
        setFactorId(totpFactor.id);
      }
    } catch (error) {
      console.error('Error checking MFA status:', error);
    } finally {
      setMfaLoading(false);
    }
  };

  const startMfaEnrollment = async () => {
    setMfaEnrolling(true);
    try {
      const { data, error } = await supabase.auth.mfa.enroll({
        factorType: 'totp',
        friendlyName: 'Authenticator App'
      });

      if (error) throw error;

      setQrCode(data.totp.qr_code);
      setTotpSecret(data.totp.secret);
      setFactorId(data.id);
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to start MFA enrollment",
        variant: "destructive",
      });
      setMfaEnrolling(false);
    }
  };

  const verifyMfaEnrollment = async () => {
    if (!factorId || verifyCode.length !== 6) return;

    try {
      const { error } = await supabase.auth.mfa.challengeAndVerify({
        factorId,
        code: verifyCode
      });

      if (error) throw error;

      setMfaEnabled(true);
      setQrCode(null);
      setTotpSecret(null);
      setVerifyCode("");
      setMfaEnrolling(false);

      toast({
        title: "MFA Enabled",
        description: "Two-factor authentication is now active on your account",
      });
    } catch (error: any) {
      toast({
        title: "Verification Failed",
        description: error.message || "Invalid code. Please try again.",
        variant: "destructive",
      });
    }
  };

  const disableMfa = async () => {
    if (!factorId) return;

    try {
      const { error } = await supabase.auth.mfa.unenroll({ factorId });
      if (error) throw error;

      setMfaEnabled(false);
      setFactorId(null);

      toast({
        title: "MFA Disabled",
        description: "Two-factor authentication has been removed from your account",
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "Failed to disable MFA",
        variant: "destructive",
      });
    }
  };

  const cancelMfaEnrollment = () => {
    setQrCode(null);
    setTotpSecret(null);
    setVerifyCode("");
    setMfaEnrolling(false);
    // Unenroll the pending factor
    if (factorId && !mfaEnabled) {
      supabase.auth.mfa.unenroll({ factorId }).catch(console.error);
      setFactorId(null);
    }
  };
  const [operatingHours, setOperatingHours] = useState({
    monday: { open: "07:00", close: "20:00" },
    tuesday: { open: "07:00", close: "20:00" },
    wednesday: { open: "07:00", close: "20:00" },
    thursday: { open: "07:00", close: "20:00" },
    friday: { open: "07:00", close: "20:00" },
    saturday: { open: "07:00", close: "20:00" },
    sunday: { open: "07:00", close: "17:00" },
  });

  const handleSave = () => {
    toast({
      title: "Settings Saved",
      description: "Your changes have been saved successfully",
    });
  };

  const handleCancel = () => {
    setIs24_7(false);
    setOperatingHours({
      monday: { open: "07:00", close: "20:00" },
      tuesday: { open: "07:00", close: "20:00" },
      wednesday: { open: "07:00", close: "20:00" },
      thursday: { open: "07:00", close: "20:00" },
      friday: { open: "07:00", close: "20:00" },
      saturday: { open: "07:00", close: "20:00" },
      sunday: { open: "07:00", close: "17:00" },
    });
    toast({
      title: "Changes Cancelled",
      description: "Settings have been reset to default values",
    });
  };

  return (
    <div className="max-w-3xl space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-semibold flex items-center gap-2 text-foreground">
          <div
            className={cn(
              "p-2 rounded-lg",
              "bg-primary/10 text-primary",
              "dark:shadow-glow-primary"
            )}
          >
            <SettingsIcon className="h-5 w-5" />
          </div>
          Settings
        </h2>
        <p className="text-muted-foreground mt-1">
          Manage store settings and preferences
        </p>
      </div>

      <div className="space-y-6">
        {/* Store Information */}
        <GlassCard glowColor={isSuperAdmin ? "cyan" : "none"} gradient="blue">
          <div className="p-5">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div
                  className={cn(
                    "p-2 rounded-lg",
                    "bg-primary/10 text-primary"
                  )}
                >
                  <Store className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="font-semibold">Store Information</h3>
                  <p className="text-sm text-muted-foreground">
                    {isSuperAdmin
                      ? "Update your store details"
                      : "View store details (contact Super Admin to modify)"}
                  </p>
                </div>
              </div>
              {isAdmin && (
                <GlowingBadge variant="default" size="sm">
                  <Lock className="h-3 w-3" />
                  Locked
                </GlowingBadge>
              )}
            </div>

            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="storeName" className="text-sm">Store Name (Entity)</Label>
                  <Input
                    id="storeName"
                    defaultValue="Highland Mills Snack Shop Inc"
                    disabled={!isSuperAdmin}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10",
                      !isSuperAdmin && "opacity-60 cursor-not-allowed"
                    )}
                  />
                </div>
                <div>
                  <Label htmlFor="tradeName" className="text-sm">Trade Name</Label>
                  <Input
                    id="tradeName"
                    defaultValue="Jay's Deli"
                    disabled={!isSuperAdmin}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10",
                      !isSuperAdmin && "opacity-60 cursor-not-allowed"
                    )}
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="address" className="text-sm">Address</Label>
                <Input
                  id="address"
                  defaultValue="534 NY-32, Highland Mills, NY 10930"
                  disabled={!isSuperAdmin}
                  className={cn(
                    "mt-1.5",
                    "bg-secondary/50 border-border/50",
                    "dark:bg-card/50 dark:border-primary/10",
                    !isSuperAdmin && "opacity-60 cursor-not-allowed"
                  )}
                />
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="phone" className="text-sm">Phone Number</Label>
                  <Input
                    id="phone"
                    defaultValue="(845) 928-2803"
                    disabled={!isSuperAdmin}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10",
                      !isSuperAdmin && "opacity-60 cursor-not-allowed"
                    )}
                  />
                </div>
                <div>
                  <Label htmlFor="email" className="text-sm">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    defaultValue="jaysdeli@cpetromgmt.com"
                    disabled={!isSuperAdmin}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10",
                      !isSuperAdmin && "opacity-60 cursor-not-allowed"
                    )}
                  />
                </div>
                <div>
                  <Label htmlFor="county" className="text-sm">County</Label>
                  <Input
                    id="county"
                    defaultValue="Orange"
                    disabled={!isSuperAdmin}
                    className={cn(
                      "mt-1.5",
                      "bg-secondary/50 border-border/50",
                      "dark:bg-card/50 dark:border-primary/10",
                      !isSuperAdmin && "opacity-60 cursor-not-allowed"
                    )}
                  />
                </div>
              </div>

              {isAdmin && (
                <div
                  className={cn(
                    "mt-4 p-3 rounded-lg",
                    "bg-ios-yellow/10 border border-ios-yellow/20",
                    "dark:bg-neon-orange/5 dark:border-neon-orange/20"
                  )}
                >
                  <p className="text-sm text-ios-yellow dark:text-neon-orange flex items-center gap-2">
                    <Lock className="h-4 w-4" />
                    Store information can only be modified by Super Admin
                  </p>
                </div>
              )}
            </div>
          </div>
        </GlassCard>

        {/* Operating Hours */}
        <GlassCard glowColor={isSuperAdmin ? "purple" : "none"} gradient="purple">
          <div className="p-5">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div
                  className={cn(
                    "p-2 rounded-lg",
                    "bg-ios-purple/10 text-ios-purple",
                    "dark:bg-neon-purple/10 dark:text-neon-purple"
                  )}
                >
                  <Clock className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="font-semibold">Operating Hours</h3>
                  <p className="text-sm text-muted-foreground">
                    {isSuperAdmin
                      ? "Set your store hours"
                      : "View store hours (contact Super Admin to modify)"}
                  </p>
                </div>
              </div>
              {isAdmin && (
                <GlowingBadge variant="default" size="sm">
                  <Lock className="h-3 w-3" />
                  Locked
                </GlowingBadge>
              )}
            </div>

            <div className="space-y-4">
              <div
                className={cn(
                  "p-3 rounded-lg",
                  "bg-primary/10 border border-primary/20"
                )}
              >
                <p className="text-sm text-primary">
                  <strong>Current Hours:</strong> M-Sat: 7 AM - 8 PM, Sun: 7 AM - 5 PM
                </p>
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">Open 24/7</p>
                  <p className="text-sm text-muted-foreground">
                    Enable for 24-hour operation
                  </p>
                </div>
                <Switch
                  checked={is24_7}
                  onCheckedChange={setIs24_7}
                  aria-label="Toggle 24/7 operating hours"
                  disabled={!isSuperAdmin}
                />
              </div>

              {!is24_7 && (
                <div className="pt-4 border-t border-border/50 dark:border-primary/10 space-y-4">
                  <p className="text-sm font-medium text-muted-foreground">
                    Customize hours for each day:
                  </p>

                  {Object.entries(operatingHours).map(([day, hours]) => (
                    <div key={day} className="grid grid-cols-3 gap-4 items-center">
                      <Label className="capitalize">{day}</Label>
                      <div>
                        <Label className="text-xs text-muted-foreground">Open</Label>
                        <Input
                          type="time"
                          value={hours.open}
                          onChange={(e) =>
                            setOperatingHours({
                              ...operatingHours,
                              [day]: { ...hours, open: e.target.value },
                            })
                          }
                          disabled={!isSuperAdmin}
                          className={cn(
                            "mt-1",
                            "bg-secondary/50 border-border/50",
                            "dark:bg-card/50 dark:border-primary/10",
                            !isSuperAdmin && "opacity-60 cursor-not-allowed"
                          )}
                        />
                      </div>
                      <div>
                        <Label className="text-xs text-muted-foreground">Close</Label>
                        <Input
                          type="time"
                          value={hours.close}
                          onChange={(e) =>
                            setOperatingHours({
                              ...operatingHours,
                              [day]: { ...hours, close: e.target.value },
                            })
                          }
                          disabled={!isSuperAdmin}
                          className={cn(
                            "mt-1",
                            "bg-secondary/50 border-border/50",
                            "dark:bg-card/50 dark:border-primary/10",
                            !isSuperAdmin && "opacity-60 cursor-not-allowed"
                          )}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </GlassCard>

        {/* Notifications */}
        <GlassCard glowColor="accent" gradient="green">
          <div className="p-5">
            <div className="flex items-center gap-2 mb-4">
              <div
                className={cn(
                  "p-2 rounded-lg",
                  "bg-accent/10 text-accent",
                  "dark:bg-neon-green/10 dark:text-neon-green"
                )}
              >
                <Bell className="h-4 w-4" />
              </div>
              <div>
                <h3 className="font-semibold">Notifications</h3>
                <p className="text-sm text-muted-foreground">
                  Manage notification preferences
                </p>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={cn(
                      "p-2 rounded-lg",
                      "bg-accent/10 text-accent",
                      "dark:bg-neon-green/10 dark:text-neon-green"
                    )}
                  >
                    <Bell className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="font-medium">New Order Alerts</p>
                    <p className="text-sm text-muted-foreground">
                      Get notified when new orders arrive
                    </p>
                  </div>
                </div>
                <Switch defaultChecked aria-label="Toggle new order alerts" />
              </div>

              <Separator className="dark:bg-primary/10" />

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={cn(
                      "p-2 rounded-lg",
                      "bg-primary/10 text-primary"
                    )}
                  >
                    <Volume2 className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="font-medium">Sound Notifications</p>
                    <p className="text-sm text-muted-foreground">
                      Play sound when orders are ready
                    </p>
                  </div>
                </div>
                <Switch defaultChecked aria-label="Toggle sound notifications" />
              </div>

              <Separator className="dark:bg-primary/10" />

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={cn(
                      "p-2 rounded-lg",
                      "bg-ios-purple/10 text-ios-purple",
                      "dark:bg-neon-purple/10 dark:text-neon-purple"
                    )}
                  >
                    <Mail className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="font-medium">Email Notifications</p>
                    <p className="text-sm text-muted-foreground">
                      Receive daily order summaries via email
                    </p>
                  </div>
                </div>
                <Switch aria-label="Toggle email notifications" />
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Two-Factor Authentication - Only for Admin and Super Admin */}
        {isAdminOrHigher && (
          <GlassCard glowColor="cyan" gradient="blue">
            <div className="p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div
                    className={cn(
                      "p-2 rounded-lg",
                      "bg-primary/10 text-primary"
                    )}
                  >
                    <Smartphone className="h-4 w-4" />
                  </div>
                  <div>
                    <h3 className="font-semibold">Two-Factor Authentication</h3>
                    <p className="text-sm text-muted-foreground">
                      Add an extra layer of security to your account
                    </p>
                  </div>
                </div>
                {mfaLoading ? (
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                ) : mfaEnabled ? (
                  <GlowingBadge variant="success" size="sm">
                    <CheckCircle className="h-3 w-3" />
                    Enabled
                  </GlowingBadge>
                ) : (
                  <GlowingBadge variant="warning" size="sm">
                    <AlertCircle className="h-3 w-3" />
                    Not Enabled
                  </GlowingBadge>
                )}
              </div>

              {!mfaLoading && (
                <div className="space-y-4">
                  {mfaEnabled ? (
                    // MFA is enabled - show status and disable option
                    <div className="space-y-4">
                      <div
                        className={cn(
                          "p-4 rounded-lg",
                          "bg-accent/10 border border-accent/20",
                          "dark:bg-neon-green/5 dark:border-neon-green/20"
                        )}
                      >
                        <div className="flex items-center gap-3">
                          <CheckCircle className="h-5 w-5 text-accent dark:text-neon-green" />
                          <div>
                            <p className="font-medium text-accent dark:text-neon-green">
                              Two-factor authentication is active
                            </p>
                            <p className="text-sm text-muted-foreground">
                              Your account is protected with an authenticator app
                            </p>
                          </div>
                        </div>
                      </div>
                      <NeonButton
                        variant="destructive"
                        onClick={disableMfa}
                        className="w-full"
                      >
                        <X className="h-4 w-4 mr-2" />
                        Disable Two-Factor Authentication
                      </NeonButton>
                    </div>
                  ) : qrCode ? (
                    // Enrollment in progress - show QR code
                    <div className="space-y-4">
                      <div
                        className={cn(
                          "p-4 rounded-lg text-center",
                          "bg-secondary/50 border border-border/50",
                          "dark:bg-card/50 dark:border-primary/10"
                        )}
                      >
                        <p className="text-sm text-muted-foreground mb-4">
                          Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)
                        </p>
                        <img
                          src={qrCode}
                          alt="MFA QR Code"
                          className="mx-auto w-48 h-48 rounded-lg"
                        />
                        {totpSecret && (
                          <div className="mt-4">
                            <p className="text-xs text-muted-foreground mb-1">
                              Or enter this code manually:
                            </p>
                            <code className="text-xs bg-muted px-2 py-1 rounded font-mono">
                              {totpSecret}
                            </code>
                          </div>
                        )}
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="verifyCode" className="text-sm">
                          Enter the 6-digit code from your app
                        </Label>
                        <Input
                          id="verifyCode"
                          type="text"
                          inputMode="numeric"
                          maxLength={6}
                          placeholder="000000"
                          value={verifyCode}
                          onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, ''))}
                          className={cn(
                            "text-center text-2xl font-mono tracking-widest",
                            "bg-secondary/50 border-border/50",
                            "dark:bg-card/50 dark:border-primary/10"
                          )}
                        />
                      </div>

                      <div className="flex gap-2">
                        <NeonButton
                          variant="ghost"
                          onClick={cancelMfaEnrollment}
                          className="flex-1"
                        >
                          Cancel
                        </NeonButton>
                        <NeonButton
                          onClick={verifyMfaEnrollment}
                          disabled={verifyCode.length !== 6}
                          className="flex-1"
                          glow
                        >
                          <CheckCircle className="h-4 w-4 mr-2" />
                          Verify & Enable
                        </NeonButton>
                      </div>
                    </div>
                  ) : (
                    // MFA not enabled - show enable button
                    <div className="space-y-4">
                      <div
                        className={cn(
                          "p-4 rounded-lg",
                          "bg-ios-yellow/10 border border-ios-yellow/20",
                          "dark:bg-neon-orange/5 dark:border-neon-orange/20"
                        )}
                      >
                        <div className="flex items-start gap-3">
                          <Shield className="h-5 w-5 text-ios-yellow dark:text-neon-orange mt-0.5" />
                          <div>
                            <p className="font-medium text-ios-yellow dark:text-neon-orange">
                              Recommended for administrators
                            </p>
                            <p className="text-sm text-muted-foreground mt-1">
                              Two-factor authentication adds an extra layer of security by requiring a code from your phone in addition to your password.
                            </p>
                          </div>
                        </div>
                      </div>
                      <NeonButton
                        onClick={startMfaEnrollment}
                        disabled={mfaEnrolling}
                        className="w-full"
                        glow
                      >
                        {mfaEnrolling ? (
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        ) : (
                          <Smartphone className="h-4 w-4 mr-2" />
                        )}
                        Set Up Two-Factor Authentication
                      </NeonButton>
                    </div>
                  )}
                </div>
              )}
            </div>
          </GlassCard>
        )}

        {/* Staff Management Quick View */}
        <GlassCard glowColor="purple" gradient="pink" hoverable>
          <div className="p-5">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div
                  className={cn(
                    "p-2 rounded-lg",
                    "bg-ios-purple/10 text-ios-purple",
                    "dark:bg-neon-purple/10 dark:text-neon-purple"
                  )}
                >
                  <Users className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="font-semibold">Staff Management</h3>
                  <p className="text-sm text-muted-foreground">
                    Quick overview of your team
                  </p>
                </div>
              </div>
              <NeonButton
                variant="ghost"
                size="sm"
                onClick={onNavigateToStaff}
                className="gap-1"
              >
                View All
                <ArrowRight className="h-4 w-4" />
              </NeonButton>
            </div>

            {/* Mini Stats */}
            <div className="grid grid-cols-3 gap-3 mb-4">
              <div
                className={cn(
                  "rounded-lg p-3 text-center",
                  "bg-ios-purple/10 border border-ios-purple/20",
                  "dark:bg-neon-purple/5 dark:border-neon-purple/20"
                )}
              >
                <Users className="h-5 w-5 mx-auto mb-2 text-ios-purple dark:text-neon-purple" />
                <div className="text-2xl font-bold">
                  <AnimatedCounter value={5} />
                </div>
                <p className="text-xs text-muted-foreground mt-1">Total Staff</p>
              </div>

              <div
                className={cn(
                  "rounded-lg p-3 text-center",
                  "bg-primary/10 border border-primary/20"
                )}
              >
                <Shield className="h-5 w-5 mx-auto mb-2 text-primary" />
                <div className="text-2xl font-bold">
                  <AnimatedCounter value={2} />
                </div>
                <p className="text-xs text-muted-foreground mt-1">Admins</p>
              </div>

              <div
                className={cn(
                  "rounded-lg p-3 text-center",
                  "bg-accent/10 border border-accent/20",
                  "dark:bg-neon-green/5 dark:border-neon-green/20"
                )}
              >
                <UserCheck className="h-5 w-5 mx-auto mb-2 text-accent dark:text-neon-green" />
                <div className="text-2xl font-bold">
                  <AnimatedCounter value={5} />
                </div>
                <p className="text-xs text-muted-foreground mt-1">Active</p>
              </div>
            </div>

            <NeonButton
              className="w-full gap-2"
              onClick={onNavigateToStaff}
              glow
            >
              <Users className="h-4 w-4" />
              Manage Full Team
            </NeonButton>
          </div>
        </GlassCard>

        {/* Save Button - Only for Super Admin */}
        {isSuperAdmin && (
          <div className="flex justify-end gap-3">
            <NeonButton variant="ghost" onClick={handleCancel} className="gap-2">
              <X className="h-4 w-4" />
              Cancel
            </NeonButton>
            <NeonButton onClick={handleSave} className="gap-2" glow>
              <Save className="h-4 w-4" />
              Save Changes
            </NeonButton>
          </div>
        )}
      </div>
    </div>
  );
};
