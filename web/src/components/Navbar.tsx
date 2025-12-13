import { useState } from "react";
import { Link } from "react-router-dom";
import { Menu, X, ShoppingCart, User, Sun, Moon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useTheme } from "next-themes";

export const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const { theme, setTheme } = useTheme();

  const toggleTheme = () => {
    setTheme(theme === "dark" ? "light" : "dark");
  };

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-border/50 shadow-float">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2">
            <img src="/knockbites-logo.png" alt="KnockBites" className="h-10 w-10 rounded-lg dark:bg-white dark:p-0.5" />
            <span className="text-2xl font-bold">
              <span className="text-[#F97316]">Knock</span><span className="text-[#EC4899]">Bites</span>
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            <Link to="/menu" className="text-foreground hover:text-primary transition-colors">
              Menu
            </Link>
            <Link to="/locations" className="text-foreground hover:text-primary transition-colors">
              Locations
            </Link>
            <Link to="/about" className="text-foreground hover:text-primary transition-colors">
              About
            </Link>
            <Link to="/contact" className="text-foreground hover:text-primary transition-colors">
              Contact
            </Link>
          </div>

          {/* Action Buttons */}
          <div className="hidden md:flex items-center space-x-4">
            <Button
              variant="ghost"
              size="icon"
              onClick={toggleTheme}
              aria-label="Toggle theme"
              className="text-foreground hover:text-[#F97316]"
            >
              {theme === "dark" ? (
                <Sun className="h-5 w-5" />
              ) : (
                <Moon className="h-5 w-5" />
              )}
            </Button>
            <Link to="/order">
              <Button variant="ghost" size="icon" aria-label="View shopping cart">
                <ShoppingCart className="h-5 w-5" />
              </Button>
            </Link>
            <Link to="/signin">
              <Button variant="ghost" size="icon" aria-label="User account">
                <User className="h-5 w-5" />
              </Button>
            </Link>
            <Link to="/order">
              <Button className="bg-[#F97316] hover:bg-[#EA580C] text-white">
                Order Now
              </Button>
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsOpen(!isOpen)}
            className="md:hidden p-2 rounded-md hover:bg-muted transition-colors"
            aria-label={isOpen ? "Close menu" : "Open menu"}
          >
            {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isOpen && (
          <div className="md:hidden py-4 space-y-4 animate-fade-in">
            <Link
              to="/menu"
              className="block py-2 text-foreground hover:text-primary transition-colors"
              onClick={() => setIsOpen(false)}
            >
              Menu
            </Link>
            <Link
              to="/locations"
              className="block py-2 text-foreground hover:text-primary transition-colors"
              onClick={() => setIsOpen(false)}
            >
              Locations
            </Link>
            <Link
              to="/about"
              className="block py-2 text-foreground hover:text-primary transition-colors"
              onClick={() => setIsOpen(false)}
            >
              About
            </Link>
            <Link
              to="/contact"
              className="block py-2 text-foreground hover:text-primary transition-colors"
              onClick={() => setIsOpen(false)}
            >
              Contact
            </Link>
            <div className="pt-4 space-y-2">
              <Button
                variant="outline"
                className="w-full border-[#F97316] text-[#F97316]"
                onClick={() => {
                  toggleTheme();
                  setIsOpen(false);
                }}
              >
                {theme === "dark" ? (
                  <>
                    <Sun className="h-4 w-4 mr-2" />
                    Light Mode
                  </>
                ) : (
                  <>
                    <Moon className="h-4 w-4 mr-2" />
                    Dark Mode
                  </>
                )}
              </Button>
              <Link to="/signin" className="block">
                <Button variant="outline" className="w-full" onClick={() => setIsOpen(false)}>
                  Sign In
                </Button>
              </Link>
              <Link to="/order" className="block">
                <Button className="w-full bg-[#F97316] hover:bg-[#EA580C] text-white" onClick={() => setIsOpen(false)}>
                  Order Now
                </Button>
              </Link>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};
