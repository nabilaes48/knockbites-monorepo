import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Cookie, X, Settings } from "lucide-react";
import { Link } from "react-router-dom";

export const CookieConsent = () => {
  const [showBanner, setShowBanner] = useState(false);
  const [showPreferences, setShowPreferences] = useState(false);

  const [preferences, setPreferences] = useState({
    essential: true, // Always true, cannot be disabled
    functional: true,
    analytics: true,
    marketing: true,
  });

  useEffect(() => {
    // Check if user has already made a choice
    const consent = localStorage.getItem("cookieConsent");
    if (!consent) {
      // Show banner after a short delay
      const timer = setTimeout(() => {
        setShowBanner(true);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleAcceptAll = () => {
    const consent = {
      essential: true,
      functional: true,
      analytics: true,
      marketing: true,
      timestamp: new Date().toISOString(),
    };
    localStorage.setItem("cookieConsent", JSON.stringify(consent));
    setShowBanner(false);
  };

  const handleRejectNonEssential = () => {
    const consent = {
      essential: true,
      functional: false,
      analytics: false,
      marketing: false,
      timestamp: new Date().toISOString(),
    };
    localStorage.setItem("cookieConsent", JSON.stringify(consent));
    setShowBanner(false);
  };

  const handleSavePreferences = () => {
    const consent = {
      ...preferences,
      essential: true, // Always true
      timestamp: new Date().toISOString(),
    };
    localStorage.setItem("cookieConsent", JSON.stringify(consent));
    setShowBanner(false);
    setShowPreferences(false);
  };

  const handleTogglePreference = (key: string) => {
    if (key === "essential") return; // Cannot disable essential cookies
    setPreferences((prev) => ({
      ...prev,
      [key]: !prev[key as keyof typeof prev],
    }));
  };

  if (!showBanner) return null;

  return (
    <>
      {/* Overlay */}
      {showPreferences && (
        <div
          className="fixed inset-0 bg-black/50 z-[9998]"
          onClick={() => setShowPreferences(false)}
        />
      )}

      {/* Main Cookie Banner */}
      {!showPreferences ? (
        <Card className="fixed bottom-4 left-4 right-4 md:left-auto md:right-4 md:max-w-md z-[9999] shadow-2xl border-2">
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className="flex-shrink-0">
                  <Cookie className="h-6 w-6 text-accent" />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-lg mb-2">We Value Your Privacy</h3>
                  <p className="text-sm text-muted-foreground">
                    We use cookies to enhance your browsing experience, serve personalized content,
                    and analyze our traffic. By clicking "Accept All", you consent to our use of
                    cookies.
                  </p>
                </div>
              </div>
              <button
                onClick={() => setShowBanner(false)}
                className="flex-shrink-0 p-1 hover:bg-muted rounded-full transition-colors"
                aria-label="Close cookie banner"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="flex flex-col gap-2">
              <div className="flex flex-wrap gap-2">
                <Button
                  variant="secondary"
                  size="sm"
                  className="flex-1 min-w-[120px]"
                  onClick={handleAcceptAll}
                >
                  Accept All
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1 min-w-[120px]"
                  onClick={handleRejectNonEssential}
                >
                  Reject Non-Essential
                </Button>
              </div>
              <Button
                variant="ghost"
                size="sm"
                className="w-full"
                onClick={() => setShowPreferences(true)}
              >
                <Settings className="h-4 w-4 mr-2" />
                Customize Preferences
              </Button>
            </div>

            <p className="text-xs text-muted-foreground">
              Learn more in our{" "}
              <Link to="/cookie-policy" className="text-primary hover:underline">
                Cookie Policy
              </Link>{" "}
              and{" "}
              <Link to="/privacy-policy" className="text-primary hover:underline">
                Privacy Policy
              </Link>
              .
            </p>
          </CardContent>
        </Card>
      ) : (
        /* Cookie Preferences Modal */
        <Card className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90%] max-w-lg z-[9999] shadow-2xl border-2 max-h-[90vh] overflow-y-auto">
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-start justify-between gap-3 mb-4">
              <div>
                <h3 className="font-semibold text-xl mb-1">Cookie Preferences</h3>
                <p className="text-sm text-muted-foreground">
                  Manage your cookie settings below. Essential cookies cannot be disabled.
                </p>
              </div>
              <button
                onClick={() => setShowPreferences(false)}
                className="flex-shrink-0 p-1 hover:bg-muted rounded-full transition-colors"
                aria-label="Close preferences"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Essential Cookies */}
            <div className="border rounded-lg p-4 bg-muted/30">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <h4 className="font-semibold">Essential Cookies</h4>
                  <span className="text-xs bg-primary text-primary-foreground px-2 py-0.5 rounded">
                    Always Active
                  </span>
                </div>
              </div>
              <p className="text-sm text-muted-foreground">
                Required for the website to function. These cookies enable core functionality like
                security, authentication, and shopping cart features.
              </p>
            </div>

            {/* Functional Cookies */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold">Functional Cookies</h4>
                <button
                  onClick={() => handleTogglePreference("functional")}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    preferences.functional ? "bg-primary" : "bg-muted"
                  }`}
                  role="switch"
                  aria-checked={preferences.functional}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      preferences.functional ? "translate-x-6" : "translate-x-1"
                    }`}
                  />
                </button>
              </div>
              <p className="text-sm text-muted-foreground">
                Enable enhanced functionality like remembering your preferences, location, and
                personalized features.
              </p>
            </div>

            {/* Analytics Cookies */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold">Analytics Cookies</h4>
                <button
                  onClick={() => handleTogglePreference("analytics")}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    preferences.analytics ? "bg-primary" : "bg-muted"
                  }`}
                  role="switch"
                  aria-checked={preferences.analytics}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      preferences.analytics ? "translate-x-6" : "translate-x-1"
                    }`}
                  />
                </button>
              </div>
              <p className="text-sm text-muted-foreground">
                Help us understand how visitors use our website to improve performance and user
                experience.
              </p>
            </div>

            {/* Marketing Cookies */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold">Marketing Cookies</h4>
                <button
                  onClick={() => handleTogglePreference("marketing")}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    preferences.marketing ? "bg-primary" : "bg-muted"
                  }`}
                  role="switch"
                  aria-checked={preferences.marketing}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      preferences.marketing ? "translate-x-6" : "translate-x-1"
                    }`}
                  />
                </button>
              </div>
              <p className="text-sm text-muted-foreground">
                Used to deliver personalized advertisements and measure marketing campaign
                effectiveness.
              </p>
            </div>

            <div className="flex flex-col gap-2 pt-2">
              <Button variant="secondary" className="w-full" onClick={handleSavePreferences}>
                Save Preferences
              </Button>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1"
                  onClick={() => setShowPreferences(false)}
                >
                  Cancel
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="flex-1"
                  onClick={handleAcceptAll}
                >
                  Accept All
                </Button>
              </div>
            </div>

            <p className="text-xs text-muted-foreground text-center">
              View our{" "}
              <Link to="/cookie-policy" className="text-primary hover:underline">
                Cookie Policy
              </Link>{" "}
              for more details.
            </p>
          </CardContent>
        </Card>
      )}
    </>
  );
};
