import React, { useState, useEffect } from 'react';
import {
  Heart, Menu, Search, Globe, Sun, Moon, Bell, User, Users, Shield,
  CreditCard, MessageSquare, BellRing, BarChart3, Settings as SettingsIcon, ChevronDown,
  ChevronLeft, ChevronRight, TrendingUp, AlertTriangle, CheckCircle,
  XCircle, ArrowUp, Flag, Crown, IndianRupee, X, Activity
} from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import * as echarts from 'echarts';
import { supabase } from '../admin-integrations/supabase/client';
import UserManagement from './UserManagement';
import ContentModeration from './ContentModeration';
import SubscriptionManagement from './SubscriptionManagement';
import CommunicationLogs from './CommunicationLogs';
import Notifications from './Notifications';
import Analytics from './Analytics';
import Settings from './Settings';
import SystemHealth from './SystemHealth';

interface AdminDashboardProps {
  onLogout: () => void;
}

interface DashboardStats {
  totalUsers: number;
  activeSubscriptions: number;
  totalRevenue: number;
  reportedContent: number;
  pendingReports: number;
  totalMatches: number;
  messagesSent: number;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({ onLogout }) => {
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [activeModule, setActiveModule] = useState("dashboard");
  const [language, setLanguage] = useState("english");
  const [dashboardStats, setDashboardStats] = useState<DashboardStats>({
    totalUsers: 0,
    activeSubscriptions: 0,
    totalRevenue: 0,
    reportedContent: 0,
    pendingReports: 0,
    totalMatches: 0,
    messagesSent: 0
  });
  const [isLoading, setIsLoading] = useState(true);

  const toggleDarkMode = () => {
    setIsDarkMode(!isDarkMode);
  };

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  const handleModuleChange = (moduleId: string) => {
    setActiveModule(moduleId);
    setIsMobileMenuOpen(false); // Close mobile menu when selecting a module
  };

  // Fetch dashboard statistics
  const fetchDashboardStats = async () => {
    try {
      setIsLoading(true);
      
      // Get total users count
      const { count: totalUsers } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true });

      // Get active subscriptions count
      const { count: activeSubscriptions } = await supabase
        .from('user_subscriptions')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'active');

      // Get pending reports count
      const { count: pendingReports } = await supabase
        .from('reports')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      // Get total matches count
      const { count: totalMatches } = await supabase
        .from('matches')
        .select('*', { count: 'exact', head: true });

      // Get messages count
      const { count: messagesSent } = await supabase
        .from('messages')
        .select('*', { count: 'exact', head: true });

      // Get revenue from subscription analytics
      const { data: revenueData } = await supabase
        .from('user_analytics')
        .select('revenue')
        .order('date', { ascending: false })
        .limit(30);

      const totalRevenue = revenueData?.reduce((sum, day) => sum + parseFloat(day.revenue.toString()), 0) || 0;

      setDashboardStats({
        totalUsers: totalUsers || 0,
        activeSubscriptions: activeSubscriptions || 0,
        totalRevenue,
        reportedContent: pendingReports || 0,
        pendingReports: pendingReports || 0,
        totalMatches: totalMatches || 0,
        messagesSent: messagesSent || 0
      });

    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Fetch stats on component mount
  useEffect(() => {
    fetchDashboardStats();
  }, []);

