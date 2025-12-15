import { useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { Button } from "@/components/ui/button";
import { Plus, Minus, Maximize2, LocateFixed } from "lucide-react";

// Fix for default marker icons in React-Leaflet
// eslint-disable-next-line @typescript-eslint/no-explicit-any
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

// Custom map component to handle center updates
function MapController({
  center,
  zoom,
  onMapReady,
  onZoomChange
}: {
  center: [number, number];
  zoom: number;
  onMapReady: (map: L.Map) => void;
  onZoomChange: (zoom: number) => void;
}) {
  const map = useMap();

  useEffect(() => {
    onMapReady(map);

    // Track zoom changes
    const handleZoomEnd = () => {
      onZoomChange(map.getZoom());
    };

    map.on('zoomend', handleZoomEnd);

    return () => {
      map.off('zoomend', handleZoomEnd);
    };
  }, [map, onMapReady, onZoomChange]);

  useEffect(() => {
    map.setView(center, zoom);
  }, [center, zoom, map]);

  return null;
}

interface Location {
  id: number;
  name: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  phone: string;
  hours: string;
  isOpen: boolean;
  distance: string;
  coords: { lat: number; lng: number };
}

interface LocationMapProps {
  locations: Location[];
  selectedLocation: number | null;
  onLocationSelect: (id: number) => void;
}

export const LocationMap = ({
  locations,
  selectedLocation,
  onLocationSelect,
}: LocationMapProps) => {
  const mapRef = useRef<L.Map | null>(null);
  const [mapInstance, setMapInstance] = useState<L.Map | null>(null);
  const [currentZoom, setCurrentZoom] = useState(8);
  const [userLocation, setUserLocation] = useState<[number, number] | null>(null);
  const [isLoadingLocation, setIsLoadingLocation] = useState(true);

  // Get user's current location on mount
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setUserLocation([latitude, longitude]);
          setIsLoadingLocation(false);
        },
        (error) => {
          console.error("Error getting location:", error);
          setIsLoadingLocation(false);
        }
      );
    } else {
      setIsLoadingLocation(false);
    }
  }, []);

  // Find closest stores to user location
  const getClosestStores = (userLoc: [number, number], count: number = 5) => {
    return locations
      .map((loc) => {
        const distance = Math.sqrt(
          Math.pow(loc.coords.lat - userLoc[0], 2) +
          Math.pow(loc.coords.lng - userLoc[1], 2)
        );
        return { ...loc, calculatedDistance: distance };
      })
      .sort((a, b) => a.calculatedDistance - b.calculatedDistance)
      .slice(0, count);
  };

  // Auto-fit map to show closest stores
  useEffect(() => {
    if (mapInstance && userLocation && !selectedLocation) {
      const closestStores = locations
        .map((loc) => {
          const distance = Math.sqrt(
            Math.pow(loc.coords.lat - userLocation[0], 2) +
            Math.pow(loc.coords.lng - userLocation[1], 2)
          );
          return { ...loc, calculatedDistance: distance };
        })
        .sort((a, b) => a.calculatedDistance - b.calculatedDistance)
        .slice(0, 5);
      const bounds = L.latLngBounds([
        userLocation,
        ...closestStores.map(s => [s.coords.lat, s.coords.lng] as [number, number])
      ]);
      mapInstance.fitBounds(bounds, { padding: [50, 50] });
    }
  }, [mapInstance, userLocation, selectedLocation, locations]);

  // Calculate center based on all locations or selected location
  const getMapCenter = (): [number, number] => {
    if (selectedLocation) {
      const location = locations.find((loc) => loc.id === selectedLocation);
      if (location) {
        return [location.coords.lat, location.coords.lng];
      }
    }
    // Use user location if available
    if (userLocation) {
      return userLocation;
    }
    // Default to center of New York state (Hudson Valley area)
    return [41.7, -73.9];
  };

  const getMapZoom = () => {
    if (selectedLocation) return 13;
    if (userLocation) return 11;
    return 8;
  };

  // Map control handlers
  const handleZoomIn = () => {
    if (mapInstance) {
      mapInstance.zoomIn();
    }
  };

  const handleZoomOut = () => {
    if (mapInstance) {
      mapInstance.zoomOut();
    }
  };

  const handleResetView = () => {
    if (mapInstance) {
      mapInstance.setView(getMapCenter(), getMapZoom());
    }
  };

  const handleLocateMe = () => {
    if (mapInstance) {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { latitude, longitude } = position.coords;
            mapInstance.setView([latitude, longitude], 13);
          },
          (error) => {
            console.error("Error getting location:", error);
            alert("Unable to get your location. Please enable location services.");
          }
        );
      } else {
        alert("Geolocation is not supported by your browser.");
      }
    }
  };

  // Create custom icon for selected location
  const createCustomIcon = (isSelected: boolean) => {
    return L.divIcon({
      className: "custom-marker",
      html: `<div class="relative">
        <svg class="w-8 h-8 ${
          isSelected ? "text-orange-500" : "text-blue-500"
        }" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 0c-4.198 0-8 3.403-8 7.602 0 4.198 3.469 9.21 8 16.398 4.531-7.188 8-12.2 8-16.398 0-4.199-3.801-7.602-8-7.602zm0 11c-1.657 0-3-1.343-3-3s1.343-3 3-3 3 1.343 3 3-1.343 3-3 3z"/>
        </svg>
      </div>`,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
      popupAnchor: [0, -32],
    });
  };

  return (
    <div className="w-full h-full rounded-2xl overflow-hidden relative">
      <MapContainer
        center={getMapCenter()}
        zoom={getMapZoom()}
        scrollWheelZoom={true}
        className="w-full h-full"
        ref={mapRef}
      >
        <MapController
          center={getMapCenter()}
          zoom={getMapZoom()}
          onMapReady={setMapInstance}
          onZoomChange={setCurrentZoom}
        />

        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* User location marker */}
        {userLocation && (
          <Marker
            position={userLocation}
            icon={L.divIcon({
              className: "user-location-marker",
              html: `<div class="relative flex items-center justify-center">
                <div class="absolute w-12 h-12 bg-blue-400 rounded-full opacity-30"></div>
                <div class="relative w-8 h-8 bg-blue-600 border-4 border-white rounded-full shadow-lg flex items-center justify-center">
                  <div class="w-3 h-3 bg-white rounded-full"></div>
                </div>
              </div>`,
              iconSize: [32, 32],
              iconAnchor: [16, 16],
            })}
          >
            <Popup>
              <div className="p-2">
                <h3 className="font-bold text-sm">Your Location</h3>
                <p className="text-xs text-gray-600">You are here</p>
              </div>
            </Popup>
          </Marker>
        )}

        {locations.map((location) => (
          <Marker
            key={location.id}
            position={[location.coords.lat, location.coords.lng]}
            icon={createCustomIcon(selectedLocation === location.id)}
            eventHandlers={{
              click: () => onLocationSelect(location.id),
            }}
          >
            <Popup>
              <div className="p-2 min-w-[200px]">
                <h3 className="font-bold text-lg mb-2">{location.name}</h3>
                <div className="space-y-1 text-sm">
                  <p className="text-gray-600">
                    {location.address}
                    <br />
                    {location.city}, {location.state} {location.zip}
                  </p>
                  <p className="text-gray-600">
                    <strong>Phone:</strong> {location.phone}
                  </p>
                  <p className="text-gray-600">
                    <strong>Hours:</strong> {location.hours}
                  </p>
                  <p className="text-blue-600 font-semibold">{location.distance} away</p>
                  {location.isOpen && (
                    <span className="inline-block bg-green-100 text-green-800 text-xs px-2 py-1 rounded">
                      Open Now
                    </span>
                  )}
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Map Controls */}
      <div className="absolute top-4 right-4 z-[1000] flex flex-col gap-2">
        <Button
          size="icon"
          className="shadow-2xl bg-white hover:bg-gray-100 border-2 border-gray-300 text-gray-800 hover:text-gray-900 h-10 w-10"
          onClick={handleZoomIn}
          disabled={currentZoom >= 18}
          aria-label="Zoom in"
        >
          <Plus className="h-5 w-5 font-bold" />
        </Button>

        <Button
          size="icon"
          className="shadow-2xl bg-white hover:bg-gray-100 border-2 border-gray-300 text-gray-800 hover:text-gray-900 h-10 w-10"
          onClick={handleZoomOut}
          disabled={currentZoom <= 1}
          aria-label="Zoom out"
        >
          <Minus className="h-5 w-5 font-bold" />
        </Button>

        <Button
          size="icon"
          className="shadow-2xl bg-white hover:bg-gray-100 border-2 border-gray-300 text-gray-800 hover:text-gray-900 h-10 w-10"
          onClick={handleResetView}
          aria-label="Reset view"
        >
          <Maximize2 className="h-5 w-5 font-bold" />
        </Button>

        <Button
          size="icon"
          className="shadow-2xl bg-blue-600 hover:bg-blue-700 border-2 border-blue-800 text-white h-10 w-10"
          onClick={handleLocateMe}
          aria-label="Find my location"
        >
          <LocateFixed className="h-5 w-5" />
        </Button>
      </div>
    </div>
  );
};
