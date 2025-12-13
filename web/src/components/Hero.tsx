import { Button } from "@/components/ui/button";
import { ArrowRight, Clock } from "lucide-react";
import { Link } from "react-router-dom";
import heroImage from "@/assets/hero-food.jpg";

export const Hero = () => {
  // Simple time check for "Open Now" status
  const currentHour = new Date().getHours();
  const isOpen = true; // 24/7 deli is always open!

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
      {/* Background Image with Overlay */}
      <div className="absolute inset-0 z-0">
        <img
          src={heroImage}
          alt="Delicious deli sandwiches from KnockBites"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-background/95 via-background/85 to-background/50" />
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 z-10">
        <div className="max-w-2xl animate-fade-in bg-background/40 backdrop-blur-sm p-8 rounded-2xl shadow-float border border-border/30">
          {/* Operating Status Badge */}
          <div className="inline-flex items-center gap-2 bg-accent/20 border border-accent px-4 py-2 rounded-full mb-6">
            <Clock className="h-4 w-4 text-accent" />
            <span className="text-sm font-semibold text-accent">
              {isOpen ? "Open Now - 24/7" : "Opens at 6:00 AM"}
            </span>
          </div>

          <h1 className="text-5xl md:text-7xl font-bold mb-6 text-foreground leading-tight">
            Fresh Deli Favorites,
            <br />
            <span className="bg-gradient-hero bg-clip-text text-transparent">
              Ready When You Are
            </span>
          </h1>
          <p className="text-xl md:text-2xl mb-8 text-muted-foreground">
            Order ahead from 29 locations across New York
          </p>

          <div className="flex flex-col sm:flex-row gap-4 mb-8">
            <Link to="/order">
              <Button variant="secondary" size="xl" className="group w-full sm:w-auto">
                Order Now
                <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </Button>
            </Link>
            <Button variant="outline" size="xl">
              View Menu
            </Button>
          </div>

          {/* Stats */}
          <div className="flex flex-wrap gap-8 pt-8 border-t border-border">
            <div>
              <div className="text-3xl font-bold text-primary">29</div>
              <div className="text-sm text-muted-foreground">Locations</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-secondary">24/7</div>
              <div className="text-sm text-muted-foreground">Always Open</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-accent">Fresh</div>
              <div className="text-sm text-muted-foreground">Daily</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
