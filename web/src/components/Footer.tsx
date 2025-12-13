import { Link } from "react-router-dom";
import { Facebook, Instagram, Twitter, Mail, Phone, MapPin } from "lucide-react";

export const Footer = () => {
  return (
    <footer className="bg-gray-900 text-gray-100">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Brand */}
          <div>
            <div className="flex items-center space-x-2 mb-4">
              <img src="/knockbites-logo.png" alt="KnockBites" className="h-10 w-10 rounded-lg bg-white p-0.5" />
              <h3 className="text-2xl font-bold">
                <span className="text-[#FBBF24]">Knock</span><span className="text-[#EC4899]">Bites</span>
              </h3>
            </div>
            <p className="text-gray-400 mb-4">
              Fresh deli favorites made to order, 24/7. Order online for pickup from our locations.
            </p>
            <div className="flex space-x-4">
              <a
                href="https://facebook.com/knockbites"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-400 hover:text-[#F97316] transition-colors"
                aria-label="Follow us on Facebook"
              >
                <Facebook className="h-5 w-5" />
              </a>
              <a
                href="https://instagram.com/knockbites"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-400 hover:text-[#F97316] transition-colors"
                aria-label="Follow us on Instagram"
              >
                <Instagram className="h-5 w-5" />
              </a>
              <a
                href="https://twitter.com/knockbites"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-400 hover:text-[#F97316] transition-colors"
                aria-label="Follow us on Twitter"
              >
                <Twitter className="h-5 w-5" />
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-gray-100">Quick Links</h4>
            <ul className="space-y-2">
              <li>
                <Link to="/menu" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Menu
                </Link>
              </li>
              <li>
                <Link to="/locations" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Locations
                </Link>
              </li>
              <li>
                <Link to="/about" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  About Us
                </Link>
              </li>
              <li>
                <Link to="/contact" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Contact
                </Link>
              </li>
            </ul>
          </div>

          {/* Customer Service */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-gray-100">Customer Service</h4>
            <ul className="space-y-2">
              <li>
                <Link to="/faq" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  FAQ
                </Link>
              </li>
              <li>
                <Link to="/customer/dashboard" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Order History
                </Link>
              </li>
              <li>
                <Link to="/privacy-policy" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link to="/terms-of-service" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link to="/cookie-policy" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  Cookie Policy
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-gray-100">Contact Us</h4>
            <ul className="space-y-3">
              <li className="flex items-start gap-2">
                <Phone className="h-5 w-5 mt-0.5 flex-shrink-0 text-[#F97316]" />
                <a href="tel:1-800-KNOCKBITES" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  1-800-KNOCKBITES
                </a>
              </li>
              <li className="flex items-start gap-2">
                <Mail className="h-5 w-5 mt-0.5 flex-shrink-0 text-[#F97316]" />
                <a href="mailto:support@knockbites.com" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  support@knockbites.com
                </a>
              </li>
              <li className="flex items-start gap-2">
                <MapPin className="h-5 w-5 mt-0.5 flex-shrink-0 text-[#F97316]" />
                <Link to="/locations" className="text-gray-400 hover:text-[#F97316] transition-colors">
                  View our locations
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-700 mt-8 pt-8 text-center text-gray-500">
          <p>&copy; {new Date().getFullYear()} KnockBites. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};
