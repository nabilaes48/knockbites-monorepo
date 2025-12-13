import { useState } from "react";
import { MapPin, Phone, Clock, Navigation } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LocationMap } from "@/components/LocationMap";
import { locations } from "@/data/locations";
import { Link } from "react-router-dom";

// Show first 6 locations on homepage
const stores = locations.slice(0, 6);

export const StoreLocator = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedStore, setSelectedStore] = useState<number | null>(null);

  const filteredStores = stores.filter(
    (store) =>
      store.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.zip.includes(searchQuery)
  );

  return (
    <section className="py-20 bg-muted/30">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Find a <span className="text-primary">Location</span>
          </h2>
          <p className="text-xl text-muted-foreground mb-8">
            29 locations across New York, always open to serve you
          </p>

          {/* Search Bar */}
          <div className="max-w-md mx-auto relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search by city, address, or location name..."
              className="pl-10 h-12"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Interactive Map */}
          <div className="order-2 lg:order-1">
            <div className="sticky top-24 h-[600px] border-2 border-border rounded-2xl overflow-hidden shadow-medium">
              <LocationMap
                locations={filteredStores}
                selectedLocation={selectedStore}
                onLocationSelect={setSelectedStore}
              />
            </div>
          </div>

          {/* Store Cards */}
          <div className="order-1 lg:order-2 space-y-4 max-h-[600px] overflow-y-auto pr-2">
            {filteredStores.length > 0 ? (
              filteredStores.map((store) => (
                <Card
                  key={store.id}
                  className={`transition-all hover:shadow-medium cursor-pointer ${
                    selectedStore === store.id ? "ring-2 ring-primary" : ""
                  }`}
                  onClick={() => setSelectedStore(store.id)}
                >
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <CardTitle className="text-xl mb-1">{store.name}</CardTitle>
                        <CardDescription className="text-base">
                          {store.address}, {store.city}, {store.state} {store.zip}
                        </CardDescription>
                      </div>
                      <div className="flex items-center gap-2">
                        {store.isOpen && (
                          <span className="inline-flex items-center gap-1 bg-accent/20 border border-accent text-accent px-3 py-1 rounded-full text-xs font-semibold">
                            <Clock className="h-3 w-3" />
                            Open Now
                          </span>
                        )}
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Phone className="h-4 w-4 text-primary" />
                        <span>{store.phone}</span>
                      </div>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Clock className="h-4 w-4 text-primary" />
                        <span>{store.hours}</span>
                      </div>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Navigation className="h-4 w-4 text-primary" />
                        <span>{store.distance} away</span>
                      </div>

                      <div className="pt-3 flex gap-3">
                        <Link
                          to="/order"
                          className="flex-1"
                          onClick={() => {
                            localStorage.setItem("selectedStore", store.id.toString());
                          }}
                        >
                          <Button variant="secondary" className="w-full">
                            Order from this store
                          </Button>
                        </Link>
                        <a
                          href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
                            `${store.address}, ${store.city}, ${store.state} ${store.zip}`
                          )}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                        >
                          <Button variant="outline" size="icon">
                            <Navigation className="h-4 w-4" />
                          </Button>
                        </a>
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

        {/* View All Locations Link */}
        <div className="text-center mt-12">
          <Link to="/locations">
            <Button variant="outline" size="lg">
              View All 29 Locations
            </Button>
          </Link>
        </div>
      </div>
    </section>
  );
};
