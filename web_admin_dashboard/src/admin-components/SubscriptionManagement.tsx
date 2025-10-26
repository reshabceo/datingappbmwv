import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Badge } from "./ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "./ui/sheet";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { CheckCircle, XCircle, Clock, Users, DollarSign, TrendingUp, CreditCard, Eye, Search, Plus } from 'lucide-react';
import { supabase } from "../admin-integrations/supabase/client";

interface SubscriptionManagementProps {
  isDarkMode: boolean;
}

interface Subscription {
  id: string;
  user_id: string;
  plan: {
    name: string;
    price_monthly: number;
  };
  status: string;
  current_period_start: string;
  current_period_end: string;
  created_at: string;
  stripe_subscription_id?: string;
  canceled_at?: string;
}

interface SubscriptionPlan {
  id: string;
  name: string;
  price_monthly: number;
  price_yearly?: number;
  features: string[];
  is_active: boolean;
}

interface RevenueData {
  date: string;
  total_revenue: number;
  subscription_revenue: number;
  new_subscriptions: number;
  cancelled_subscriptions: number;
  active_subscriptions: number;
  mrr: number;
  churn_rate: number;
}

interface PaymentTransaction {
  id: string;
  user_id: string;
  amount: number;
  currency: string;
  status: string;
  payment_method: string;
  created_at: string;
}

