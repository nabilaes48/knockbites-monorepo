import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Store, Clock, MapPin, Users, Award, Heart } from "lucide-react";

const About = () => {
  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      <main className="pt-20 pb-16">
        <div className="container mx-auto px-4">
          {/* Hero Section */}
          <div className="text-center mb-12">
            <h1 className="text-4xl md:text-5xl font-bold mb-4">
              About <span className="text-primary">KnockBites</span>
            </h1>
            <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
              Serving fresh, quality food 24 hours a day, 7 days a week across 29 locations in New York
            </p>
          </div>

          {/* Our Story */}
          <div className="max-w-4xl mx-auto mb-16">
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-2xl font-bold mb-4">Our Story</h2>
                <div className="space-y-4 text-muted-foreground">
                  <p>
                    Founded with a simple mission: to provide delicious, fresh food whenever you need it.
                    KnockBites has grown from a single location to a network of 29 stores across
                    New York, serving thousands of satisfied customers every day.
                  </p>
                  <p>
                    We pride ourselves on using only the freshest ingredients, preparing everything daily,
                    and maintaining the highest standards of quality and service. Whether it's breakfast at
                    6 AM or a late-night snack at midnight, we're here for you.
                  </p>
                  <p>
                    Our commitment to the community goes beyond just serving great food. We're dedicated to
                    creating jobs, supporting local suppliers, and being a reliable presence in every
                    neighborhood we serve.
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Stats */}
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
            <Card>
              <CardContent className="pt-6 text-center">
                <Store className="h-12 w-12 text-primary mx-auto mb-3" />
                <div className="text-4xl font-bold text-primary mb-2">29</div>
                <p className="text-lg font-semibold">Locations</p>
                <p className="text-sm text-muted-foreground">Across New York</p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6 text-center">
                <Clock className="h-12 w-12 text-secondary mx-auto mb-3" />
                <div className="text-4xl font-bold text-secondary mb-2">24/7</div>
                <p className="text-lg font-semibold">Always Open</p>
                <p className="text-sm text-muted-foreground">Never closed</p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6 text-center">
                <Users className="h-12 w-12 text-accent mx-auto mb-3" />
                <div className="text-4xl font-bold text-accent mb-2">1000+</div>
                <p className="text-lg font-semibold">Daily Customers</p>
                <p className="text-sm text-muted-foreground">Served with care</p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6 text-center">
                <Award className="h-12 w-12 text-orange-600 mx-auto mb-3" />
                <div className="text-4xl font-bold text-orange-600 mb-2">4.7★</div>
                <p className="text-lg font-semibold">Customer Rating</p>
                <p className="text-sm text-muted-foreground">Based on reviews</p>
              </CardContent>
            </Card>
          </div>

          {/* What We Offer */}
          <div className="max-w-4xl mx-auto mb-16">
            <h2 className="text-3xl font-bold mb-8 text-center">What We Offer</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <Card>
                <CardContent className="pt-6">
                  <Heart className="h-10 w-10 text-primary mb-4" />
                  <h3 className="text-xl font-semibold mb-2">Fresh Ingredients</h3>
                  <p className="text-muted-foreground">
                    We source the freshest ingredients daily and prepare everything from scratch
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <Clock className="h-10 w-10 text-secondary mb-4" />
                  <h3 className="text-xl font-semibold mb-2">24/7 Availability</h3>
                  <p className="text-muted-foreground">
                    Open around the clock, ready to serve you whenever hunger strikes
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <MapPin className="h-10 w-10 text-accent mb-4" />
                  <h3 className="text-xl font-semibold mb-2">Convenient Locations</h3>
                  <p className="text-muted-foreground">
                    29 stores across New York, always close to where you need us
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Our Values */}
          <div className="max-w-4xl mx-auto">
            <Card className="bg-gradient-to-br from-blue-50 to-orange-50 border-2">
              <CardContent className="pt-6">
                <h2 className="text-2xl font-bold mb-6 text-center">Our Values</h2>
                <div className="grid md:grid-cols-2 gap-6">
                  <div>
                    <Badge className="mb-2 bg-primary">Quality First</Badge>
                    <p className="text-muted-foreground">
                      We never compromise on the quality of our food or service
                    </p>
                  </div>
                  <div>
                    <Badge className="mb-2 bg-secondary">Customer Focus</Badge>
                    <p className="text-muted-foreground">
                      Your satisfaction and experience are our top priorities
                    </p>
                  </div>
                  <div>
                    <Badge className="mb-2 bg-accent">Community</Badge>
                    <p className="text-muted-foreground">
                      We're proud to be part of the neighborhoods we serve
                    </p>
                  </div>
                  <div>
                    <Badge className="mb-2 bg-orange-600">Innovation</Badge>
                    <p className="text-muted-foreground">
                      Always improving and finding new ways to serve you better
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default About;
