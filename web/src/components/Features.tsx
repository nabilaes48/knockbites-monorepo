import { Clock, Users, Gift } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export const Features = () => {
  const features = [
    {
      icon: Clock,
      title: "Order Ahead",
      description: "Skip the wait by ordering online. Your food will be ready when you arrive.",
      color: "text-[#FF8C42]",
      bgColor: "bg-[#FF8C42]/10",
    },
    {
      icon: Users,
      title: "Skip the Line",
      description: "Walk straight to pickup. No waiting in line, just grab your order and go.",
      color: "text-[#FF8C42]",
      bgColor: "bg-[#FF8C42]/10",
    },
    {
      icon: Gift,
      title: "Earn Rewards",
      description: "Every purchase earns points. Redeem for free food and exclusive deals.",
      color: "text-[#4CAF50]",
      bgColor: "bg-[#4CAF50]/10",
    },
  ];

  return (
    <section className="py-20 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Why Choose <span className="text-[#FF8C42]">KnockBites</span>?
          </h2>
          <p className="text-xl text-muted-foreground">
            Fresh food, fast service, and rewards that keep you coming back
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <Card
              key={index}
              className="border-2 hover:shadow-strong transition-all hover:-translate-y-1 duration-300"
            >
              <CardHeader>
                <div className={`w-16 h-16 ${feature.bgColor} rounded-2xl flex items-center justify-center mb-4`}>
                  <feature.icon className={`h-8 w-8 ${feature.color}`} />
                </div>
                <CardTitle className="text-2xl">{feature.title}</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-base">
                  {feature.description}
                </CardDescription>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
};
