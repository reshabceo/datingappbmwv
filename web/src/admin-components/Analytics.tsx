import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Badge } from "./ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Calendar } from "./ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import { DateRange } from "react-day-picker";
import { 
  TrendingUp, TrendingDown, Users, Heart, MessageSquare, CreditCard,
  Calendar as CalendarIcon, Clock, Target, BarChart3, PieChart, Activity, Globe,
  Smartphone, Monitor, Filter, Download, RefreshCw, Eye, Zap, Star
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart as RechartsPieChart, Cell, Pie, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { supabase } from "../admin-integrations/supabase/client";
import { format } from "date-fns";

interface AnalyticsProps {
  isDarkMode: boolean;
}

interface PlatformAnalytics {
  date: string;
  total_users: number;
  new_users: number;
  active_users: number;
  daily_active_users: number;
  weekly_active_users: number;
  monthly_active_users: number;
  user_retention_rate: number;
  avg_session_duration: string;
  bounce_rate: number;
}

interface ContentAnalytics {
  date: string;
  total_messages: number;
  text_messages: number;
  image_messages: number;
  video_messages: number;
  stories_posted: number;
  stories_viewed: number;
  avg_messages_per_conversation: number;
  peak_activity_hour: number;
  popular_features: any;
}

interface RevenueAnalytics {
  date: string;
  total_revenue: number;
  subscription_revenue: number;
  new_subscriptions: number;
  cancelled_subscriptions: number;
  active_subscriptions: number;
  mrr: number;
  churn_rate: number;
}

interface RealTimeMetric {
  metric_type: string;
  metric_value: number;
  timestamp: string;
  metadata: any;
}

const Analytics: React.FC<AnalyticsProps> = ({ isDarkMode }) => {
  const [timeRange, setTimeRange] = useState('30');
  const [dateRange, setDateRange] = useState<DateRange | undefined>();
  const [loading, setLoading] = useState(true);
  const [platformData, setPlatformData] = useState<PlatformAnalytics[]>([]);
  const [contentData, setContentData] = useState<ContentAnalytics[]>([]);
  const [revenueData, setRevenueData] = useState<RevenueAnalytics[]>([]);
  const [realTimeMetrics, setRealTimeMetrics] = useState<RealTimeMetric[]>([]);
  const [exportFormat, setExportFormat] = useState('csv');

  useEffect(() => {
    fetchAnalyticsData();
    fetchRealTimeMetrics();
    
    // Set up real-time updates
    const interval = setInterval(fetchRealTimeMetrics, 30000); // Update every 30 seconds
    
    return () => clearInterval(interval);
  }, [timeRange, dateRange]);

  const fetchAnalyticsData = async () => {
    try {
      setLoading(true);
      
      const daysBack = parseInt(timeRange);
      const startDate = dateRange?.from || new Date(Date.now() - daysBack * 24 * 60 * 60 * 1000);
      const endDate = dateRange?.to || new Date();

      console.log('📊 Fetching analytics data...', { startDate, endDate, timeRange });

      // Fetch platform analytics
      const { data: platformAnalytics, error: platformError } = await supabase
        .from('platform_analytics')
        .select('*')
        .gte('date', format(startDate, 'yyyy-MM-dd'))
        .lte('date', format(endDate, 'yyyy-MM-dd'))
        .order('date', { ascending: true });

      if (platformError) {
        console.error('Platform analytics error:', platformError);
        throw platformError;
      }
      
      console.log('✅ Platform analytics loaded:', platformAnalytics?.length || 0, 'records');
      
      const formattedPlatformData = (platformAnalytics || []).map(item => ({
        ...item,
        avg_session_duration: item.avg_session_duration ? String(item.avg_session_duration) : ''
      }));
      setPlatformData(formattedPlatformData);

      // Fetch content analytics
      const { data: contentAnalytics, error: contentError } = await supabase
        .from('content_analytics')
        .select('*')
        .gte('date', format(startDate, 'yyyy-MM-dd'))
        .lte('date', format(endDate, 'yyyy-MM-dd'))
        .order('date', { ascending: true });

      if (contentError) {
        console.error('Content analytics error:', contentError);
        throw contentError;
      }
      
      console.log('✅ Content analytics loaded:', contentAnalytics?.length || 0, 'records');
      setContentData(contentAnalytics || []);

      // Fetch revenue analytics
      const { data: revenueAnalytics, error: revenueError } = await supabase
        .from('revenue_analytics')
        .select('*')
        .gte('date', format(startDate, 'yyyy-MM-dd'))
        .lte('date', format(endDate, 'yyyy-MM-dd'))
        .order('date', { ascending: true });

      if (revenueError) {
        console.error('Revenue analytics error:', revenueError);
        throw revenueError;
      }
      
      console.log('✅ Revenue analytics loaded:', revenueAnalytics?.length || 0, 'records');
      setRevenueData(revenueAnalytics || []);

    } catch (error) {
      console.error('❌ Error fetching analytics data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchRealTimeMetrics = async () => {
    try {
      // Get the latest metrics for each type
      const { data: metrics, error } = await supabase
        .from('real_time_metrics')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(20); // Get latest 20 records

      if (error) {
        console.error('Real-time metrics error:', error);
        throw error;
      }
      
      console.log('✅ Real-time metrics loaded:', metrics?.length || 0, 'records');
      setRealTimeMetrics(metrics || []);
    } catch (error) {
      console.error('❌ Error fetching real-time metrics:', error);
    }
  };

  const handleExportData = async () => {
    try {
      const exportData = {
        platform_analytics: platformData,
        content_analytics: contentData,
        revenue_analytics: revenueData,
        real_time_metrics: realTimeMetrics,
        export_date: new Date().toISOString(),
        date_range: {
          from: dateRange?.from?.toISOString(),
          to: dateRange?.to?.toISOString()
        }
      };

      // Create and trigger download
      const blob = new Blob([JSON.stringify(exportData, null, 2)], { 
        type: exportFormat === 'json' ? 'application/json' : 'text/csv' 
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `analytics-report-${format(new Date(), 'yyyy-MM-dd')}.${exportFormat}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting data:', error);
    }
  };

  // Calculate key metrics from data
  const latestPlatformData = platformData[platformData.length - 1];
  const latestContentData = contentData[contentData.length - 1];
  const latestRevenueData = revenueData[revenueData.length - 1];

  const getMetricChange = (current: number, previous: number) => {
    if (!previous) return 0;
    return ((current - previous) / previous * 100);
  };

  const keyMetrics = [
    {
      title: 'Total Revenue',
      value: `₹${(latestRevenueData?.total_revenue || 0).toLocaleString('en-IN')}`,
      change: revenueData.length >= 2 ? getMetricChange(
        latestRevenueData?.total_revenue || 0, 
        revenueData[revenueData.length - 2]?.total_revenue || 0
      ) : 0,
      icon: CreditCard,
      color: 'green'
    },
    {
      title: 'Active Users',
      value: (latestPlatformData?.active_users || 0).toLocaleString(),
      change: platformData.length >= 2 ? getMetricChange(
        latestPlatformData?.active_users || 0,
        platformData[platformData.length - 2]?.active_users || 0
      ) : 0,
      icon: Users,
      color: 'blue'
    },
    {
      title: 'Daily Messages',
      value: (latestContentData?.total_messages || 0).toLocaleString(),
      change: contentData.length >= 2 ? getMetricChange(
        latestContentData?.total_messages || 0,
        contentData[contentData.length - 2]?.total_messages || 0
      ) : 0,
      icon: MessageSquare,
      color: 'purple'
    },
    {
      title: 'Retention Rate',
      value: `${(latestPlatformData?.user_retention_rate || 0).toFixed(1)}%`,
      change: platformData.length >= 2 ? getMetricChange(
        latestPlatformData?.user_retention_rate || 0,
        platformData[platformData.length - 2]?.user_retention_rate || 0
      ) : 0,
      icon: Target,
      color: 'yellow'
    },
    {
      title: 'MRR',
      value: `₹${(latestRevenueData?.mrr || 0).toLocaleString('en-IN')}`,
      change: revenueData.length >= 2 ? getMetricChange(
        latestRevenueData?.mrr || 0,
        revenueData[revenueData.length - 2]?.mrr || 0
      ) : 0,
      icon: TrendingUp,
      color: 'pink'
    },
    {
      title: 'Churn Rate',
      value: `${(latestRevenueData?.churn_rate || 0).toFixed(1)}%`,
      change: revenueData.length >= 2 ? getMetricChange(
        latestRevenueData?.churn_rate || 0,
        revenueData[revenueData.length - 2]?.churn_rate || 0
      ) : 0,
      icon: TrendingDown,
      color: 'red'
    }
  ];

  // Chart data preparation
  const userGrowthData = platformData.map(item => ({
    date: format(new Date(item.date), 'MMM dd'),
    new_users: item.new_users,
    active_users: item.active_users,
    total_users: item.total_users
  }));

  const engagementData = platformData.map(item => ({
    date: format(new Date(item.date), 'MMM dd'),
    daily: item.daily_active_users,
    weekly: item.weekly_active_users,
    monthly: item.monthly_active_users
  }));

  const revenueChartData = revenueData.map(item => ({
    date: format(new Date(item.date), 'MMM dd'),
    revenue: item.total_revenue,
    mrr: item.mrr,
    subscriptions: item.active_subscriptions
  }));

  const messageTypeData = contentData.length > 0 ? [
    { name: 'Text Messages', value: contentData.reduce((sum, item) => sum + item.text_messages, 0), color: '#8884d8' },
    { name: 'Image Messages', value: contentData.reduce((sum, item) => sum + item.image_messages, 0), color: '#82ca9d' },
    { name: 'Video Messages', value: contentData.reduce((sum, item) => sum + item.video_messages, 0), color: '#ffc658' },
  ] : [];

  const getRealTimeMetric = (type: string) => {
    const metric = realTimeMetrics.find(m => m.metric_type === type);
    return metric?.metric_value || 0;
  };

  // Performance monitoring metrics
  const performanceMetrics = [
    {
      title: 'Server Response Time',
      value: `${getRealTimeMetric('server_response_time')}ms`,
      status: getRealTimeMetric('server_response_time') < 100 ? 'excellent' : 
              getRealTimeMetric('server_response_time') < 300 ? 'good' : 'poor',
      icon: Activity,
      color: getRealTimeMetric('server_response_time') < 100 ? 'green' : 
             getRealTimeMetric('server_response_time') < 300 ? 'yellow' : 'red'
    },
    {
      title: 'Database Connections',
      value: getRealTimeMetric('database_connections'),
      status: getRealTimeMetric('database_connections') < 50 ? 'excellent' : 
              getRealTimeMetric('database_connections') < 100 ? 'good' : 'poor',
      icon: Target,
      color: getRealTimeMetric('database_connections') < 50 ? 'green' : 
             getRealTimeMetric('database_connections') < 100 ? 'yellow' : 'red'
    },
    {
      title: 'Cache Hit Rate',
      value: `${getRealTimeMetric('cache_hit_rate')}%`,
      status: getRealTimeMetric('cache_hit_rate') > 90 ? 'excellent' : 
              getRealTimeMetric('cache_hit_rate') > 70 ? 'good' : 'poor',
      icon: Zap,
      color: getRealTimeMetric('cache_hit_rate') > 90 ? 'green' : 
             getRealTimeMetric('cache_hit_rate') > 70 ? 'yellow' : 'red'
    },
    {
      title: 'API Requests/sec',
      value: getRealTimeMetric('api_requests_per_second'),
      status: getRealTimeMetric('api_requests_per_second') < 100 ? 'excellent' : 
              getRealTimeMetric('api_requests_per_second') < 500 ? 'good' : 'poor',
      icon: Globe,
      color: getRealTimeMetric('api_requests_per_second') < 100 ? 'green' : 
             getRealTimeMetric('api_requests_per_second') < 500 ? 'yellow' : 'red'
    }
  ];

  if (loading) {
    return (
      <div className="space-y-6 p-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading analytics data...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Analytics Dashboard</h1>
          <p className="text-muted-foreground mt-2">Comprehensive platform insights and performance metrics</p>
        </div>
        
        <div className="flex items-center space-x-3">
          <Select value={timeRange} onValueChange={setTimeRange}>
            <SelectTrigger className="w-40">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">Last 7 days</SelectItem>
              <SelectItem value="30">Last 30 days</SelectItem>
              <SelectItem value="90">Last 90 days</SelectItem>
              <SelectItem value="365">Last year</SelectItem>
            </SelectContent>
          </Select>
          
          <Popover>
            <PopoverTrigger asChild>
              <Button variant="outline" className="w-40">
                <CalendarIcon className="mr-2 h-4 w-4" />
                Custom Range
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="end">
              <Calendar
                initialFocus
                mode="range"
                defaultMonth={dateRange?.from}
                selected={dateRange}
                onSelect={setDateRange}
                numberOfMonths={2}
              />
            </PopoverContent>
          </Popover>
          
          <Select value={exportFormat} onValueChange={setExportFormat}>
            <SelectTrigger className="w-24">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="csv">CSV</SelectItem>
              <SelectItem value="json">JSON</SelectItem>
            </SelectContent>
          </Select>
          
          <Button onClick={handleExportData} variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          
          <Button onClick={fetchAnalyticsData}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {/* Real-time Metrics Bar */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Live Metrics
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{getRealTimeMetric('active_users_now')}</div>
              <div className="text-sm text-muted-foreground">Users Online</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{getRealTimeMetric('messages_per_minute')}/min</div>
              <div className="text-sm text-muted-foreground">Messages</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">{getRealTimeMetric('new_matches_today')}</div>
              <div className="text-sm text-muted-foreground">Matches Today</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600">{getRealTimeMetric('server_response_time')}ms</div>
              <div className="text-sm text-muted-foreground">Response Time</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-pink-600">{getRealTimeMetric('concurrent_conversations')}</div>
              <div className="text-sm text-muted-foreground">Active Chats</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {keyMetrics.map((metric, index) => {
          const Icon = metric.icon;
          const isPositive = metric.change > 0;
          return (
            <Card key={index}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <Icon className={`h-5 w-5 ${
                    metric.color === 'green' ? 'text-green-600' :
                    metric.color === 'blue' ? 'text-blue-600' :
                    metric.color === 'purple' ? 'text-purple-600' :
                    metric.color === 'yellow' ? 'text-yellow-600' :
                    metric.color === 'pink' ? 'text-pink-600' :
                    'text-red-600'
                  }`} />
                  <div className={`flex items-center space-x-1 text-xs ${
                    isPositive ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
                    <span>{Math.abs(metric.change).toFixed(1)}%</span>
                  </div>
                </div>
                <div className="mt-2">
                  <p className="text-xs text-muted-foreground">{metric.title}</p>
                  <p className="text-xl font-bold">{metric.value}</p>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Analytics Tabs */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="engagement">Engagement</TabsTrigger>
          <TabsTrigger value="revenue">Revenue</TabsTrigger>
          <TabsTrigger value="content">Content</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>User Growth Trend</CardTitle>
                <CardDescription>Daily user acquisition and activity</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={userGrowthData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="new_users" stroke="#8884d8" name="New Users" />
                    <Line type="monotone" dataKey="active_users" stroke="#82ca9d" name="Active Users" />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Revenue Growth</CardTitle>
                <CardDescription>Revenue trends and MRR</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={revenueChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip formatter={(value) => [`₹${Number(value).toLocaleString('en-IN')}`, '']} />
                    <Legend />
                    <Area type="monotone" dataKey="revenue" stackId="1" stroke="#8884d8" fill="#8884d8" name="Total Revenue" />
                    <Area type="monotone" dataKey="mrr" stackId="2" stroke="#82ca9d" fill="#82ca9d" name="MRR" />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Message Types Distribution</CardTitle>
                <CardDescription>Breakdown of message content types</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <RechartsPieChart>
                    <Pie
                      dataKey="value"
                      data={messageTypeData}
                      cx="50%"
                      cy="50%"
                      outerRadius={80}
                      label={({name, percent}) => `${name} ${(percent * 100).toFixed(0)}%`}
                    >
                      {messageTypeData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </RechartsPieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Platform Health</CardTitle>
                <CardDescription>Key performance indicators</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Users className="h-4 w-4 text-blue-600" />
                      <span>User Retention</span>
                    </div>
                    <Badge variant="outline">{(latestPlatformData?.user_retention_rate || 0).toFixed(1)}%</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Activity className="h-4 w-4 text-green-600" />
                      <span>Bounce Rate</span>
                    </div>
                    <Badge variant="outline">{(latestPlatformData?.bounce_rate || 0).toFixed(1)}%</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Clock className="h-4 w-4 text-purple-600" />
                      <span>Avg Session</span>
                    </div>
                    <Badge variant="outline">{latestPlatformData?.avg_session_duration || 'N/A'}</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Star className="h-4 w-4 text-yellow-600" />
                      <span>Peak Hour</span>
                    </div>
                    <Badge variant="outline">{latestContentData?.peak_activity_hour || 0}:00</Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="users">
          <Card>
            <CardHeader>
              <CardTitle>User Engagement Metrics</CardTitle>
              <CardDescription>Daily, weekly, and monthly active user trends</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={engagementData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="daily" fill="#8884d8" name="Daily Active Users" />
                  <Bar dataKey="weekly" fill="#82ca9d" name="Weekly Active Users" />
                  <Bar dataKey="monthly" fill="#ffc658" name="Monthly Active Users" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="engagement">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Engagement Overview</CardTitle>
                <CardDescription>User interaction metrics</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  <div className="flex justify-between items-center">
                    <span className="text-sm">Daily Messages</span>
                    <span className="font-medium">{(latestContentData?.total_messages || 0).toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm">Stories Posted</span>
                    <span className="font-medium">{(latestContentData?.stories_posted || 0).toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm">Stories Viewed</span>
                    <span className="font-medium">{(latestContentData?.stories_viewed || 0).toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm">Avg Messages/Conversation</span>
                    <span className="font-medium">{(latestContentData?.avg_messages_per_conversation || 0).toFixed(1)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Popular Features</CardTitle>
                <CardDescription>Feature usage statistics</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {latestContentData?.popular_features && Object.entries(latestContentData.popular_features).map(([feature, count]) => (
                    <div key={feature} className="flex justify-between items-center p-3 bg-muted rounded-lg">
                      <span className="capitalize">{feature.replace('_', ' ')}</span>
                      <Badge variant="outline">{Number(count).toLocaleString()}</Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="revenue">
          <Card>
            <CardHeader>
              <CardTitle>Revenue Analytics</CardTitle>
              <CardDescription>Revenue trends and subscription metrics</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <LineChart data={revenueChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip formatter={(value) => [`₹${Number(value).toLocaleString('en-IN')}`, '']} />
                  <Legend />
                  <Line type="monotone" dataKey="revenue" stroke="#8884d8" name="Total Revenue" strokeWidth={3} />
                  <Line type="monotone" dataKey="mrr" stroke="#82ca9d" name="Monthly Recurring Revenue" strokeWidth={3} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="content">
          <Card>
            <CardHeader>
              <CardTitle>Content Analytics</CardTitle>
              <CardDescription>Message volume and content trends</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <AreaChart data={contentData.map(item => ({
                  date: format(new Date(item.date), 'MMM dd'),
                  text: item.text_messages,
                  image: item.image_messages,
                  video: item.video_messages
                }))}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Area type="monotone" dataKey="text" stackId="1" stroke="#8884d8" fill="#8884d8" name="Text Messages" />
                  <Area type="monotone" dataKey="image" stackId="1" stroke="#82ca9d" fill="#82ca9d" name="Image Messages" />
                  <Area type="monotone" dataKey="video" stackId="1" stroke="#ffc658" fill="#ffc658" name="Video Messages" />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="performance" className="space-y-6">
          {/* Performance Metrics Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {performanceMetrics.map((metric, index) => {
              const Icon = metric.icon;
              return (
                <Card key={index} className={`border-l-4 ${
                  metric.color === 'green' ? 'border-l-green-500' :
                  metric.color === 'yellow' ? 'border-l-yellow-500' :
                  'border-l-red-500'
                }`}>
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <Icon className={`h-5 w-5 ${
                        metric.color === 'green' ? 'text-green-600' :
                        metric.color === 'yellow' ? 'text-yellow-600' :
                        'text-red-600'
                      }`} />
                      <Badge variant={
                        metric.status === 'excellent' ? 'default' :
                        metric.status === 'good' ? 'secondary' : 'destructive'
                      }>
                        {metric.status}
                      </Badge>
                    </div>
                    <div className="mt-2">
                      <p className="text-xs text-muted-foreground">{metric.title}</p>
                      <p className="text-xl font-bold">{metric.value}</p>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {/* System Health Overview */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>System Health Status</CardTitle>
                <CardDescription>Overall platform performance indicators</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Activity className="h-4 w-4 text-green-600" />
                      <span>System Status</span>
                    </div>
                    <Badge variant="default" className="bg-green-600">Operational</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Globe className="h-4 w-4 text-blue-600" />
                      <span>API Health</span>
                    </div>
                    <Badge variant="default" className="bg-blue-600">Healthy</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Target className="h-4 w-4 text-purple-600" />
                      <span>Database Status</span>
                    </div>
                    <Badge variant="default" className="bg-purple-600">Connected</Badge>
                  </div>
                  <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
                    <div className="flex items-center gap-2">
                      <Zap className="h-4 w-4 text-yellow-600" />
                      <span>Cache Status</span>
                    </div>
                    <Badge variant="default" className="bg-yellow-600">Active</Badge>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Performance Trends</CardTitle>
                <CardDescription>Real-time performance metrics over time</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={realTimeMetrics.slice(-20).map(metric => ({
                    time: format(new Date(metric.timestamp), 'HH:mm'),
                    value: metric.metric_value,
                    type: metric.metric_type
                  })).filter(item => item.type === 'server_response_time')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" />
                    <YAxis />
                    <Tooltip />
                    <Line type="monotone" dataKey="value" stroke="#8884d8" strokeWidth={2} />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>

          {/* Alerts and Notifications */}
          <Card>
            <CardHeader>
              <CardTitle>System Alerts</CardTitle>
              <CardDescription>Recent performance alerts and notifications</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center gap-3 p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">System Performance Normal</p>
                    <p className="text-xs text-muted-foreground">All metrics within acceptable ranges</p>
                  </div>
                  <span className="text-xs text-muted-foreground">2 min ago</span>
                </div>
                <div className="flex items-center gap-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                  <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">High User Activity Detected</p>
                    <p className="text-xs text-muted-foreground">Peak usage during evening hours</p>
                  </div>
                  <span className="text-xs text-muted-foreground">15 min ago</span>
                </div>
                <div className="flex items-center gap-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
                  <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">Cache Hit Rate Below Optimal</p>
                    <p className="text-xs text-muted-foreground">Consider cache optimization</p>
                  </div>
                  <span className="text-xs text-muted-foreground">1 hour ago</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default Analytics;