const SubscriptionManagement: React.FC<SubscriptionManagementProps> = ({ isDarkMode }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [planFilter, setPlanFilter] = useState('all');
  const [selectedSubscription, setSelectedSubscription] = useState<Subscription | null>(null);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>([]);
  const [revenueData, setRevenueData] = useState<RevenueData | null>(null);
  const [paymentTransactions, setPaymentTransactions] = useState<PaymentTransaction[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        
        // Fetch subscription plans
        const { data: plansData, error: plansError } = await supabase
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');
        
        if (plansError) throw plansError;
        const formattedPlans = (plansData || []).map(plan => ({
          ...plan,
          features: Array.isArray(plan.features) ? plan.features as string[] : []
        }));
        setSubscriptionPlans(formattedPlans);

        // Fetch user subscriptions with plan details
        const { data: subsData, error: subsError } = await supabase
          .from('user_subscriptions')
          .select(`
            *,
            plan:subscription_plans(name, price_monthly)
          `)
          .order('created_at', { ascending: false });
        
        if (subsError) throw subsError;
        setSubscriptions(subsData || []);

        // Fetch latest revenue data
        const { data: revenueDataResult, error: revenueError } = await supabase
          .from('revenue_analytics')
          .select('*')
          .order('date', { ascending: false })
          .limit(1)
          .single();
        
        if (revenueError && revenueError.code !== 'PGRST116') throw revenueError;
        setRevenueData(revenueDataResult);

        // Fetch recent payment transactions
        const { data: transactionsData, error: transError } = await supabase
          .from('payment_transactions')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(10);
        
        if (transError) throw transError;
        setPaymentTransactions(transactionsData || []);

      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-success text-success-foreground"><CheckCircle className="w-3 h-3 mr-1" />Active</Badge>;
      case 'cancelled':
        return <Badge variant="destructive"><XCircle className="w-3 h-3 mr-1" />Cancelled</Badge>;
      case 'past_due':
        return <Badge variant="secondary"><Clock className="w-3 h-3 mr-1" />Past Due</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getPlanBadge = (planName: string) => {
    switch (planName?.toLowerCase()) {
      case 'premium':
        return <Badge className="bg-primary text-primary-foreground">{planName}</Badge>;
      case 'pro':
        return <Badge className="bg-accent text-accent-foreground">{planName}</Badge>;
      default:
        return <Badge variant="outline">{planName}</Badge>;
    }
  };

  const filteredSubscriptions = subscriptions.filter(sub => {
    const planName = sub.plan?.name || '';
    const matchesSearch = planName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                         sub.user_id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || sub.status === statusFilter;
    const matchesPlan = planFilter === 'all' || planName.toLowerCase() === planFilter.toLowerCase();
    
    return matchesSearch && matchesStatus && matchesPlan;
  });

  // Calculate metrics from revenue data or fallback to calculations
  const totalRevenue = revenueData?.total_revenue || 0;
  const activeSubscriptionsCount = revenueData?.active_subscriptions || subscriptions.filter(sub => sub.status === 'active').length;
  const churnRate = revenueData?.churn_rate || 0;
  const avgRevenuePerUser = activeSubscriptionsCount > 0 ? totalRevenue / activeSubscriptionsCount : 0;

  if (loading) {
    return (
      <div className="space-y-6 p-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading subscription data...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Subscription Management</h1>
          <p className="text-muted-foreground mt-2">Manage user subscriptions and revenue analytics</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{totalRevenue.toLocaleString('en-IN')}</div>
            <p className="text-xs text-muted-foreground">
              Monthly recurring revenue: ₹{revenueData?.mrr?.toLocaleString('en-IN') || 0}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Subscriptions</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeSubscriptionsCount}</div>
            <p className="text-xs text-muted-foreground">
              New this month: {revenueData?.new_subscriptions || 0}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Churn Rate</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{churnRate.toFixed(1)}%</div>
            <p className="text-xs text-muted-foreground">
              Cancelled: {revenueData?.cancelled_subscriptions || 0}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Revenue Per User</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{avgRevenuePerUser.toFixed(0)}</div>
            <p className="text-xs text-muted-foreground">
              Per active subscriber
            </p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="plans" className="space-y-4">
        <TabsList>
          <TabsTrigger value="plans">Subscription Plans</TabsTrigger>
          <TabsTrigger value="subscriptions">Active Subscriptions</TabsTrigger>
          <TabsTrigger value="transactions">Payment Transactions</TabsTrigger>
        </TabsList>

        <TabsContent value="plans">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Subscription Plans</CardTitle>
                <Button size="sm" disabled>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Plan
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {subscriptionPlans.map((plan) => (
                  <Card key={plan.id} className="border-2">
                    <CardHeader>
                      <CardTitle className="flex items-center justify-between">
                        {plan.name}
                        {plan.is_active && <Badge className="bg-success text-success-foreground">Active</Badge>}
                      </CardTitle>
                      <CardDescription>
                        <span className="text-2xl font-bold">₹{plan.price_monthly}</span>/month
                        {plan.price_yearly && (
                          <span className="text-sm text-muted-foreground ml-2">
                            or ₹{plan.price_yearly}/year
                          </span>
                        )}
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <ul className="space-y-2">
                        {plan.features.map((feature, index) => (
                          <li key={index} className="flex items-center text-sm">
                            <CheckCircle className="w-4 h-4 mr-2 text-success" />
                            {feature}
                          </li>
                        ))}
                      </ul>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="subscriptions">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Active Subscriptions ({filteredSubscriptions.length})</CardTitle>
                <div className="flex space-x-2">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search subscriptions..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 w-64"
                    />
                  </div>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Filter by status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="active">Active</SelectItem>
                      <SelectItem value="cancelled">Cancelled</SelectItem>
                      <SelectItem value="past_due">Past Due</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={planFilter} onValueChange={setPlanFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Filter by plan" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Plans</SelectItem>
                      {subscriptionPlans.map((plan) => (
                        <SelectItem key={plan.id} value={plan.name.toLowerCase()}>
                          {plan.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>User ID</TableHead>
                    <TableHead>Plan</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Start Date</TableHead>
                    <TableHead>End Date</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredSubscriptions.map((subscription) => (
                    <TableRow key={subscription.id}>
                      <TableCell className="font-mono text-xs">{subscription.user_id.slice(0, 8)}...</TableCell>
                      <TableCell>{getPlanBadge(subscription.plan?.name || 'Unknown')}</TableCell>
                      <TableCell>{getStatusBadge(subscription.status)}</TableCell>
                      <TableCell>{new Date(subscription.current_period_start).toLocaleDateString()}</TableCell>
                      <TableCell>{new Date(subscription.current_period_end).toLocaleDateString()}</TableCell>
                      <TableCell>₹{subscription.plan?.price_monthly || 0}</TableCell>
                      <TableCell>
                        <Sheet>
                          <SheetTrigger asChild>
                            <Button 
                              variant="outline" 
                              size="sm"
                              onClick={() => setSelectedSubscription(subscription)}
                            >
                              <Eye className="w-4 h-4" />
                            </Button>
                          </SheetTrigger>
                          <SheetContent>
                            <SheetHeader>
                              <SheetTitle>Subscription Details</SheetTitle>
                              <SheetDescription>
                                Detailed information about this subscription
                              </SheetDescription>
                            </SheetHeader>
                            {selectedSubscription && (
                              <div className="mt-6 space-y-4">
                                <div>
                                  <h4 className="font-semibold">User Information</h4>
                                  <p className="font-mono text-sm">ID: {selectedSubscription.user_id}</p>
                                </div>
                                <div>
                                  <h4 className="font-semibold">Subscription Details</h4>
                                  <p>Plan: {selectedSubscription.plan?.name || 'Unknown'}</p>
                                  <p>Status: {selectedSubscription.status}</p>
                                  <p>Amount: ₹{selectedSubscription.plan?.price_monthly || 0}/month</p>
                                  {selectedSubscription.stripe_subscription_id && (
                                    <p className="font-mono text-xs">Razorpay ID: {selectedSubscription.stripe_subscription_id}</p>
                                  )}
                                </div>
                                <div>
                                  <h4 className="font-semibold">Billing Period</h4>
                                  <p>Start: {new Date(selectedSubscription.current_period_start).toLocaleDateString()}</p>
                                  <p>End: {new Date(selectedSubscription.current_period_end).toLocaleDateString()}</p>
                                  <p>Created: {new Date(selectedSubscription.created_at).toLocaleDateString()}</p>
                                  {selectedSubscription.canceled_at && (
                                    <p>Cancelled: {new Date(selectedSubscription.canceled_at).toLocaleDateString()}</p>
                                  )}
                                </div>
                                <div className="pt-4">
                                  <Button variant="outline" className="w-full mb-2" disabled>
                                    Cancel Subscription
                                  </Button>
                                  <Button variant="default" className="w-full" disabled>
                                    View Payment History
                                  </Button>
                                </div>
                              </div>
                            )}
                          </SheetContent>
                        </Sheet>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="transactions">
          <Card>
            <CardHeader>
              <CardTitle>Recent Payment Transactions</CardTitle>
              <CardDescription>
                Latest payment transactions from Razorpay
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Transaction ID</TableHead>
                    <TableHead>User ID</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Payment Method</TableHead>
                    <TableHead>Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {paymentTransactions.length > 0 ? (
                    paymentTransactions.map((transaction) => (
                      <TableRow key={transaction.id}>
                        <TableCell className="font-mono text-xs">{transaction.id.slice(0, 8)}...</TableCell>
                        <TableCell className="font-mono text-xs">{transaction.user_id.slice(0, 8)}...</TableCell>
                        <TableCell>₹{transaction.amount}</TableCell>
                        <TableCell>{getStatusBadge(transaction.status)}</TableCell>
                        <TableCell>{transaction.payment_method}</TableCell>
                        <TableCell>{new Date(transaction.created_at).toLocaleDateString()}</TableCell>
                      </TableRow>
                    ))
                  ) : (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center text-muted-foreground">
                        No payment transactions found
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default SubscriptionManagement;