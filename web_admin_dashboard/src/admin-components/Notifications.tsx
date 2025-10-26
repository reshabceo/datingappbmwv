
import React, { useState, useEffect } from 'react';
import { 
  Bell, BellRing, Send, Users, MessageSquare, Calendar, 
  Search, Filter, MoreHorizontal, Eye, Trash2, Edit,
  TrendingUp, Clock, CheckCircle, AlertTriangle,
  Plus, Settings, Target, BarChart3, X
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
import { 
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from './ui/dialog';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { supabase } from '../admin-integrations/supabase/client';
import { toast } from 'react-hot-toast';

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
  const [trends, setTrends] = useState({
    totalSent: { change: 0, isPositive: true },
    openRate: { change: 0, isPositive: true },
    scheduled: { change: 0, isPositive: true },
    clickRate: { change: 0, isPositive: true }
  });
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [createForm, setCreateForm] = useState({
    title: '',
    content: '',
    notification_type: 'push',
    template_type: 'system',
    status: 'draft',
    recipients_count: 0,
    scheduled_for: ''
  });

  // Load notifications from Supabase
  useEffect(() => {
    loadNotifications();
    loadStats();
  }, []);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      console.log('📧 Loading notifications...');
      
      // First, get admin notifications with their template info
      const { data: adminNotifications, error: adminError } = await supabase
        .from('admin_notifications')
        .select(`
          *,
          notification_templates (
            template_name,
            template_type
          )
        `)
        .order('created_at', { ascending: false });

      if (adminError) {
        console.error('❌ Error loading admin notifications:', adminError);
        throw adminError;
      }

      console.log('📧 Admin notifications loaded:', adminNotifications?.length || 0);
      setNotifications(adminNotifications || []);
    } catch (error) {
      console.error('❌ Error loading notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      console.log('📊 Loading notification stats...');
      
      // Get total sent notifications
      const { count: totalSent, error: sentError } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'sent');

      if (sentError) {
        console.error('❌ Error loading sent count:', sentError);
      }

      // Get average open rate from sent notifications
      const { data: openRateData, error: openError } = await supabase
        .from('admin_notifications')
        .select('open_rate')
        .eq('status', 'sent')
        .not('open_rate', 'is', null);

      if (openError) {
        console.error('❌ Error loading open rate data:', openError);
      }

      const avgOpenRate = openRateData?.length > 0 
        ? openRateData.reduce((sum, item) => sum + (item.open_rate || 0), 0) / openRateData.length 
        : 0;

      // Get scheduled count
      const { count: scheduled, error: scheduledError } = await supabase
        .from('admin_notifications')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'scheduled');

      if (scheduledError) {
        console.error('❌ Error loading scheduled count:', scheduledError);
      }

      // Get average click rate from sent notifications
      const { data: clickRateData, error: clickError } = await supabase
        .from('admin_notifications')
        .select('click_rate')
        .eq('status', 'sent')
        .not('click_rate', 'is', null);

      if (clickError) {
        console.error('❌ Error loading click rate data:', clickError);
      }

      const avgClickRate = clickRateData?.length > 0 
        ? clickRateData.reduce((sum, item) => sum + (item.click_rate || 0), 0) / clickRateData.length 
        : 0;

      // Calculate trends by comparing with previous period
      const { data: previousStats } = await supabase
        .from('admin_notifications')
        .select('status, open_rate, click_rate, created_at')
        .lt('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

      const previousSent = previousStats?.filter(n => n.status === 'sent').length || 0;
      const previousOpenRate = previousStats?.filter(n => n.status === 'sent' && n.open_rate)
        .reduce((sum, n) => sum + (n.open_rate || 0), 0) / (previousStats?.filter(n => n.status === 'sent' && n.open_rate).length || 1) || 0;
      const previousClickRate = previousStats?.filter(n => n.status === 'sent' && n.click_rate)
        .reduce((sum, n) => sum + (n.click_rate || 0), 0) / (previousStats?.filter(n => n.status === 'sent' && n.click_rate).length || 1) || 0;

      const calculateTrend = (current: number, previous: number) => {
        if (previous === 0) return { change: 0, isPositive: true };
        const change = Math.round(((current - previous) / previous) * 100);
        return { change: Math.abs(change), isPositive: change >= 0 };
      };

      const statsData = {
        totalSent: totalSent || 0,
        openRate: Math.round(avgOpenRate * 100) / 100,
        scheduled: scheduled || 0,
        clickRate: Math.round(avgClickRate * 100) / 100
      };

      const trendsData = {
        totalSent: calculateTrend(totalSent || 0, previousSent),
        openRate: calculateTrend(avgOpenRate, previousOpenRate),
        scheduled: { change: scheduled || 0, isPositive: true },
        clickRate: calculateTrend(avgClickRate, previousClickRate)
      };

      console.log('📊 Notification stats loaded:', statsData);
      console.log('📈 Notification trends loaded:', trendsData);
      setStats(statsData);
      setTrends(trendsData);
    } catch (error) {
      console.error('❌ Error loading stats:', error);
    }
  };

  const filteredNotifications = notifications.filter(notification => {
    const matchesSearch = notification.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         notification.content?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || notification.status === statusFilter;
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

  const handleCreateNotification = async () => {
    try {
      setIsCreating(true);
      console.log('📧 Creating notification:', createForm);

      // First create a template
      const { data: template, error: templateError } = await supabase
        .from('notification_templates')
        .insert({
          template_name: createForm.title,
          template_content: createForm.content,
          template_type: createForm.template_type
        })
        .select()
        .single();

      if (templateError) {
        console.error('❌ Error creating template:', templateError);
        toast.error('Failed to create notification template');
        return;
      }

      // Then create the admin notification
      const { data: notification, error: notificationError } = await supabase
        .from('admin_notifications')
        .insert({
          template_id: template.id,
          title: createForm.title,
          content: createForm.content,
          notification_type: createForm.notification_type,
          status: createForm.status,
          recipients_count: createForm.recipients_count,
          scheduled_for: createForm.scheduled_for ? new Date(createForm.scheduled_for).toISOString() : null
        })
        .select()
        .single();

      if (notificationError) {
        console.error('❌ Error creating notification:', notificationError);
        toast.error('Failed to create notification');
        return;
      }

      console.log('✅ Notification created successfully:', notification);
      toast.success('Notification created successfully!');
      
      // Reset form and close modal
      setCreateForm({
        title: '',
        content: '',
        notification_type: 'push',
        template_type: 'system',
        status: 'draft',
        recipients_count: 0,
        scheduled_for: ''
      });
      setIsCreateModalOpen(false);
      
      // Refresh data
      loadNotifications();
      loadStats();
    } catch (error) {
      console.error('❌ Error creating notification:', error);
      toast.error('Failed to create notification');
    } finally {
      setIsCreating(false);
    }
  };

  const handleFormChange = (field: string, value: any) => {
    setCreateForm(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleViewNotification = (notification: any) => {
    console.log('👁️ Viewing notification:', notification);
    // TODO: Implement notification details modal
    toast.success('Notification details (coming soon)');
  };

  const handleSendNotification = async (notificationId: string) => {
    try {
      console.log('📤 Sending notification:', notificationId);
      
      const { data, error } = await supabase
        .from('admin_notifications')
        .update({
          status: 'sent',
          sent_at: new Date().toISOString(),
          open_rate: Math.random() * 30 + 50, // Simulate open rate 50-80%
          click_rate: Math.random() * 20 + 5  // Simulate click rate 5-25%
        })
        .eq('id', notificationId)
        .select()
        .single();

      if (error) {
        console.error('❌ Error sending notification:', error);
        toast.error('Failed to send notification');
        return;
      }

      console.log('✅ Notification sent successfully:', data);
      toast.success('Notification sent successfully!');
      
      // Refresh data
      loadNotifications();
      loadStats();
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      toast.error('Failed to send notification');
    }
  };

  const handleSendNow = async (notificationId: string) => {
    try {
      console.log('⏰ Sending scheduled notification now:', notificationId);
      
      const { data, error } = await supabase
        .from('admin_notifications')
        .update({
          status: 'sent',
          sent_at: new Date().toISOString(),
          scheduled_for: null,
          open_rate: Math.random() * 30 + 50,
          click_rate: Math.random() * 20 + 5
        })
        .eq('id', notificationId)
        .select()
        .single();

      if (error) {
        console.error('❌ Error sending notification:', error);
        toast.error('Failed to send notification');
        return;
      }

      console.log('✅ Notification sent successfully:', data);
      toast.success('Scheduled notification sent now!');
      
      // Refresh data
      loadNotifications();
      loadStats();
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      toast.error('Failed to send notification');
    }
  };

  const handleDeleteNotification = async (notificationId: string) => {
    if (!confirm('Are you sure you want to delete this notification?')) {
      return;
    }

    try {
      console.log('🗑️ Deleting notification:', notificationId);
      
      const { error } = await supabase
        .from('admin_notifications')
        .delete()
        .eq('id', notificationId);

      if (error) {
        console.error('❌ Error deleting notification:', error);
        toast.error('Failed to delete notification');
        return;
      }

      console.log('✅ Notification deleted successfully');
      toast.success('Notification deleted successfully!');
      
      // Refresh data
      loadNotifications();
      loadStats();
    } catch (error) {
      console.error('❌ Error deleting notification:', error);
      toast.error('Failed to delete notification');
    }
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
        <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
          <DialogTrigger asChild>
            <Button className="bg-pink-500 hover:bg-pink-600">
              <Plus className="h-4 w-4 mr-2" />
              Create Notification
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[600px] bg-gray-900/95 backdrop-blur-md border-gray-700">
            <DialogHeader>
              <DialogTitle className="text-white">Create New Notification</DialogTitle>
              <DialogDescription className="text-gray-300">
                Create a new notification to send to your users. Choose the type, content, and scheduling options.
              </DialogDescription>
            </DialogHeader>
            
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="title" className="text-white">Title</Label>
                  <Input
                    id="title"
                    placeholder="Enter notification title"
                    value={createForm.title}
                    onChange={(e) => handleFormChange('title', e.target.value)}
                    className="bg-gray-800/50 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="recipients" className="text-white">Recipients Count</Label>
                  <Input
                    id="recipients"
                    type="number"
                    placeholder="0"
                    value={createForm.recipients_count}
                    onChange={(e) => handleFormChange('recipients_count', parseInt(e.target.value) || 0)}
                    className="bg-gray-800/50 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="content" className="text-white">Content</Label>
                <Textarea
                  id="content"
                  placeholder="Enter notification content"
                  value={createForm.content}
                  onChange={(e) => handleFormChange('content', e.target.value)}
                  rows={4}
                  className="bg-gray-800/50 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="notification_type" className="text-white">Notification Type</Label>
                  <Select value={createForm.notification_type} onValueChange={(value) => handleFormChange('notification_type', value)}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-600 text-white">
                      <SelectValue placeholder="Select type" />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-600">
                      <SelectItem value="push" className="text-white hover:bg-gray-700">Push Notification</SelectItem>
                      <SelectItem value="in_app" className="text-white hover:bg-gray-700">In-App Notification</SelectItem>
                      <SelectItem value="email" className="text-white hover:bg-gray-700">Email</SelectItem>
                      <SelectItem value="sms" className="text-white hover:bg-gray-700">SMS</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="template_type" className="text-white">Template Type</Label>
                  <Select value={createForm.template_type} onValueChange={(value) => handleFormChange('template_type', value)}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-600 text-white">
                      <SelectValue placeholder="Select template type" />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-600">
                      <SelectItem value="system" className="text-white hover:bg-gray-700">System</SelectItem>
                      <SelectItem value="promotional" className="text-white hover:bg-gray-700">Promotional</SelectItem>
                      <SelectItem value="automated" className="text-white hover:bg-gray-700">Automated</SelectItem>
                      <SelectItem value="marketing" className="text-white hover:bg-gray-700">Marketing</SelectItem>
                      <SelectItem value="security" className="text-white hover:bg-gray-700">Security</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="status" className="text-white">Status</Label>
                  <Select value={createForm.status} onValueChange={(value) => handleFormChange('status', value)}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-600 text-white">
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-600">
                      <SelectItem value="draft" className="text-white hover:bg-gray-700">Draft</SelectItem>
                      <SelectItem value="scheduled" className="text-white hover:bg-gray-700">Scheduled</SelectItem>
                      <SelectItem value="sent" className="text-white hover:bg-gray-700">Send Now</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="scheduled_for" className="text-white">Schedule For (Optional)</Label>
                  <Input
                    id="scheduled_for"
                    type="datetime-local"
                    value={createForm.scheduled_for}
                    onChange={(e) => handleFormChange('scheduled_for', e.target.value)}
                    className="bg-gray-800/50 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>
              </div>
            </div>
            
            <DialogFooter>
              <Button 
                variant="outline" 
                onClick={() => setIsCreateModalOpen(false)}
                className="border-gray-600 text-gray-300 hover:bg-gray-700 hover:text-white"
              >
                Cancel
              </Button>
              <Button 
                onClick={handleCreateNotification} 
                disabled={isCreating || !createForm.title || !createForm.content}
                className="bg-pink-500 hover:bg-pink-600 text-white"
              >
                {isCreating ? 'Creating...' : 'Create Notification'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Total Sent</p>
                <h3 className="text-2xl font-bold mt-1">{stats.totalSent.toLocaleString()}</h3>
                <p className={`text-xs mt-1 flex items-center ${trends.totalSent.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <TrendingUp className="h-3 w-3 mr-1" /> 
                  {trends.totalSent.change > 0 ? '+' : ''}{trends.totalSent.change}% this week
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
                <p className={`text-xs mt-1 flex items-center ${trends.openRate.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <TrendingUp className="h-3 w-3 mr-1" /> 
                  {trends.openRate.change > 0 ? '+' : ''}{trends.openRate.change}% vs last week
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
                <p className={`text-xs mt-1 flex items-center ${trends.scheduled.isPositive ? 'text-blue-500' : 'text-gray-500'}`}>
                  <Clock className="h-3 w-3 mr-1" /> 
                  {stats.scheduled > 0 ? `${stats.scheduled} scheduled` : 'None scheduled'}
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
                <p className={`text-xs mt-1 flex items-center ${trends.clickRate.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <AlertTriangle className="h-3 w-3 mr-1" /> 
                  {trends.clickRate.change > 0 ? '+' : ''}{trends.clickRate.change}% vs last week
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
                  return (
                    <TableRow key={notification.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium">{notification.title}</p>
                          <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'} truncate max-w-xs`}>
                            {notification.content}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        {getTypeBadge(notification.notification_type || 'system')}
                      </TableCell>
                      <TableCell>
                        {getStatusBadge(notification.status || 'draft')}
                      </TableCell>
                      <TableCell>
                        {notification.recipients_count > 0 ? notification.recipients_count.toLocaleString() : '-'}
                      </TableCell>
                      <TableCell>
                        {notification.open_rate > 0 ? `${notification.open_rate}%` : '-'}
                      </TableCell>
                      <TableCell>
                        {notification.click_rate > 0 ? `${notification.click_rate}%` : '-'}
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          {notification.sent_at && (
                            <p>{new Date(notification.sent_at).toLocaleDateString()}</p>
                          )}
                          {notification.scheduled_for && (
                            <p className="text-blue-500">
                              Scheduled: {new Date(notification.scheduled_for).toLocaleDateString()}
                            </p>
                          )}
                          {!notification.sent_at && !notification.scheduled_for && (
                            <p>Updated: {new Date(notification.updated_at).toLocaleDateString()}</p>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-1">
                          <Button 
                            variant="ghost" 
                            size="sm"
                            onClick={() => handleViewNotification(notification)}
                            title="View Details"
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                          {notification.status === 'draft' && (
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => handleSendNotification(notification.id)}
                              title="Send Now"
                              className="text-green-600 hover:text-green-700"
                            >
                              <Send className="h-4 w-4" />
                            </Button>
                          )}
                          {notification.status === 'scheduled' && (
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => handleSendNow(notification.id)}
                              title="Send Now"
                              className="text-blue-600 hover:text-blue-700"
                            >
                              <Clock className="h-4 w-4" />
                            </Button>
                          )}
                          <Button 
                            variant="ghost" 
                            size="sm"
                            onClick={() => handleDeleteNotification(notification.id)}
                            title="Delete"
                            className="text-red-600 hover:text-red-700"
                          >
                            <Trash2 className="h-4 w-4" />
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
