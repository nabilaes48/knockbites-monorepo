import { useState } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { LocationMap } from "@/components/LocationMap";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { MapPin, Phone, Clock, Navigation, Search } from "lucide-react";
import { Link } from "react-router-dom";
import { locations } from "@/data/locations";


const Locations = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedLocation, setSelectedLocation] = useState<number | null>(null);

  const filteredLocations = locations.filter(
    (location) =>
      location.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      location.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
      location.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
      location.zip.includes(searchQuery)
  );

  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      <main className="pt-20 pb-16">
        <div className="container mx-auto px-4">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl md:text-5xl font-bold mb-4">
              Find a <span className="text-primary">Location</span>
            </h1>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              29 locations serving you across New York, all open 24/7
            </p>
          </div>

          {/* Search Bar */}
          <div className="max-w-md mx-auto mb-8">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
              <Input
                type="text"
                placeholder="Search by city, address, or ZIP code..."
                className="pl-10 h-12"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <p className="text-sm text-muted-foreground mt-2 text-center">
              Showing {filteredLocations.length} of {locations.length} locations
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-8">
            {/* Interactive Map */}
            <div className="order-2 lg:order-1">
              <div className="sticky top-24 h-[600px] border-2 border-border rounded-2xl overflow-hidden shadow-medium">
                <LocationMap
                  locations={filteredLocations}
                  selectedLocation={selectedLocation}
                  onLocationSelect={setSelectedLocation}
                />
              </div>
            </div>

            {/* Store Cards */}
            <div className="order-1 lg:order-2 space-y-4 max-h-[600px] overflow-y-auto pr-2">
              {filteredLocations.length > 0 ? (
                filteredLocations.map((location) => (
                  <Card
                    key={location.id}
                    className={`transition-all hover:shadow-medium cursor-pointer ${
                      selectedLocation === location.id ? "ring-2 ring-primary" : ""
                    }`}
                    onClick={() => setSelectedLocation(location.id)}
                  >
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <CardTitle className="text-xl mb-2">{location.name}</CardTitle>
                          <div className="space-y-2 text-sm text-muted-foreground">
                            <div className="flex items-center gap-2">
                              <MapPin className="h-4 w-4 text-primary flex-shrink-0" />
                              <span>
                                {location.address}, {location.city}, {location.state} {location.zip}
                              </span>
                            </div>
                            <div className="flex items-center gap-2">
                              <Phone className="h-4 w-4 text-primary flex-shrink-0" />
                              <a
                                href={`tel:${location.phone}`}
                                className="hover:text-primary transition-colors"
                                onClick={(e) => e.stopPropagation()}
                              >
                                {location.phone}
                              </a>
                            </div>
                            <div className="flex items-center gap-2">
                              <Navigation className="h-4 w-4 text-primary flex-shrink-0" />
                              <span>{location.distance} away</span>
                            </div>
                          </div>
                        </div>
                        <div className="flex flex-col items-end gap-2">
                          {location.isOpen && (
                            <Badge variant="default" className="bg-accent">
                              <Clock className="h-3 w-3 mr-1" />
                              Open Now
                            </Badge>
                          )}
                          {selectedLocation === location.id && (
                            <Badge variant="default" className="bg-primary">
                              Selected
                            </Badge>
                          )}
                        </div>
                      </div>
                    </CardHeader>

                    <CardContent>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Clock className="h-4 w-4" />
                          <span className="font-semibold text-accent">{location.hours}</span>
                        </div>
                        <div className="flex gap-2">
                          <a
                            href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
                              `${location.address}, ${location.city}, ${location.state} ${location.zip}`
                            )}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            onClick={(e) => e.stopPropagation()}
                          >
                            <Button variant="outline" size="sm">
                              <Navigation className="h-4 w-4 mr-1" />
                              Directions
                            </Button>
                          </a>
                          <Link to="/order" onClick={(e) => {
                            localStorage.setItem("selectedStore", location.id.toString());
                          }}>
                            <Button variant="secondary" size="sm">
                              Order Now
                            </Button>
                          </Link>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))
              ) : (
                <Card>
                  <CardContent className="py-12 text-center">
                    <p className="text-muted-foreground">
                      No locations found matching "{searchQuery}"
                    </p>
                  </CardContent>
                </Card>
              )}
            </div>
          </div>

          {/* Stats Section */}
          <div className="mt-16 grid md:grid-cols-3 gap-6">
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-4xl font-bold text-primary mb-2">29</div>
                <p className="text-lg font-semibold mb-1">Locations</p>
                <p className="text-sm text-muted-foreground">Across New York</p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-4xl font-bold text-secondary mb-2">24/7</div>
                <p className="text-lg font-semibold mb-1">Always Open</p>
                <p className="text-sm text-muted-foreground">Never closed</p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-4xl font-bold text-accent mb-2">100%</div>
                <p className="text-lg font-semibold mb-1">Fresh Daily</p>
                <p className="text-sm text-muted-foreground">Quality guaranteed</p>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default Locations;
