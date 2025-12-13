import { useState } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Search, HelpCircle, Mail, Phone } from "lucide-react";
import { faqData, faqCategories } from "@/data/faqData";
import { Link } from "react-router-dom";

const FAQ = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");

  // Filter FAQs based on search and category
  const filteredFAQs = faqData.filter((faq) => {
    const matchesSearch =
      faq.question.toLowerCase().includes(searchQuery.toLowerCase()) ||
      faq.answer.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory =
      selectedCategory === "All" || faq.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  // Group FAQs by category for display
  const groupedFAQs = filteredFAQs.reduce((acc, faq) => {
    if (!acc[faq.category]) {
      acc[faq.category] = [];
    }
    acc[faq.category].push(faq);
    return acc;
  }, {} as Record<string, typeof faqData>);

  return (
    <div className="min-h-screen bg-gradient-background">
      <Navbar />

      <main className="pt-24 pb-16">
        <div className="container mx-auto px-4 max-w-4xl">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-primary/10 rounded-full mb-4">
              <HelpCircle className="h-8 w-8 text-primary" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold mb-4">
              Frequently Asked Questions
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Find answers to common questions about ordering, payments, rewards, and more.
            </p>
          </div>

          {/* Search Bar */}
          <Card className="mb-8">
            <CardContent className="pt-6">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                <Input
                  type="text"
                  placeholder="Search for answers..."
                  className="pl-10 h-12"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
            </CardContent>
          </Card>

          {/* Category Filters */}
          <div className="flex flex-wrap gap-2 mb-8">
            {faqCategories.map((category) => (
              <Badge
                key={category}
                variant={selectedCategory === category ? "default" : "outline"}
                className="cursor-pointer hover:bg-primary/80 transition-colors px-4 py-2"
                onClick={() => setSelectedCategory(category)}
              >
                {category}
              </Badge>
            ))}
          </div>

          {/* Results Count */}
          {searchQuery && (
            <p className="text-sm text-muted-foreground mb-4">
              Found {filteredFAQs.length} result{filteredFAQs.length !== 1 ? "s" : ""} for "
              {searchQuery}"
            </p>
          )}

          {/* FAQ Accordion */}
          {filteredFAQs.length > 0 ? (
            <div className="space-y-8">
              {selectedCategory === "All" ? (
                // Show grouped by category when All is selected
                Object.entries(groupedFAQs).map(([category, faqs]) => (
                  <div key={category}>
                    <h2 className="text-2xl font-bold mb-4 text-primary">{category}</h2>
                    <Accordion type="single" collapsible className="space-y-2">
                      {faqs.map((faq) => (
                        <AccordionItem
                          key={faq.id}
                          value={`faq-${faq.id}`}
                          className="border rounded-lg px-4 bg-card"
                        >
                          <AccordionTrigger className="text-left hover:no-underline">
                            <span className="font-semibold">{faq.question}</span>
                          </AccordionTrigger>
                          <AccordionContent className="text-muted-foreground leading-relaxed">
                            {faq.answer}
                          </AccordionContent>
                        </AccordionItem>
                      ))}
                    </Accordion>
                  </div>
                ))
              ) : (
                // Show flat list when a specific category is selected
                <Accordion type="single" collapsible className="space-y-2">
                  {filteredFAQs.map((faq) => (
                    <AccordionItem
                      key={faq.id}
                      value={`faq-${faq.id}`}
                      className="border rounded-lg px-4 bg-card"
                    >
                      <AccordionTrigger className="text-left hover:no-underline">
                        <span className="font-semibold">{faq.question}</span>
                      </AccordionTrigger>
                      <AccordionContent className="text-muted-foreground leading-relaxed">
                        {faq.answer}
                      </AccordionContent>
                    </AccordionItem>
                  ))}
                </Accordion>
              )}
            </div>
          ) : (
            // No Results
            <Card>
              <CardContent className="py-12 text-center">
                <Search className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                <p className="text-lg font-semibold mb-2">No results found</p>
                <p className="text-muted-foreground mb-4">
                  Try adjusting your search or browse by category
                </p>
                <Button variant="outline" onClick={() => setSearchQuery("")}>
                  Clear Search
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Contact Support Section */}
          <Card className="mt-12 bg-primary/5 border-primary/20">
            <CardContent className="pt-6">
              <h3 className="text-xl font-bold mb-4 text-center">Still have questions?</h3>
              <p className="text-center text-muted-foreground mb-6">
                Can't find the answer you're looking for? Our support team is here to help!
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/contact">
                  <Button variant="default" className="gap-2 w-full sm:w-auto">
                    <Mail className="h-4 w-4" />
                    Contact Support
                  </Button>
                </Link>
                <a href="tel:1-800-KNOCKBITES">
                  <Button variant="outline" className="gap-2 w-full sm:w-auto">
                    <Phone className="h-4 w-4" />
                    Call 1-800-KNOCKBITES
                  </Button>
                </a>
              </div>
            </CardContent>
          </Card>

          {/* Quick Links */}
          <div className="mt-8 flex flex-wrap justify-center gap-4 text-sm">
            <Link to="/privacy-policy" className="text-primary hover:underline">
              Privacy Policy
            </Link>
            <span className="text-muted-foreground">•</span>
            <Link to="/terms-of-service" className="text-primary hover:underline">
              Terms of Service
            </Link>
            <span className="text-muted-foreground">•</span>
            <Link to="/cookie-policy" className="text-primary hover:underline">
              Cookie Policy
            </Link>
            <span className="text-muted-foreground">•</span>
            <Link to="/about" className="text-primary hover:underline">
              About Us
            </Link>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default FAQ;
