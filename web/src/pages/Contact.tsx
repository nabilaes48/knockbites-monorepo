import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Mail, Phone, MapPin, Clock, Send } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

const Contact = () => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    subject: "",
    message: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    // Simulate form submission
    setTimeout(() => {
      toast.success("Message sent successfully!", {
        description: "We'll get back to you within 24 hours.",
      });
      setFormData({ name: "", email: "", phone: "", subject: "", message: "" });
      setIsSubmitting(false);
    }, 1000);
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      {/* Hero Section */}
      <section className="relative pt-32 pb-16 overflow-hidden">
        <div className="container mx-auto px-4">
          <div className="max-w-3xl mx-auto text-center animate-fade-in">
            <h1 className="text-5xl md:text-6xl font-bold mb-6 text-foreground">
              Get in{" "}
              <span className="bg-gradient-hero bg-clip-text text-transparent">
                Touch
              </span>
            </h1>
            <p className="text-xl text-muted-foreground mb-8">
              Have questions? We're here to help 24/7, just like our stores.
            </p>
          </div>
        </div>
      </section>

      {/* Contact Information & Form */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-2 gap-8 max-w-6xl mx-auto">
            {/* Contact Information */}
            <div className="space-y-6">
              <Card className="shadow-soft border-border/50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-primary">
                    <Phone className="h-5 w-5" />
                    Phone Support
                  </CardTitle>
                  <CardDescription>
                    Call us anytime, we're always open
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <a
                    href="tel:1-800-KNOCKBITES"
                    className="text-2xl font-semibold text-foreground hover:text-primary transition-colors"
                  >
                    1-800-KNOCKBITES
                  </a>
                  <p className="text-sm text-muted-foreground mt-2">
                    Available 24 hours a day, 7 days a week
                  </p>
                </CardContent>
              </Card>

              <Card className="shadow-soft border-border/50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-primary">
                    <Mail className="h-5 w-5" />
                    Email Support
                  </CardTitle>
                  <CardDescription>
                    Send us an email and we'll respond within 24 hours
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <a
                    href="mailto:support@knockbites.com"
                    className="text-lg font-semibold text-foreground hover:text-primary transition-colors"
                  >
                    support@knockbites.com
                  </a>
                </CardContent>
              </Card>

              <Card className="shadow-soft border-border/50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-primary">
                    <MapPin className="h-5 w-5" />
                    Visit Us
                  </CardTitle>
                  <CardDescription>29 locations across New York</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-foreground mb-2">
                    Find your nearest KnockBites location
                  </p>
                  <Button variant="outline" className="w-full" asChild>
                    <a href="/locations">View All Locations</a>
                  </Button>
                </CardContent>
              </Card>

              <Card className="shadow-soft border-border/50 bg-accent/10 border-accent/30">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-accent">
                    <Clock className="h-5 w-5" />
                    Open 24/7
                  </CardTitle>
                  <CardDescription>
                    We're always here when you need us
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-foreground font-semibold">
                    All locations open 24 hours a day
                  </p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Fresh food, anytime you need it
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Contact Form */}
            <Card className="shadow-medium border-border/50">
              <CardHeader>
                <CardTitle className="text-2xl">Send Us a Message</CardTitle>
                <CardDescription>
                  Fill out the form below and we'll get back to you soon
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Name *</Label>
                    <Input
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                      placeholder="Your name"
                      className="focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email">Email *</Label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      placeholder="your.email@example.com"
                      className="focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="phone">Phone</Label>
                    <Input
                      id="phone"
                      name="phone"
                      type="tel"
                      value={formData.phone}
                      onChange={handleChange}
                      placeholder="(555) 123-4567"
                      className="focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="subject">Subject *</Label>
                    <Input
                      id="subject"
                      name="subject"
                      value={formData.subject}
                      onChange={handleChange}
                      required
                      placeholder="How can we help?"
                      className="focus:ring-primary"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="message">Message *</Label>
                    <Textarea
                      id="message"
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      required
                      placeholder="Tell us more about your inquiry..."
                      rows={5}
                      className="focus:ring-primary resize-none"
                    />
                  </div>

                  <Button
                    type="submit"
                    variant="secondary"
                    className="w-full"
                    disabled={isSubmitting}
                  >
                    {isSubmitting ? (
                      <>Sending...</>
                    ) : (
                      <>
                        <Send className="h-4 w-4 mr-2" />
                        Send Message
                      </>
                    )}
                  </Button>

                  <p className="text-xs text-muted-foreground text-center">
                    We typically respond within 24 hours
                  </p>
                </form>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
};

export default Contact;
