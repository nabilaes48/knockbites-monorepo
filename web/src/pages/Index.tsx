import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { Features } from "@/components/Features";
import { StoreLocator } from "@/components/StoreLocator";
import { FeaturedItems } from "@/components/FeaturedItems";
import { Footer } from "@/components/Footer";

const Index = () => {
  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />
      <Hero />
      <Features />
      <StoreLocator />
      <FeaturedItems />
      <Footer />
    </div>
  );
};

export default Index;
