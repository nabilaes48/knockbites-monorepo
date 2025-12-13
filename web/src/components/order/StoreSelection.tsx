import { useState } from "react";
import { MapPin, Phone, Clock, Navigation, Search } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { locations } from "@/data/locations";

// Use real KnockBites store locations
const stores = locations;

interface StoreSelectionProps {
  onSelectStore: (storeId: number) => void;
}

export const StoreSelection = ({ onSelectStore }: StoreSelectionProps) => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedStoreId, setSelectedStoreId] = useState<number | null>(null);

  const filteredStores = stores.filter(
    (store) =>
      store.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
      store.zip.includes(searchQuery)
  );

  const handleSelectStore = (storeId: number) => {
    setSelectedStoreId(storeId);
  };

  const handleContinue = () => {
    if (selectedStoreId) {
      // Save selected store to localStorage for persistence
      localStorage.setItem("selectedStore", selectedStoreId.toString());
      onSelectStore(selectedStoreId);
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h1 className="text-3xl md:text-4xl font-bold mb-3">
          Choose Your <span className="text-primary">Location</span>
        </h1>
        <p className="text-lg text-muted-foreground">
          Select a store to start your order
        </p>
      </div>

      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
          <Input
            type="text"
            placeholder="Search by city, ZIP code, or address..."
            className="pl-10 h-12"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Store Cards */}
      <div className="space-y-4 mb-6">
        {filteredStores.length > 0 ? (
          filteredStores.map((store) => (
            <Card
              key={store.id}
              className={`transition-all cursor-pointer hover:shadow-medium ${
                selectedStoreId === store.id ? "ring-2 ring-primary shadow-medium" : ""
              }`}
              onClick={() => handleSelectStore(store.id)}
            >
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-xl mb-2">{store.name}</CardTitle>
                    <div className="space-y-2 text-sm text-muted-foreground">
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-primary" />
                        <span>
                          {store.address}, {store.city}, {store.state} {store.zip}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Phone className="h-4 w-4 text-primary" />
                        <span>{store.phone}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Navigation className="h-4 w-4 text-primary" />
                        <span>{store.distance} away</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    {store.isOpen && (
                      <Badge variant="default" className="bg-accent">
                        <Clock className="h-3 w-3 mr-1" />
                        Open Now
                      </Badge>
                    )}
                    {selectedStoreId === store.id && (
                      <Badge variant="default" className="bg-primary">
                        Selected
                      </Badge>
                    )}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-between text-sm text-muted-foreground">
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4" />
                    <span>{store.hours}</span>
                  </div>
                  <Button
                    variant={selectedStoreId === store.id ? "default" : "outline"}
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleSelectStore(store.id);
                    }}
                  >
                    {selectedStoreId === store.id ? "Selected" : "Select Store"}
                  </Button>
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

      {/* Continue Button */}
      {selectedStoreId && (
        <div className="flex justify-center">
          <Button
            variant="secondary"
            size="lg"
            onClick={handleContinue}
            className="px-12"
          >
            Continue to Menu
          </Button>
        </div>
      )}
    </div>
  );
};
