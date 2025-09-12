
import React, { useState, useEffect } from 'react';
import { 
  Bell, BellRing, Send, Users, MessageSquare, Calendar, 
  Search, Filter, MoreHorizontal, Eye, Trash2, Edit,
  TrendingUp, Clock, CheckCircle, AlertTriangle,
  Plus, Settings, Target, BarChart3
} from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from './ui/table';
import { supabase } from '../admin-integrations/supabase/client';

interface NotificationsProps {
  isDarkMode: boolean;
}

const Notifications: React.FC<NotificationsProps> = ({ isDarkMode }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalSent: 0,
    openRate: 0,
    scheduled: 0,
    clickRate: 0
  });

  // Load notifications from Supabase
  useEffect(() => {
    loadNotifications();
    loadStats();
  }, []);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('notification_templates')
        .select(`
          *,
          admin_notifications (
            id,
            status,
            recipients_count,
            open_rate,
            click_rate,
            sent_at,
            scheduled_for,
            created_at
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setNotifications(data || []);
    } catch (error) {
      console.error('Error loading notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      // Get total sent notifications
      const { count: totalSent } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'sent');

      // Get average open rate
      const { data: openRateData } = await supabase
        .from('admin_notifications')
        .select('open_rate')
        .eq('status', 'sent')
        .not('open_rate', 'is', null);

      const avgOpenRate = openRateData?.length > 0 
        ? openRateData.reduce((sum, item) => sum + (item.open_rate || 0), 0) / openRateData.length 
        : 0;

      // Get scheduled count
      const { count: scheduled } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'scheduled');

      // Get average click rate
      const { data: clickRateData } = await supabase
        .from('admin_notifications')
        .select('click_rate')
        .eq('status', 'sent')
        .not('click_rate', 'is', null);

      const avgClickRate = clickRateData?.length > 0 
        ? clickRateData.reduce((sum, item) => sum + (item.click_rate || 0), 0) / clickRateData.length 
        : 0;

      setStats({
        totalSent: totalSent || 0,
        openRate: Math.round(avgOpenRate * 100) / 100,
        scheduled: scheduled || 0,
        clickRate: Math.round(avgClickRate * 100) / 100
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const filteredNotifications = notifications.filter(notification => {
    const matchesSearch = notification.template_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         notification.template_content?.toLowerCase().includes(searchTerm.toLowerCase());
    const latestNotification = notification.admin_notifications?.[0];
    const matchesStatus = statusFilter === 'all' || latestNotification?.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'sent':
        return <Badge className="bg-green-100 text-green-600">Sent</Badge>;
      case 'scheduled':
        return <Badge className="bg-blue-100 text-blue-600">Scheduled</Badge>;
      case 'draft':
        return <Badge className="bg-gray-100 text-gray-600">Draft</Badge>;
      case 'failed':
        return <Badge variant="destructive">Failed</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getTypeBadge = (type: string) => {
    const colors = {
      promotional: 'bg-purple-100 text-purple-600',
      automated: 'bg-blue-100 text-blue-600',
      marketing: 'bg-pink-100 text-pink-600',
      security: 'bg-red-100 text-red-600',
      system: 'bg-gray-100 text-gray-600'
    };
    return (
      <Badge className={colors[type as keyof typeof colors] || 'bg-gray-100 text-gray-600'}>
        {type.charAt(0).toUpperCase() + type.slice(1)}
      </Badge>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Notifications Management</h2>
          <p className={`${isDarkMode ? 'text-gray-400' : 'text-gray-600'} mt-1`}>
            Send, schedule, and manage user notifications
          </p>
        </div>
        <Button className="bg-pink-500 hover:bg-pink-600">
          <Plus className="h-4 w-4 mr-2" />
          Create Notification
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Total Sent</p>
                <h3 className="text-2xl font-bold mt-1">{stats.totalSent.toLocaleString()}</h3>
                <p className="text-xs text-green-500 mt-1 flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" /> 12% this month
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-pink-900' : 'bg-pink-100'}`}>
                <Send className="text-pink-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Open Rate</p>
                <h3 className="text-2xl font-bold mt-1">{stats.openRate}%</h3>
                <p className="text-xs text-green-500 mt-1 flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" /> +5.3% vs last month
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-blue-900' : 'bg-blue-100'}`}>
                <Eye className="text-blue-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Scheduled</p>
                <h3 className="text-2xl font-bold mt-1">{stats.scheduled}</h3>
                <p className="text-xs text-blue-500 mt-1 flex items-center">
                  <Clock className="h-3 w-3 mr-1" /> Next in 2 hours
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-purple-900' : 'bg-purple-100'}`}>
                <Calendar className="text-purple-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Click Rate</p>
                <h3 className="text-2xl font-bold mt-1">{stats.clickRate}%</h3>
                <p className="text-xs text-red-500 mt-1 flex items-center">
                  <AlertTriangle className="h-3 w-3 mr-1" /> -2.1% vs last month
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                <Target className="text-green-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} cursor-pointer hover:shadow-md transition-shadow`}>
          <CardContent className="p-6 text-center">
            <MessageSquare className="h-8 w-8 text-blue-500 mx-auto mb-3" />
            <h3 className="font-semibold mb-2">Push Notifications</h3>
            <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              Send instant push notifications to app users
            </p>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} cursor-pointer hover:shadow-md transition-shadow`}>
          <CardContent className="p-6 text-center">
            <BellRing className="h-8 w-8 text-purple-500 mx-auto mb-3" />
            <h3 className="font-semibold mb-2">In-App Notifications</h3>
            <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              Create notifications visible within the app
            </p>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} cursor-pointer hover:shadow-md transition-shadow`}>
          <CardContent className="p-6 text-center">
            <Users className="h-8 w-8 text-pink-500 mx-auto mb-3" />
            <h3 className="font-semibold mb-2">Targeted Campaigns</h3>
            <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              Send notifications to specific user segments
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Notifications Table */}
      <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle>Recent Notifications</CardTitle>
            <div className="flex space-x-2">
              <Button variant="outline" size="sm">
                <BarChart3 className="h-4 w-4 mr-2" />
                Analytics
              </Button>
              <Button variant="outline" size="sm">
                <Settings className="h-4 w-4 mr-2" />
                Settings
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search and Filters */}
          <div className="flex space-x-4 mb-6">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                type="text"
                placeholder="Search notifications..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className={`px-3 py-2 border rounded-md ${isDarkMode ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}
            >
              <option value="all">All Status</option>
              <option value="sent">Sent</option>
              <option value="scheduled">Scheduled</option>
              <option value="draft">Draft</option>
              <option value="failed">Failed</option>
            </select>
            <Button variant="outline">
              <Filter className="h-4 w-4 mr-2" />
              Filters
            </Button>
          </div>

          {/* Table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Recipients</TableHead>
                  <TableHead>Open Rate</TableHead>
                  <TableHead>Click Rate</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-8">
                      <div className="flex items-center justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-pink-500"></div>
                        <span className="ml-2">Loading notifications...</span>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : filteredNotifications.map((notification) => {
                  const latestNotification = notification.admin_notifications?.[0];
                  return (
                    <TableRow key={notification.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium">{notification.template_name}</p>
                          <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'} truncate max-w-xs`}>
                            {notification.template_content}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        {getTypeBadge(notification.template_type || 'system')}
                      </TableCell>
                      <TableCell>
                        {getStatusBadge(latestNotification?.status || 'draft')}
                      </TableCell>
                      <TableCell>
                        {latestNotification?.recipients_count > 0 ? latestNotification.recipients_count.toLocaleString() : '-'}
                      </TableCell>
                      <TableCell>
                        {latestNotification?.open_rate > 0 ? `${latestNotification.open_rate}%` : '-'}
                      </TableCell>
                      <TableCell>
                        {latestNotification?.click_rate > 0 ? `${latestNotification.click_rate}%` : '-'}
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          {latestNotification?.sent_at && (
                            <p>{new Date(latestNotification.sent_at).toLocaleDateString()}</p>
                          )}
                          {latestNotification?.scheduled_for && (
                            <p className="text-blue-500">
                              Scheduled: {new Date(latestNotification.scheduled_for).toLocaleDateString()}
                            </p>
                          )}
                          {!latestNotification?.sent_at && !latestNotification?.scheduled_for && (
                            <p>Updated: {new Date(notification.updated_at).toLocaleDateString()}</p>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-1">
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>

          {filteredNotifications.length === 0 && (
            <div className="text-center py-8">
              <Bell className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className={`${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                No notifications found matching your criteria
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default Notifications;
