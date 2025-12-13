import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { Store, ArrowLeft, Users, MapPin } from "lucide-react";
import { locations } from "@/data/locations";

const RequestStaffAccess = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    phone: "",
    preferredStore: "",
    reason: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    // Validate form
    if (!formData.fullName || !formData.email || !formData.phone || !formData.preferredStore) {
      toast({
        title: "Missing Information",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      setIsSubmitting(false);
      return;
    }

    // In a real application, this would send a request to the backend
    // For now, we'll simulate success
    try {
      // TODO: Send staff access request to backend/database
      // This would create a pending request in a staff_requests table
      // that admins can approve/reject in the Staff Management dashboard

      await new Promise(resolve => setTimeout(resolve, 1500)); // Simulate API call

      toast({
        title: "Request Submitted!",
        description: "Your staff access request has been sent to the administrators. You'll be notified via email once it's reviewed.",
      });

      // Redirect to login page after 2 seconds
      setTimeout(() => {
        navigate("/dashboard/login");
      }, 2000);
    } catch (error: any) {
      toast({
        title: "Submission Failed",
        description: error.message || "Failed to submit request. Please try again.",
        variant: "destructive",
      });
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-background flex items-center justify-center p-4">
      <div className="w-full max-w-2xl">
        <Link
          to="/dashboard/login"
          className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Login
        </Link>

        <Card>
          <CardHeader className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-500/10 mx-auto mb-4">
              <Users className="h-8 w-8 text-blue-500" />
            </div>
            <CardTitle className="text-2xl">Request Staff Access</CardTitle>
            <CardDescription>
              Join the KnockBites team - submit your request for staff access
            </CardDescription>
          </CardHeader>

          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Personal Information */}
              <div className="space-y-4">
                <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                  Personal Information
                </h3>

                <div>
                  <Label htmlFor="fullName">
                    Full Name <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="fullName"
                    type="text"
                    placeholder="John Doe"
                    value={formData.fullName}
                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                    required
                  />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="email">
                      Email <span className="text-red-500">*</span>
                    </Label>
                    <Input
                      id="email"
                      type="email"
                      placeholder="john.doe@example.com"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      required
                    />
                  </div>

                  <div>
                    <Label htmlFor="phone">
                      Phone Number <span className="text-red-500">*</span>
                    </Label>
                    <Input
                      id="phone"
                      type="tel"
                      placeholder="(555) 123-4567"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      required
                    />
                  </div>
                </div>
              </div>

              {/* Store Preference */}
              <div className="space-y-4">
                <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                  Store Preference
                </h3>

                <div>
                  <Label htmlFor="preferredStore">
                    Preferred Store Location <span className="text-red-500">*</span>
                  </Label>
                  <Select
                    value={formData.preferredStore}
                    onValueChange={(value) => setFormData({ ...formData, preferredStore: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select a store location" />
                    </SelectTrigger>
                    <SelectContent>
                      {locations
                        .filter(loc => loc.isOpen)
                        .map((location) => (
                          <SelectItem key={location.id} value={location.id.toString()}>
                            <div className="flex items-center gap-2">
                              <MapPin className="h-4 w-4 text-muted-foreground" />
                              <span>{location.name} - {location.city}, {location.state}</span>
                            </div>
                          </SelectItem>
                        ))}
                    </SelectContent>
                  </Select>
                  <p className="text-xs text-muted-foreground mt-1">
                    Select the store where you'd like to work
                  </p>
                </div>
              </div>

              {/* Additional Information */}
              <div className="space-y-4">
                <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
                  Additional Information
                </h3>

                <div>
                  <Label htmlFor="reason">
                    Why do you want to join our team? (Optional)
                  </Label>
                  <Textarea
                    id="reason"
                    placeholder="Tell us why you'd like to work at KnockBites..."
                    rows={4}
                    value={formData.reason}
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  />
                </div>
              </div>

              {/* Info Box */}
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <p className="text-sm font-semibold text-blue-900 mb-1">
                  What happens next?
                </p>
                <ul className="text-xs text-blue-700 space-y-1 list-disc list-inside">
                  <li>Your request will be reviewed by store administrators</li>
                  <li>You'll receive an email notification about your request status</li>
                  <li>If approved, you'll get staff login credentials</li>
                  <li>Initial access level: <strong>Staff</strong> (can be promoted later)</li>
                </ul>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                size="lg"
                className="w-full"
                disabled={isSubmitting}
              >
                {isSubmitting ? "Submitting Request..." : "Submit Request"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default RequestStaffAccess;
