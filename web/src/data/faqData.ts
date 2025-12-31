export interface FAQItem {
  id: number;
  question: string;
  answer: string;
  category: string;
}

export const faqCategories = [
  "All",
  "Ordering",
  "Payment",
  "Account",
  "Rewards",
  "Locations",
  "General",
];

export const faqData: FAQItem[] = [
  // Ordering
  {
    id: 1,
    category: "Ordering",
    question: "How do I place an order?",
    answer:
      "You can place an order by visiting the Order page, selecting your preferred location, browsing our menu, adding items to your cart, and proceeding to checkout. You can pay online or at the store when you pick up your order.",
  },
  {
    id: 2,
    category: "Ordering",
    question: "Can I customize my order?",
    answer:
      "Yes! When adding an item to your cart, you'll see a customization modal where you can add or remove ingredients, select options, and add special instructions.",
  },
  {
    id: 3,
    category: "Ordering",
    question: "How long does it take to prepare my order?",
    answer:
      "Most orders are ready within 10-15 minutes. You'll receive a notification via email or SMS when your order is ready for pickup. Preparation time may vary during peak hours.",
  },
  {
    id: 4,
    category: "Ordering",
    question: "Can I cancel or modify my order?",
    answer:
      "You can cancel or modify your order before it enters preparation. Once preparation has started, changes cannot be made. Contact the store directly if you need immediate assistance.",
  },
  {
    id: 5,
    category: "Ordering",
    question: "Do you offer delivery?",
    answer:
      "Currently, we only offer pickup service at our 29 locations across New York. Delivery options may be available in the future.",
  },

  // Payment
  {
    id: 6,
    category: "Payment",
    question: "What payment methods do you accept?",
    answer:
      "We accept credit cards (Visa, Mastercard, American Express, Discover), debit cards, Apple Pay, Google Pay, and cash at pickup. All online payments are securely processed through Stripe.",
  },
  {
    id: 7,
    category: "Payment",
    question: "Is it safe to pay online?",
    answer:
      "Yes, absolutely. All online payments are processed through Stripe, a PCI-compliant payment processor. Your payment information is encrypted and never stored on our servers.",
  },
  {
    id: 8,
    category: "Payment",
    question: "Can I save my payment method for future orders?",
    answer:
      "Yes, you can securely save your payment methods in your account settings for faster checkout on future orders.",
  },
  {
    id: 9,
    category: "Payment",
    question: "How do refunds work?",
    answer:
      "Refunds are processed to your original payment method within 5-10 business days. If you're not satisfied with your order, please contact us within 24 hours for a refund or replacement.",
  },
  {
    id: 10,
    category: "Payment",
    question: "Do you charge sales tax?",
    answer:
      "Yes, applicable sales tax is added to your order total at checkout based on your pickup location.",
  },

  // Account
  {
    id: 11,
    category: "Account",
    question: "Do I need an account to order?",
    answer:
      "Yes, you need to create a free account to place orders. This allows you to track your orders, save favorites, earn rewards, and manage your preferences.",
  },
  {
    id: 12,
    category: "Account",
    question: "How do I reset my password?",
    answer:
      "Click the 'Forgot Password' link on the sign-in page. Enter your email address, and we'll send you an 8-digit verification code to reset your password.",
  },
  {
    id: 13,
    category: "Account",
    question: "Can I change my email address?",
    answer:
      "Yes, you can update your email address in your account settings. For security, you'll need to verify your new email address.",
  },
  {
    id: 14,
    category: "Account",
    question: "How do I delete my account?",
    answer:
      "To delete your account, go to Account Settings and select 'Delete Account'. Please note that this action is permanent and will remove all your order history and rewards points.",
  },

  // Rewards
  {
    id: 15,
    category: "Rewards",
    question: "How does the rewards program work?",
    answer:
      "Earn 1 point for every dollar spent. Points can be redeemed for discounts on future orders. You'll also get exclusive offers and birthday rewards!",
  },
  {
    id: 16,
    category: "Rewards",
    question: "Do my rewards points expire?",
    answer:
      "Points expire after 12 months of account inactivity. Keep ordering to keep your points active!",
  },
  {
    id: 17,
    category: "Rewards",
    question: "Can I use multiple coupons on one order?",
    answer:
      "Only one coupon or promotional code can be applied per order. Choose the one that gives you the best discount!",
  },
  {
    id: 18,
    category: "Rewards",
    question: "How do I redeem my rewards points?",
    answer:
      "During checkout, you'll see an option to apply your rewards points as a discount. Select how many points you want to use, and the discount will be applied to your order total.",
  },

  // Locations
  {
    id: 19,
    category: "Locations",
    question: "How many locations do you have?",
    answer:
      "We have 29 locations across New York, all open 24 hours a day, 7 days a week. Visit our Locations page to find the nearest store to you.",
  },
  {
    id: 20,
    category: "Locations",
    question: "Are all locations open 24/7?",
    answer:
      "Yes! All KnockBites locations are open 24 hours a day, every day of the year, including holidays. We're here whenever you need us.",
  },
  {
    id: 21,
    category: "Locations",
    question: "Can I pick up my order from any location?",
    answer:
      "You must pick up your order from the location you selected during checkout. Orders cannot be transferred between locations.",
  },
  {
    id: 22,
    category: "Locations",
    question: "Do all locations have the same menu?",
    answer:
      "While most items are available at all locations, some menu items may vary by store. Check the menu for your selected location when ordering.",
  },

  // General
  {
    id: 23,
    category: "General",
    question: "Do you accommodate dietary restrictions?",
    answer:
      "Yes! You can filter our menu by dietary preferences (vegetarian, vegan, gluten-free). Always inform staff of allergies when picking up your order.",
  },
  {
    id: 24,
    category: "General",
    question: "How can I provide feedback about my order?",
    answer:
      "We'd love to hear from you! You can leave a review after completing your order, or contact us directly at support@knockbites.com.",
  },
  {
    id: 25,
    category: "General",
    question: "Do you cater events?",
    answer:
      "Yes, we offer catering services for events of all sizes. Please contact your nearest location at least 24 hours in advance to discuss catering options and pricing.",
  },
  {
    id: 26,
    category: "General",
    question: "Is nutritional information available?",
    answer:
      "Nutritional information for our menu items is available upon request. Please contact your local store or email us at nutrition@knockbites.com.",
  },
  {
    id: 27,
    category: "General",
    question: "Can I order in advance for a specific pickup time?",
    answer:
      "Yes! When placing your order, you can schedule a pickup time up to 24 hours in advance. Your order will be prepared just before your selected time.",
  },
  {
    id: 28,
    category: "General",
    question: "What if there's a problem with my order?",
    answer:
      "We're committed to your satisfaction. If there's any issue with your order, please contact us within 24 hours at support@knockbites.com or call 1-800-KNOCKBITES, and we'll make it right.",
  },
];
