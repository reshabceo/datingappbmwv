import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area, PieChart, Pie, Cell } from 'recharts';
import { Activity, Server, Database, Zap, Users, AlertTriangle, CheckCircle, Clock, TrendingUp } from 'lucide-react';
import { supabase } from '../admin-integrations/supabase/client';
import { useToast } from './ui/use-toast';

interface RealTimeMetric {
  id: string;
  metric_type: string;
  metric_value: number;
  timestamp: string;
  metadata: any;
}

interface SystemStatus {
  status: 'healthy' | 'warning' | 'critical';
  message: string;
}

const SystemHealth: React.FC = () => {
  const { toast } = useToast();
  const [metrics, setMetrics] = useState<RealTimeMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [systemStatus, setSystemStatus] = useState<SystemStatus>({ status: 'healthy', message: 'All systems operational' });

  useEffect(() => {
    fetchRealTimeMetrics();
    
    // Set up real-time subscription for metrics updates
    const channel = supabase
      .channel('real-time-metrics')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'real_time_metrics' },
        (payload) => {
          setMetrics(prev => [payload.new as RealTimeMetric, ...prev.slice(0, 99)]);
        }
      )
      .subscribe();

    const interval = setInterval(fetchRealTimeMetrics, 30000); // Refresh every 30 seconds

    return () => {
      supabase.removeChannel(channel);
      clearInterval(interval);
    };
  }, []);

  const fetchRealTimeMetrics = async () => {
    try {
      const { data, error } = await supabase
        .from('real_time_metrics')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(100);

      if (error) throw error;
      
      setMetrics(data || []);
      evaluateSystemHealth(data || []);
    } catch (error) {
      console.error('Error fetching metrics:', error);
      toast({
        title: "Error",
        description: "Failed to fetch system metrics",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const evaluateSystemHealth = (metricsData: RealTimeMetric[]) => {
    const latestMetrics = metricsData.slice(0, 10);
    
    // Check for critical metrics using the actual metric types we generate
    const serverResponseTime = latestMetrics.find(m => m.metric_type === 'server_response_time')?.metric_value || 0;
    const activeUsers = latestMetrics.find(m => m.metric_type === 'active_users_now')?.metric_value || 0;
    const errorRate = latestMetrics.find(m => m.metric_type === 'error_rate')?.metric_value || 0;

    if (serverResponseTime > 1000 || errorRate > 5) {
      setSystemStatus({ status: 'critical', message: 'Critical system issues detected' });
    } else if (serverResponseTime > 500 || errorRate > 2) {
      setSystemStatus({ status: 'warning', message: 'System performance degraded' });
    } else {
      setSystemStatus({ status: 'healthy', message: 'All systems operational' });
    }
  };

  const getMetricsByType = (type: string) => {
    const filteredMetrics = metrics
      .filter(m => m.metric_type === type)
      .slice(0, 20)
      .reverse()
      .map(m => ({
        timestamp: new Date(m.timestamp).toLocaleTimeString(),
        value: m.metric_value,
        name: type
      }));

    // If no data, create some sample data points for better visualization
    if (filteredMetrics.length === 0) {
      const now = new Date();
      return Array.from({ length: 10 }, (_, i) => ({
        timestamp: new Date(now.getTime() - (9 - i) * 60000).toLocaleTimeString(),
        value: 0,
        name: type
      }));
    }

    return filteredMetrics;
  };

  const getLatestMetric = (type: string) => {
    return metrics.find(m => m.metric_type === type);
  };

  const getStatusColor = (status: SystemStatus['status']) => {
    switch (status) {
      case 'healthy': return 'text-green-600';
      case 'warning': return 'text-yellow-600';
      case 'critical': return 'text-red-600';
      default: return 'text-gray-600';
    }
  };

  const getStatusIcon = (status: SystemStatus['status']) => {
    switch (status) {
      case 'healthy': return <CheckCircle className="w-5 h-5 text-green-600" />;
      case 'warning': return <AlertTriangle className="w-5 h-5 text-yellow-600" />;
      case 'critical': return <AlertTriangle className="w-5 h-5 text-red-600" />;
      default: return <Activity className="w-5 h-5 text-gray-600" />;
    }
  };

  const formatUptime = () => {
    // Calculate real uptime based on first metric timestamp
    if (metrics.length === 0) {
      return "0d 0h 0m";
    }

    const firstMetric = metrics[metrics.length - 1]; // Oldest metric
    const startTime = new Date(firstMetric.timestamp);
    const now = new Date();
    const diffMs = now.getTime() - startTime.getTime();

    const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

    return `${days}d ${hours}h ${minutes}m`;
  };

  // Calculate real system health distribution based on metrics
  const calculateSystemHealthDistribution = () => {
    if (metrics.length === 0) {
      return [
        { name: 'No Data', value: 100, color: '#6b7280' }
      ];
    }

    const recentMetrics = metrics.slice(0, 20); // Last 20 metrics
    let healthy = 0, warning = 0, critical = 0;

    recentMetrics.forEach(metric => {
      const value = metric.metric_value;
      switch (metric.metric_type) {
        case 'server_response_time':
          if (value > 1000) critical++;
          else if (value > 500) warning++;
          else healthy++;
          break;
        case 'error_rate':
          if (value > 5) critical++;
          else if (value > 2) warning++;
          else healthy++;
          break;
        case 'active_users_now':
          if (value === 0) warning++; // No active users is concerning
          else healthy++;
          break;
        default:
          healthy++;
      }
    });

    const total = healthy + warning + critical;
    if (total === 0) {
      return [
        { name: 'No Data', value: 100, color: '#6b7280' }
      ];
    }

    return [
      { name: 'Healthy', value: Math.round((healthy / total) * 100), color: '#10b981' },
      { name: 'Warning', value: Math.round((warning / total) * 100), color: '#f59e0b' },
      { name: 'Critical', value: Math.round((critical / total) * 100), color: '#ef4444' }
    ];
  };

  const pieData = calculateSystemHealthDistribution();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-muted-foreground">Loading system metrics...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* System Status Header */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              {getStatusIcon(systemStatus.status)}
              <div>
                <h2 className="text-2xl font-bold">System Health Dashboard</h2>
                <p className={`text-sm ${getStatusColor(systemStatus.status)}`}>
                  {systemStatus.message}
                </p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-muted-foreground">Uptime</p>
              <p className="text-2xl font-bold text-green-600">{formatUptime()}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Key Metrics Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">
              {getLatestMetric('active_users_now')?.metric_value || 0}
            </div>
            <p className="text-xs text-muted-foreground">Currently online</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Messages/min</CardTitle>
            <Server className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {getLatestMetric('messages_per_minute')?.metric_value || 0}
            </div>
            <Progress 
              value={Math.min((getLatestMetric('messages_per_minute')?.metric_value || 0) * 2, 100)} 
              className="mt-2"
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Response Time</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {getLatestMetric('server_response_time')?.metric_value || 0}ms
            </div>
            <p className="text-xs text-muted-foreground">Average API response</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">New Matches</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {getLatestMetric('new_matches_today')?.metric_value || 0}
            </div>
            <p className="text-xs text-muted-foreground">Today</p>
          </CardContent>
        </Card>
      </div>

      {/* Detailed Monitoring Tabs */}
      <Tabs defaultValue="performance" className="space-y-4">
        <TabsList>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="traffic">Traffic</TabsTrigger>
          <TabsTrigger value="resources">Resources</TabsTrigger>
          <TabsTrigger value="status">Status Overview</TabsTrigger>
        </TabsList>

        <TabsContent value="performance" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Response Time Trend</CardTitle>
              </CardHeader>
              <CardContent>
                {metrics.length === 0 ? (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                    <div className="text-center">
                      <Activity className="h-8 w-8 mx-auto mb-2" />
                      <p>No response time data available</p>
                      <p className="text-sm">Data will appear as metrics are collected</p>
                    </div>
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={getMetricsByType('server_response_time')}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="timestamp" />
                      <YAxis />
                      <Tooltip />
                      <Line 
                        type="monotone" 
                        dataKey="value" 
                        stroke="hsl(var(--primary))" 
                        strokeWidth={2}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Error Rate</CardTitle>
              </CardHeader>
              <CardContent>
                {metrics.length === 0 ? (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                    <div className="text-center">
                      <AlertTriangle className="h-8 w-8 mx-auto mb-2" />
                      <p>No error rate data available</p>
                      <p className="text-sm">Data will appear as metrics are collected</p>
                    </div>
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={getMetricsByType('error_rate')}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="timestamp" />
                      <YAxis />
                      <Tooltip />
                      <Area 
                        type="monotone" 
                        dataKey="value" 
                        stroke="#ef4444" 
                        fill="#ef4444" 
                        fillOpacity={0.3}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="traffic" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Active Users</CardTitle>
              </CardHeader>
              <CardContent>
                {metrics.length === 0 ? (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                    <div className="text-center">
                      <Users className="h-8 w-8 mx-auto mb-2" />
                      <p>No active users data available</p>
                      <p className="text-sm">Data will appear as users come online</p>
                    </div>
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={getMetricsByType('active_users_now')}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="timestamp" />
                      <YAxis />
                      <Tooltip />
                      <Area 
                        type="monotone" 
                        dataKey="value" 
                        stroke="hsl(var(--primary))" 
                        fill="hsl(var(--primary))" 
                        fillOpacity={0.3}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>API Calls per Minute</CardTitle>
              </CardHeader>
              <CardContent>
                {metrics.length === 0 ? (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground">
                    <div className="text-center">
                      <Zap className="h-8 w-8 mx-auto mb-2" />
                      <p>No message activity data available</p>
                      <p className="text-sm">Data will appear as messages are sent</p>
                    </div>
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={getMetricsByType('messages_per_minute')}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="timestamp" />
                      <YAxis />
                      <Tooltip />
                      <Line 
                        type="monotone" 
                        dataKey="value" 
                        stroke="#10b981" 
                        strokeWidth={2}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="resources" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Server Resources</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="flex justify-between text-sm mb-2">
                    <span>Server Response Time</span>
                    <span>{getLatestMetric('server_response_time')?.metric_value || 0}ms</span>
                  </div>
                  <Progress value={Math.min((getLatestMetric('server_response_time')?.metric_value || 0) / 10, 100)} />
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-2">
                    <span>Messages per Minute</span>
                    <span>{getLatestMetric('messages_per_minute')?.metric_value || 0}</span>
                  </div>
                  <Progress value={Math.min((getLatestMetric('messages_per_minute')?.metric_value || 0) * 2, 100)} />
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-2">
                    <span>Active Conversations</span>
                    <span>{getLatestMetric('concurrent_conversations')?.metric_value || 0}</span>
                  </div>
                  <Progress value={Math.min((getLatestMetric('concurrent_conversations')?.metric_value || 0) * 5, 100)} />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>System Health Distribution</CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      outerRadius={100}
                      fill="#8884d8"
                      dataKey="value"
                      label={({ name, value }) => `${name}: ${value}%`}
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="status" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Database</CardTitle>
                <Database className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <Badge variant="outline" className={
                  systemStatus.status === 'healthy' ? 'text-green-600 border-green-600' :
                  systemStatus.status === 'warning' ? 'text-yellow-600 border-yellow-600' :
                  'text-red-600 border-red-600'
                }>
                  {systemStatus.status === 'healthy' ? 'Operational' :
                   systemStatus.status === 'warning' ? 'Degraded' : 'Critical'}
                </Badge>
                <p className="text-sm text-muted-foreground mt-2">
                  {getLatestMetric('concurrent_conversations')?.metric_value || 0} active conversations
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">API Services</CardTitle>
                <Zap className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <Badge variant="outline" className={
                  (getLatestMetric('server_response_time')?.metric_value || 0) < 500 ? 'text-green-600 border-green-600' :
                  (getLatestMetric('server_response_time')?.metric_value || 0) < 1000 ? 'text-yellow-600 border-yellow-600' :
                  'text-red-600 border-red-600'
                }>
                  {(getLatestMetric('server_response_time')?.metric_value || 0) < 500 ? 'Healthy' :
                   (getLatestMetric('server_response_time')?.metric_value || 0) < 1000 ? 'Slow' : 'Critical'}
                </Badge>
                <p className="text-sm text-muted-foreground mt-2">
                  {getLatestMetric('server_response_time')?.metric_value || 0}ms avg response
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">File Storage</CardTitle>
                <Server className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <Badge variant="outline" className="text-green-600 border-green-600">
                  Available
                </Badge>
                <p className="text-sm text-muted-foreground mt-2">
                  {getLatestMetric('storage_usage')?.metric_value || 0}% storage used
                </p>
                <div className="mt-2">
                  <Progress value={getLatestMetric('storage_usage')?.metric_value || 0} />
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default SystemHealth;