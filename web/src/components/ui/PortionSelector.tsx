import { cn } from "@/lib/utils";

export type PortionLevel = "none" | "light" | "regular" | "extra";

interface PortionSelectorProps {
  value: PortionLevel;
  onChange: (portion: PortionLevel) => void;
  pricing?: {
    none: number;
    light: number;
    regular: number;
    extra: number;
  };
  showPrices?: boolean;
  disabled?: boolean;
  className?: string;
}

export const PortionSelector = ({
  value,
  onChange,
  pricing,
  showPrices = false,
  disabled = false,
  className,
}: PortionSelectorProps) => {
  const portions: { level: PortionLevel; label: string; emoji?: string }[] = [
    { level: "none", label: "None", emoji: "○" },
    { level: "light", label: "Light", emoji: "◔" },
    { level: "regular", label: "Regular", emoji: "◑" },
    { level: "extra", label: "Extra", emoji: "●" },
  ];

  const formatPrice = (price: number) => {
    if (price === 0) return "";
    return price > 0 ? `+$${price.toFixed(2)}` : `-$${Math.abs(price).toFixed(2)}`;
  };

  return (
    <div className={cn("flex gap-2", className)}>
      {portions.map((portion) => {
        const isSelected = value === portion.level;
        const price = pricing?.[portion.level] ?? 0;

        return (
          <button
            key={portion.level}
            type="button"
            onClick={() => !disabled && onChange(portion.level)}
            disabled={disabled}
            className={cn(
              "flex-1 px-3 py-2 rounded-lg border-2 transition-all text-sm font-medium",
              "hover:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
              isSelected
                ? "border-primary bg-primary/10 text-primary"
                : "border-muted-foreground/20 bg-background hover:bg-muted/50",
              disabled && "opacity-50 cursor-not-allowed"
            )}
          >
            <div className="flex flex-col items-center gap-0.5">
              <span className="text-lg leading-none">{portion.emoji}</span>
              <span className="leading-none">{portion.label}</span>
              {showPrices && price !== 0 && (
                <span className="text-xs text-muted-foreground leading-none">
                  {formatPrice(price)}
                </span>
              )}
            </div>
          </button>
        );
      })}
    </div>
  );
};

interface PortionSelectorCompactProps extends PortionSelectorProps {
  ingredientName: string;
}

export const PortionSelectorRow = ({
  ingredientName,
  value,
  onChange,
  pricing,
  showPrices = false,
  disabled = false,
}: PortionSelectorCompactProps) => {
  return (
    <div className="flex items-center gap-4 py-2">
      <div className="flex-1 min-w-0">
        <p className="font-medium truncate">{ingredientName}</p>
        {showPrices && pricing && pricing[value] > 0 && (
          <p className="text-xs text-muted-foreground">
            +${pricing[value].toFixed(2)}
          </p>
        )}
      </div>
      <PortionSelector
        value={value}
        onChange={onChange}
        pricing={pricing}
        showPrices={false}
        disabled={disabled}
        className="flex-shrink-0"
      />
    </div>
  );
};
