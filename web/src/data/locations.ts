// KnockBites store locations in New York
// LAUNCH PHASE: Single store - Highland Mills Snack Shop Inc (Jay's Deli)
// Will expand to additional stores in future phases

export interface Location {
  id: number;
  name: string;
  tradeName?: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  phone: string;
  hours: string;
  isOpen: boolean;
  distance: string;
  coords: { lat: number; lng: number };
  email?: string;
  owner?: string;
  county?: string;
  type?: string;
  ein?: string;
  lotteryRetailerId?: string;
  districtManager?: string;
  incorporationDate?: string;
}

export const locations: Location[] = [
  {
    id: 1,
    name: "Highland Mills Snack Shop Inc",
    tradeName: "Jay's Deli",
    address: "534 NY-32",
    city: "Highland Mills",
    state: "NY",
    zip: "10930",
    phone: "(845) 928-2803",
    hours: "M-Sat: 7 AM - 8 PM, Sun: 7 AM - 5 PM",
    isOpen: true,
    distance: "0 miles",
    coords: { lat: 41.3501, lng: -74.1243 },
    email: "jaysdeli@cpetromgmt.com",
    owner: "Ibrahim Jamal",
    county: "Orange",
    type: "C-Store / Deli",
    ein: "99-2158691",
    lotteryRetailerId: "115562",
    districtManager: "Hamza Gewida",
    incorporationDate: "03/22/2024",
  },
];

// Future expansion stores will be added here
