import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { RewardsTransaction } from "@/types/rewards";
import { ArrowUpRight, ArrowDownRight, Gift, Users, Clock } from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface RewardsHistoryProps {
  transactions: RewardsTransaction[];
}

const getTransactionIcon = (type: RewardsTransaction["type"]) => {
  switch (type) {
    case "earned":
      return <ArrowUpRight className="h-4 w-4 text-green-500" />;
    case "redeemed":
      return <ArrowDownRight className="h-4 w-4 text-red-500" />;
    case "bonus":
      return <Gift className="h-4 w-4 text-blue-500" />;
    case "referral":
      return <Users className="h-4 w-4 text-purple-500" />;
    case "expired":
      return <Clock className="h-4 w-4 text-gray-500" />;
    default:
      return null;
  }
};

const getTransactionColor = (type: RewardsTransaction["type"]) => {
  switch (type) {
    case "earned":
      return "text-green-600";
    case "redeemed":
      return "text-red-600";
    case "bonus":
      return "text-blue-600";
    case "referral":
      return "text-purple-600";
    case "expired":
      return "text-gray-600";
    default:
      return "";
  }
};

export const RewardsHistory = ({ transactions }: RewardsHistoryProps) => {
  if (transactions.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            <p>No transaction history yet.</p>
            <p className="text-sm mt-1">Start earning points by placing orders!</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Activity</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {transactions.slice(0, 10).map((transaction) => (
            <div
              key={transaction.id}
              className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent/50 transition-colors"
            >
              <div className="flex items-center gap-3 flex-1">
                <div className="p-2 bg-accent rounded-full">
                  {getTransactionIcon(transaction.type)}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm">{transaction.description}</p>
                  <p className="text-xs text-muted-foreground">
                    {formatDistanceToNow(new Date(transaction.createdAt), { addSuffix: true })}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className={`font-bold ${getTransactionColor(transaction.type)}`}>
                  {transaction.type === "redeemed" ? "-" : "+"}
                  {Math.abs(transaction.points)}
                </p>
                <Badge variant="outline" className="text-xs capitalize mt-1">
                  {transaction.type}
                </Badge>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
};