  // Chart initialization
  useEffect(() => {
    // Only initialize charts on dashboard and if elements exist
    if (activeModule === 'dashboard') {
      setTimeout(() => {
        const userActivityElement = document.getElementById('user-activity-chart');
        const revenueElement = document.getElementById('revenue-chart');
        
        if (userActivityElement && revenueElement) {
          const userActivityChart = echarts.init(userActivityElement);
          const revenueChart = echarts.init(revenueElement);
          
          const userActivityOption = {
            animation: false,
            tooltip: {
              trigger: 'axis'
            },
            legend: {
              data: ['Swipes', 'Matches', 'Messages']
            },
            grid: {
              left: '3%',
              right: '4%',
              bottom: '3%',
              containLabel: true
            },
            xAxis: {
              type: 'category',
              boundaryGap: false,
              data: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            },
            yAxis: {
              type: 'value'
            },
            series: [
              {
                name: 'Swipes',
                type: 'line',
                data: [120, 132, 101, 134, 90, 230, 210],
                smooth: true,
                lineStyle: {
                  width: 3,
                  color: '#ec4899'
                }
              },
              {
                name: 'Matches',
                type: 'line',
                data: [45, 52, 39, 64, 36, 80, 70],
                smooth: true,
                lineStyle: {
                  width: 3,
                  color: '#8b5cf6'
                }
              },
              {
                name: 'Messages',
                type: 'line',
                data: [32, 38, 30, 45, 27, 60, 48],
                smooth: true,
                lineStyle: {
                  width: 3,
                  color: '#06b6d4'
                }
              }
            ]
          };

          const revenueOption = {
            animation: false,
            tooltip: {
              trigger: 'axis',
              axisPointer: {
                type: 'shadow'
              }
            },
            legend: {
              data: ['Premium', 'Basic', 'One-time']
            },
            grid: {
              left: '3%',
              right: '4%',
              bottom: '3%',
              containLabel: true
            },
            xAxis: {
              type: 'category',
              data: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
            },
            yAxis: {
              type: 'value'
            },
            series: [
              {
                name: 'Premium',
                type: 'bar',
                stack: 'total',
                data: [320, 332, 301, 334, 390, 330],
                itemStyle: { color: '#ec4899' }
              },
              {
                name: 'Basic',
                type: 'bar',
                stack: 'total',
                data: [120, 132, 101, 134, 90, 230],
                itemStyle: { color: '#8b5cf6' }
              },
              {
                name: 'One-time',
                type: 'bar',
                stack: 'total',
                data: [220, 182, 191, 234, 290, 330],
                itemStyle: { color: '#06b6d4' }
              }
            ]
          };

          userActivityChart.setOption(userActivityOption);
          revenueChart.setOption(revenueOption);

          const handleResize = () => {
            userActivityChart.resize();
            revenueChart.resize();
          };

          window.addEventListener('resize', handleResize);

          return () => {
            window.removeEventListener('resize', handleResize);
            userActivityChart.dispose();
            revenueChart.dispose();
          };
        }
      }, 100);
    }
  }, [activeModule]);

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'users', label: 'User Management', icon: Users },
    { id: 'content', label: 'Content Moderation', icon: Shield },
    { id: 'subscription', label: 'Subscription', icon: CreditCard },
    { id: 'communication', label: 'Communication Logs', icon: MessageSquare },
    { id: 'notifications', label: 'Notifications', icon: BellRing },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
    { id: 'system-health', label: 'System Health', icon: Activity },
    { id: 'security', label: 'Settings', icon: SettingsIcon },
  ];

  return (
    <div className={`min-h-screen ${isDarkMode ? 'bg-gray-900 text-white' : 'bg-gray-50 text-gray-900'}`}>
      {/* Mobile Menu Overlay */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar - Desktop */}
      <div className={`hidden lg:fixed lg:top-0 lg:left-0 lg:h-full lg:flex lg:flex-col ${isDarkMode ? 'bg-gray-800' : 'bg-white'} lg:w-72 shadow-lg z-30`}>
        {/* Logo */}
        <div className={`flex items-center justify-between ${isDarkMode ? 'bg-gray-900' : 'bg-gradient-to-r from-pink-500 to-purple-600'} h-16 px-4`}>
          <div className="flex items-center">
            <Heart className="text-white h-8 w-8 fill-white mr-3" />
            <span className="text-white font-semibold text-xl">Love Bug</span>
          </div>
        </div>

        {/* Admin Profile */}
        <div className={`flex items-center py-4 px-4 ${isDarkMode ? 'border-gray-700' : 'border-gray-200'} border-b`}>
          <div className="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center">
            <User className="text-white h-5 w-5" />
          </div>
          <div className="ml-3">
            <p className={`font-medium ${isDarkMode ? 'text-white' : 'text-gray-800'}`}>Admin User</p>
            <p className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Super Admin</p>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 mt-4 overflow-y-auto">
          <ul className="space-y-1 px-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <li key={item.id}>
                  <Button
                    variant="ghost"
                    className={`flex items-center w-full justify-start py-3 px-4 ${
                      activeModule === item.id 
                        ? (isDarkMode ? 'bg-gray-700 text-white' : 'bg-pink-50 text-pink-600') 
                        : 'hover:bg-gray-100 dark:hover:bg-gray-700'
                    }`}
                    onClick={() => handleModuleChange(item.id)}
                  >
                    <Icon className="h-5 w-5 mr-3" />
                    <span>{item.label}</span>
                  </Button>
                </li>
              );
            })}
          </ul>
        </nav>
      </div>

      {/* Sidebar - Mobile */}
      <div className={`fixed top-0 left-0 h-full w-80 max-w-sm transform transition-transform duration-300 ease-in-out z-50 lg:hidden ${
        isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
      } ${isDarkMode ? 'bg-gray-800' : 'bg-white'} shadow-lg`}>
        {/* Mobile Logo */}
        <div className={`flex items-center justify-between ${isDarkMode ? 'bg-gray-900' : 'bg-gradient-to-r from-pink-500 to-purple-600'} h-16 px-4`}>
          <div className="flex items-center">
            <Heart className="text-white h-8 w-8 fill-white mr-3" />
            <span className="text-white font-semibold text-xl">Love Bug</span>
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="text-white hover:bg-white/20"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Mobile Admin Profile */}
        <div className={`flex items-center py-4 px-4 ${isDarkMode ? 'border-gray-700' : 'border-gray-200'} border-b`}>
          <div className="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center">
            <User className="text-white h-5 w-5" />
          </div>
          <div className="ml-3">
            <p className={`font-medium ${isDarkMode ? 'text-white' : 'text-gray-800'}`}>Admin User</p>
            <p className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Super Admin</p>
          </div>
        </div>

        {/* Mobile Navigation */}
        <nav className="flex-1 mt-4 overflow-y-auto">
          <ul className="space-y-1 px-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <li key={item.id}>
                  <Button
                    variant="ghost"
                    className={`flex items-center w-full justify-start py-3 px-4 ${
                      activeModule === item.id 
                        ? (isDarkMode ? 'bg-gray-700 text-white' : 'bg-pink-50 text-pink-600') 
                        : 'hover:bg-gray-100 dark:hover:bg-gray-700'
                    }`}
                    onClick={() => handleModuleChange(item.id)}
                  >
                    <Icon className="h-5 w-5 mr-3" />
                    <span>{item.label}</span>
                  </Button>
                </li>
              );
            })}
          </ul>
        </nav>
      </div>

      {/* Main Content */}
      <div className="lg:ml-72">
        {/* Header */}
        <header className={`h-16 ${isDarkMode ? 'bg-gray-800' : 'bg-white'} shadow-sm flex items-center px-4 lg:px-6 sticky top-0 z-20`}>
          {/* Mobile Menu Button */}
          <Button
            variant="ghost"
            size="sm"
            className="lg:hidden mr-3"
            onClick={toggleMobileMenu}
          >
            <Menu className="h-5 w-5" />
          </Button>

          <h1 className="text-lg lg:text-xl font-semibold truncate">
            {navItems.find(item => item.id === activeModule)?.label || 'Dashboard'}
          </h1>

          {/* Search Bar - Hidden on small mobile, visible on larger screens */}
          <div className={`hidden sm:flex ml-4 lg:ml-8 relative ${isDarkMode ? 'bg-gray-700' : 'bg-gray-100'} rounded-lg flex-grow max-w-md`}>
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <Input 
              type="text" 
              placeholder="Search..." 
              className={`w-full py-2 pl-10 pr-4 border-none focus:ring-2 focus:ring-pink-500 ${isDarkMode ? 'bg-gray-700 text-white' : 'bg-gray-100 text-gray-700'}`}
            />
          </div>

          {/* Right Section */}
          <div className="ml-auto flex items-center space-x-2 lg:space-x-4">
            {/* Theme Toggle */}
            <Button 
              variant="ghost"
              size="sm"
              onClick={toggleDarkMode}
              className={`p-2 rounded-full ${isDarkMode ? 'bg-gray-700 text-yellow-400' : 'bg-gray-100 text-gray-700'}`}
            >
              {isDarkMode ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </Button>

            {/* Notifications */}
            <Button variant="ghost" size="sm" className={`p-2 rounded-full ${isDarkMode ? 'bg-gray-700' : 'bg-gray-100'} relative`}>
              <Bell className="h-4 w-4" />
              <Badge className="absolute -top-1 -right-1 bg-red-500 text-white text-xs h-5 w-5 flex items-center justify-center p-0">
                3
              </Badge>
            </Button>

            {/* Profile Dropdown - Simplified on mobile */}
            <div className="relative">
              <Button variant="ghost" className="flex items-center space-x-1 lg:space-x-2">
                <div className="w-6 h-6 lg:w-8 lg:h-8 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center">
                  <User className="text-white h-3 w-3 lg:h-4 lg:w-4" />
                </div>
                <span className="hidden sm:inline">Admin</span>
                <ChevronDown className="h-3 w-3 lg:h-4 lg:w-4" />
              </Button>
            </div>

            <Button 
              variant="outline" 
              size="sm"
              onClick={onLogout}
              className="text-red-600 border-red-200 hover:bg-red-50 text-xs lg:text-sm px-2 lg:px-3"
            >
              Logout
            </Button>
          </div>
        </header>

        {/* Dashboard Content */}
        <main className="p-4 lg:p-6">
          {activeModule === 'users' && (
            <UserManagement isDarkMode={isDarkMode} />
          )}

          {activeModule === 'content' && (
            <ContentModeration isDarkMode={isDarkMode} />
          )}

          {activeModule === 'subscription' && (
            <SubscriptionManagement isDarkMode={isDarkMode} />
          )}

          {activeModule === 'communication' && (
            <CommunicationLogs isDarkMode={isDarkMode} />
          )}

          {activeModule === 'notifications' && (
            <Notifications isDarkMode={isDarkMode} />
          )}

          {activeModule === 'analytics' && (
            <Analytics isDarkMode={isDarkMode} />
          )}

          {activeModule === 'system-health' && (
            <SystemHealth />
          )}

          {activeModule === 'security' && (
            <Settings isDarkMode={isDarkMode} />
          )}

          {activeModule === 'dashboard' && (
            <div>
              {/* Stats Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6 mb-6">
                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardContent className="p-4 lg:p-6">
                    <div className="flex justify-between items-center">
                      <div>
                        <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Total Users</p>
                        <h3 className="text-xl lg:text-2xl font-bold mt-1">
                          {isLoading ? '-' : dashboardStats.totalUsers.toLocaleString()}
                        </h3>
                        <p className="text-xs text-green-500 mt-1 flex items-center">
                          <ArrowUp className="h-3 w-3 mr-1" /> 12% from last month
                        </p>
                      </div>
                      <div className={`w-10 h-10 lg:w-12 lg:h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-pink-900' : 'bg-pink-100'}`}>
                        <Users className="text-pink-600 h-5 w-5 lg:h-6 lg:w-6" />
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardContent className="p-4 lg:p-6">
                    <div className="flex justify-between items-center">
                      <div>
                        <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Active Subscriptions</p>
                        <h3 className="text-xl lg:text-2xl font-bold mt-1">
                          {isLoading ? '-' : dashboardStats.activeSubscriptions.toLocaleString()}
                        </h3>
                        <p className="text-xs text-green-500 mt-1 flex items-center">
                          <ArrowUp className="h-3 w-3 mr-1" /> 8% from last month
                        </p>
                      </div>
                      <div className={`w-10 h-10 lg:w-12 lg:h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-purple-900' : 'bg-purple-100'}`}>
                        <Crown className="text-purple-600 h-5 w-5 lg:h-6 lg:w-6" />
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardContent className="p-4 lg:p-6">
                    <div className="flex justify-between items-center">
                      <div>
                        <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Revenue (Monthly)</p>
                        <h3 className="text-xl lg:text-2xl font-bold mt-1">
                          ₹{isLoading ? '-' : Math.round(dashboardStats.totalRevenue).toLocaleString()}
                        </h3>
                        <p className="text-xs text-green-500 mt-1 flex items-center">
                          <ArrowUp className="h-3 w-3 mr-1" /> 15% from last month
                        </p>
                      </div>
                      <div className={`w-10 h-10 lg:w-12 lg:h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                        <IndianRupee className="text-green-600 h-5 w-5 lg:h-6 lg:w-6" />
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardContent className="p-4 lg:p-6">
                    <div className="flex justify-between items-center">
                      <div>
                        <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Content Reports</p>
                        <h3 className="text-xl lg:text-2xl font-bold mt-1">
                          {isLoading ? '-' : dashboardStats.reportedContent.toLocaleString()}
                        </h3>
                        <p className="text-xs text-red-500 mt-1 flex items-center">
                          <TrendingUp className="h-3 w-3 mr-1" /> 24% from last month
                        </p>
                      </div>
                      <div className={`w-10 h-10 lg:w-12 lg:h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-red-900' : 'bg-red-100'}`}>
                        <Flag className="text-red-600 h-5 w-5 lg:h-6 lg:w-6" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Charts */}
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 lg:gap-6 mb-6">
                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardHeader>
                    <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-2">
                      <CardTitle className="text-lg">User Activity</CardTitle>
                      <div className="flex space-x-2">
                        <Button size="sm" variant="outline" className="text-xs">Week</Button>
                        <Button size="sm" className="bg-pink-500 hover:bg-pink-600 text-xs">Month</Button>
                        <Button size="sm" variant="outline" className="text-xs">Year</Button>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div id="user-activity-chart" className="w-full h-64 lg:h-80"></div>
                  </CardContent>
                </Card>

                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardHeader>
                    <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-2">
                      <CardTitle className="text-lg">Revenue Breakdown</CardTitle>
                      <div className="flex space-x-2">
                        <Button size="sm" variant="outline" className="text-xs">Week</Button>
                        <Button size="sm" className="bg-pink-500 hover:bg-pink-600 text-xs">Month</Button>
                        <Button size="sm" variant="outline" className="text-xs">Year</Button>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div id="revenue-chart" className="w-full h-64 lg:h-80"></div>
                  </CardContent>
                </Card>
              </div>

              {/* Recent Activity & System Status */}
              <div className="grid grid-cols-1 xl:grid-cols-3 gap-4 lg:gap-6">
                <Card className={`xl:col-span-2 ${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardHeader>
                    <div className="flex justify-between items-center">
                      <CardTitle>Recent Activity</CardTitle>
                      <Button variant="ghost" size="sm" className="text-pink-600 text-xs">View All</Button>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className={`p-3 lg:p-4 rounded-lg ${isDarkMode ? 'bg-gray-700' : 'bg-gray-50'}`}>
                        <div className="flex items-start">
                          <div className={`w-8 h-8 lg:w-10 lg:h-10 rounded-full flex items-center justify-center flex-shrink-0 ${isDarkMode ? 'bg-red-900' : 'bg-red-100'}`}>
                            <Flag className="text-red-600 h-4 w-4 lg:h-5 lg:w-5" />
                          </div>
                          <div className="ml-3 lg:ml-4 flex-1 min-w-0">
                            <p className="font-medium text-sm lg:text-base">Content reported by multiple users</p>
                            <p className={`text-xs lg:text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'} truncate`}>User ID: 8723 posted inappropriate content</p>
                            <div className="flex items-center mt-2 flex-wrap gap-2">
                              <Badge variant="destructive" className="text-xs">High Priority</Badge>
                              <span className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>2 minutes ago</span>
                            </div>
                          </div>
                          <Button size="sm" variant="ghost" className="text-pink-600 text-xs flex-shrink-0">Review</Button>
                        </div>
                      </div>

                      <div className={`p-3 lg:p-4 rounded-lg ${isDarkMode ? 'bg-gray-700' : 'bg-gray-50'}`}>
                        <div className="flex items-start">
                          <div className={`w-8 h-8 lg:w-10 lg:h-10 rounded-full flex items-center justify-center flex-shrink-0 ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                            <CreditCard className="text-green-600 h-4 w-4 lg:h-5 lg:w-5" />
                          </div>
                          <div className="ml-3 lg:ml-4 flex-1 min-w-0">
                            <p className="font-medium text-sm lg:text-base">New subscription purchase</p>
                            <p className={`text-xs lg:text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'} truncate`}>User ID: 5642 purchased Premium plan (6 months)</p>
                            <div className="flex items-center mt-2 flex-wrap gap-2">
                              <Badge className="bg-green-100 text-green-600 text-xs">Payment Success</Badge>
                              <span className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>15 minutes ago</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
                  <CardHeader>
                    <div className="flex justify-between items-center">
                      <CardTitle className="text-lg">System Status</CardTitle>
                      <Badge className="bg-green-100 text-green-600 text-xs">All Systems Operational</Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div>
                        <div className="flex justify-between items-center mb-1">
                          <p className="text-sm">API Services</p>
                          <span className="text-xs text-green-500">99.9% Uptime</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <div className="bg-green-500 h-2 rounded-full" style={{ width: '99.9%' }}></div>
                        </div>
                      </div>

                      <div>
                        <div className="flex justify-between items-center mb-1">
                          <p className="text-sm">Database</p>
                          <span className="text-xs text-green-500">100% Uptime</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <div className="bg-green-500 h-2 rounded-full" style={{ width: '100%' }}></div>
                        </div>
                      </div>

                      <div className="pt-4 border-t border-gray-200">
                        <h4 className="text-sm font-medium mb-2">Recent Incidents</h4>
                        <div className={`p-3 rounded-lg text-sm ${isDarkMode ? 'bg-gray-700' : 'bg-gray-50'}`}>
                          <p className="font-medium">Minor notification delay</p>
                          <p className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>May 28, 2025 - Resolved</p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>
          )}

          {activeModule !== 'dashboard' && activeModule !== 'users' && activeModule !== 'content' && activeModule !== 'subscription' && activeModule !== 'communication' && activeModule !== 'notifications' && activeModule !== 'analytics' && activeModule !== 'system-health' && activeModule !== 'security' && (
            <div className="text-center py-12">
              <h2 className="text-2xl font-semibold mb-4">
                {navItems.find(item => item.id === activeModule)?.label}
              </h2>
              <p className="text-gray-500">This module is under development.</p>
            </div>
          )}
        </main>
      </div>
    </div>
  );
};

export default AdminDashboard;
