import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus } from "lucide-react";

const menuCategories = [
  {
    id: "burgers",
    name: "Burgers",
    items: [
      {
        id: 1,
        name: "Classic Cheeseburger",
        description: "1/3 lb beef patty, American cheese, lettuce, tomato, onion, pickles",
        price: "$8.99",
        image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&h=500&fit=crop",
        badges: ["Popular"],
      },
      {
        id: 2,
        name: "Bacon Deluxe Burger",
        description: "Double beef patty, crispy bacon, cheddar, BBQ sauce",
        price: "$11.99",
        image: "https://images.unsplash.com/photo-1550547660-d9450f859349?w=500&h=500&fit=crop",
        badges: ["Popular"],
      },
    ],
  },
  {
    id: "sandwiches",
    name: "Sandwiches",
    items: [
      {
        id: 3,
        name: "Turkey Club",
        description: "Roasted turkey, bacon, lettuce, tomato, mayo on toasted wheat",
        price: "$9.49",
        image: "https://images.unsplash.com/photo-1619894991209-e573b7d6919b?w=500&h=500&fit=crop",
        badges: ["Bestseller"],
      },
      {
        id: 4,
        name: "Philly Cheesesteak",
        description: "Thinly sliced ribeye, grilled onions, peppers, provolone",
        price: "$10.99",
        image: "https://images.unsplash.com/photo-1619740455993-a42b3c20e777?w=500&h=500&fit=crop",
        badges: [],
      },
    ],
  },
  {
    id: "salads",
    name: "Salads",
    items: [
      {
        id: 5,
        name: "Caesar Salad",
        description: "Romaine lettuce, parmesan, croutons, Caesar dressing",
        price: "$7.99",
        image: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=500&h=500&fit=crop",
        badges: ["Vegetarian"],
      },
      {
        id: 6,
        name: "Grilled Chicken Salad",
        description: "Mixed greens, grilled chicken, tomatoes, cucumbers, choice of dressing",
        price: "$9.99",
        image: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&h=500&fit=crop",
        badges: [],
      },
    ],
  },
  {
    id: "desserts",
    name: "Desserts",
    items: [
      {
        id: 7,
        name: "Chocolate Brownie",
        description: "Warm fudge brownie with vanilla ice cream",
        price: "$4.99",
        image: "https://images.unsplash.com/photo-1607920591413-4ec007e70023?w=500&h=500&fit=crop",
        badges: [],
      },
    ],
  },
  {
    id: "beverages",
    name: "Beverages",
    items: [
      {
        id: 8,
        name: "Fresh Lemonade",
        description: "House-made with real lemons",
        price: "$2.99",
        image: "https://images.unsplash.com/photo-1523677011781-c91d1eba394e?w=500&h=500&fit=crop",
        badges: [],
      },
    ],
  },
];

export const FeaturedItems = () => {
  const [activeCategory, setActiveCategory] = useState("burgers");

  return (
    <section className="py-20 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 animate-fade-in">
          <h2 className="text-4xl md:text-5xl font-bold mb-4 text-foreground">
            Our <span className="text-[#FF8C42]">Menu</span>
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Fresh deli favorites made to order, 24/7
          </p>
        </div>

        <Tabs value={activeCategory} onValueChange={setActiveCategory} className="w-full">
          <TabsList className="grid w-full grid-cols-5 mb-8 h-auto p-1">
            {menuCategories.map((category) => (
              <TabsTrigger
                key={category.id}
                value={category.id}
                className="text-sm md:text-base py-3"
              >
                {category.name}
              </TabsTrigger>
            ))}
          </TabsList>

          {menuCategories.map((category) => (
            <TabsContent key={category.id} value={category.id} className="mt-0">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {category.items.map((item) => (
                  <Card
                    key={item.id}
                    className="overflow-hidden shadow-soft hover:shadow-strong transition-all duration-300 hover:-translate-y-1"
                  >
                    <div className="relative h-48 overflow-hidden">
                      <img
                        src={item.image}
                        alt={item.name}
                        className="w-full h-full object-cover transition-transform duration-300 hover:scale-110"
                      />
                      {item.badges.length > 0 && (
                        <div className="absolute top-2 right-2">
                          {item.badges.map((badge, index) => (
                            <Badge
                              key={index}
                              className="bg-[#FF8C42] text-white"
                            >
                              {badge}
                            </Badge>
                          ))}
                        </div>
                      )}
                    </div>
                    <CardContent className="p-5">
                      <h3 className="text-lg font-bold text-foreground mb-2">{item.name}</h3>
                      <p className="text-sm text-muted-foreground mb-4 line-clamp-2">
                        {item.description}
                      </p>
                      <div className="flex items-center justify-between">
                        <span className="text-2xl font-bold text-[#FF8C42]">{item.price}</span>
                        <Button size="sm" className="bg-[#FF8C42] hover:bg-[#F57C00] text-white">
                          <Plus className="h-4 w-4 mr-1" />
                          Add
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>
          ))}
        </Tabs>

        <div className="text-center mt-12">
          <Button size="lg" className="bg-gradient-to-r from-[#FF8C42] to-[#E84393] hover:from-[#F57C00] hover:to-[#D63384] text-white font-semibold shadow-md hover:shadow-lg transition-all">
            View Full Menu
          </Button>
        </div>
      </div>
    </section>
  );
};
