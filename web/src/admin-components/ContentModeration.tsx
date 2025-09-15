import React, { useState, useEffect } from 'react';
import {
  AlertTriangle, Eye, EyeOff, Flag, Shield, CheckCircle, XCircle,
  Clock, User, Calendar, Search, Filter, MoreVertical, Ban, Trash2,
  MessageSquare, Image, Heart, UserX, AlertCircle
} from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from './ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from './ui/dropdown-menu';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from './ui/sheet';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from './ui/dialog';
import { supabase } from '../admin-integrations/supabase/client';
import { toast } from 'sonner';

interface ContentModerationProps {
  isDarkMode: boolean;
}

interface ModerationQueueItem {
  id: string;
  content_type: string;
  content_id: string;
  reported_user_id: string;
  reporter_user_id: string;
  reason: string;
  description: string;
  priority: string;
  status: string;
  auto_flagged: boolean;
  confidence_score: number;
  created_at: string;
  reported_user?: {
    name: string;
  };
  reporter_user?: {
    name: string;
  };
}

interface BannedUser {
  id: string;
  user_id: string;
  ban_type: string;
  reason: string;
  description: string;
  expires_at: string;
  is_active: boolean;
  created_at: string;
  profiles?: {
    name: string;
  };
}

interface ModerationStats {
  pendingReports: number;
  autoFlagged: number;
  resolvedToday: number;
  bannedUsers: number;
}

const ContentModeration: React.FC<ContentModerationProps> = ({ isDarkMode }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [selectedReport, setSelectedReport] = useState<ModerationQueueItem | null>(null);
  const [moderationQueue, setModerationQueue] = useState<ModerationQueueItem[]>([]);
  const [bannedUsers, setBannedUsers] = useState<BannedUser[]>([]);
  const [stats, setStats] = useState<ModerationStats>({
    pendingReports: 0,
    autoFlagged: 0,
    resolvedToday: 0,
    bannedUsers: 0
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isActionLoading, setIsActionLoading] = useState(false);

  // Fetch moderation queue and statistics
  const fetchModerationData = async () => {
    try {
      setIsLoading(true);

      // Fetch reports data first
      const { data: queueData, error: queueError } = await supabase
        .from('reports')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (queueError) {
        console.error('Error fetching moderation queue:', queueError);
        toast.error('Failed to fetch moderation data');
        return;
      }

      console.log('Fetched reports data:', queueData);
      console.log('Number of reports:', queueData?.length || 0);
      setModerationQueue(queueData || []);

      // Fetch banned users
      const { data: bannedData, error: bannedError } = await supabase
        .from('banned_users')
        .select(`
          *,
          profiles!user_id(name)
        `)
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (bannedError) {
        console.error('Error fetching banned users:', bannedError);
      } else {
        setBannedUsers(bannedData || []);
      }

      // Calculate statistics
      const pendingReports = queueData?.filter(item => item.status === 'pending').length || 0;
      const autoFlagged = queueData?.filter(item => item.auto_flagged && item.status === 'pending').length || 0;
      const resolvedReports = queueData?.filter(item => item.status === 'resolved' || item.status === 'approved' || item.status === 'banned').length || 0;
      const bannedReports = queueData?.filter(item => item.status === 'banned').length || 0;
      
      console.log('Stats calculation:', {
        totalReports: queueData?.length || 0,
        pendingReports,
        autoFlagged,
        resolvedReports,
        bannedReports
      });

      setStats({
        pendingReports,
        autoFlagged,
        resolvedToday: resolvedReports, // Use resolved count from current data
        bannedUsers: bannedReports // Now showing banned reports count instead of unique banned users
      });

    } catch (error) {
      console.error('Error fetching moderation data:', error);
      toast.error('Failed to fetch moderation data');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchModerationData();
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline" className="text-yellow-600 border-yellow-200">Pending</Badge>;
      case 'approved':
        return <Badge className="bg-green-100 text-green-600">Approved</Badge>;
      case 'resolved':
        return <Badge className="bg-green-100 text-green-600">Resolved</Badge>;
      case 'banned':
        return <Badge className="bg-red-100 text-red-600">Banned</Badge>;
      case 'dismissed':
        return <Badge variant="secondary">Dismissed</Badge>;
      case 'in_review':
        return <Badge className="bg-blue-100 text-blue-600">In Review</Badge>;
      default:
        return <Badge variant="outline">Unknown</Badge>;
    }
  };

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'critical':
        return <Badge className="bg-red-600 text-white">Critical</Badge>;
      case 'high':
        return <Badge variant="destructive">High</Badge>;
      case 'medium':
        return <Badge className="bg-orange-100 text-orange-600">Medium</Badge>;
      case 'low':
        return <Badge className="bg-blue-100 text-blue-600">Low</Badge>;
      default:
        return <Badge variant="outline">Unknown</Badge>;
    }
  };

  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'profile':
        return <User className="h-4 w-4" />;
      case 'message':
        return <MessageSquare className="h-4 w-4" />;
      case 'photo':
      case 'image':
        return <Image className="h-4 w-4" />;
      case 'story':
        return <Heart className="h-4 w-4" />;
      default:
        return <AlertTriangle className="h-4 w-4" />;
    }
  };

  const handleModerationAction = async (queueItemId: string, action: 'approve' | 'remove' | 'ban' | 'unban' | 'dismiss') => {
    try {
      setIsActionLoading(true);
      
      console.log('Handling action:', action, 'for report ID:', queueItemId);
      
      const queueItem = moderationQueue.find(item => item.id === queueItemId);
      if (!queueItem) {
        console.error('Report not found:', queueItemId);
        toast.error('Report not found');
        return;
      }

      // Update moderation queue status
      let newStatus = 'resolved';
      if (action === 'approve') {
        newStatus = 'approved';
      } else if (action === 'dismiss') {
        newStatus = 'dismissed';
      } else if (action === 'ban') {
        newStatus = 'banned'; // Ban user and mark report as banned
      } else if (action === 'unban') {
        newStatus = 'resolved'; // Unban user and mark report as resolved
      }

      console.log('Updating report status to:', newStatus);

      // Simple update to reports table
      console.log('=== DATABASE UPDATE DEBUG ===');
      console.log('Report ID to update:', queueItemId);
      console.log('New status to set:', newStatus);
      console.log('Attempting to update report in database...');
      
      const { data: updateData, error: updateError } = await supabase
        .from('reports')
        .update({
          status: newStatus
        })
        .eq('id', queueItemId)
        .select();

      console.log('Supabase response - data:', updateData);
      console.log('Supabase response - error:', updateError);

      if (updateError) {
        console.error('❌ DATABASE UPDATE FAILED:', updateError);
        console.error('Error details:', {
          message: updateError.message,
          details: updateError.details,
          hint: updateError.hint,
          code: updateError.code
        });
        toast.error(`Failed to update report: ${updateError.message}`);
        return;
      }

      if (!updateData || updateData.length === 0) {
        console.error('❌ NO DATA RETURNED - Report not found or not updated');
        toast.error('Report not found or not updated');
        return;
      }

      console.log('✅ DATABASE UPDATE SUCCESSFUL');
      console.log('Updated report data:', updateData[0]);
      console.log('=== END DATABASE UPDATE DEBUG ===');

      // Handle ban user action
      if (action === 'ban') {
        console.log('=== BAN USER DEBUG ===');
        console.log('Banning user:', queueItem.reported_id);
        
        try {
          // Get current user ID from Supabase session
          const { data: { user } } = await supabase.auth.getUser();
          const adminUserId = user?.id || '00000000-0000-0000-0000-000000000000';
          
          console.log('Using admin user ID for ban:', adminUserId);
          
          // Insert into banned_users table
          const { data: banData, error: banError } = await supabase
            .from('banned_users')
            .insert({
              user_id: queueItem.reported_id,
              banned_by: adminUserId, // Use actual admin UUID
              ban_type: 'permanent',
              reason: queueItem.reason,
              description: queueItem.description,
              is_active: true
            })
            .select();

          console.log('Ban user response:', { banData, banError });

          if (banError) {
            console.error('❌ BAN USER FAILED:', banError);
            toast.error(`Failed to ban user: ${banError.message}`);
            // Don't return here - still update the report status
          } else {
            console.log('✅ USER BANNED SUCCESSFULLY');
            toast.success('User banned successfully');
          }
        } catch (banError) {
          console.error('❌ BAN USER ERROR:', banError);
          toast.error('Failed to ban user');
        }
        console.log('=== END BAN USER DEBUG ===');
      }

      // Handle unban user action
      if (action === 'unban') {
        console.log('=== UNBAN USER DEBUG ===');
        console.log('Unbanning user:', queueItem.reported_id);
        
        try {
          const { data: unbanData, error: unbanError } = await supabase
            .from('banned_users')
            .update({ is_active: false })
            .eq('user_id', queueItem.reported_id)
            .select();

          console.log('Unban user response:', { unbanData, unbanError });

          if (unbanError) {
            console.error('❌ UNBAN USER FAILED:', unbanError);
            toast.error(`Failed to unban user: ${unbanError.message}`);
          } else {
            console.log('✅ USER UNBANNED SUCCESSFULLY');
            toast.success('User unbanned successfully');
          }
        } catch (unbanError) {
          console.error('❌ UNBAN USER ERROR:', unbanError);
          toast.error('Failed to unban user');
        }
        console.log('=== END UNBAN USER DEBUG ===');
      }

      // Update local state immediately for better UX
      setModerationQueue(prev => {
        console.log('Before update - moderationQueue:', prev);
        console.log('Looking for item with ID:', queueItemId);
        
        const updated = prev.map(item => {
          if (item.id === queueItemId) {
            console.log('Found item to update:', item);
            const updatedItem = { ...item, status: newStatus };
            console.log('Updated item:', updatedItem);
            return updatedItem;
          }
          return item;
        });
        
        console.log('After update - moderationQueue:', updated);
        return updated;
      });

      // Update selectedReport if it's the same report
      if (selectedReport && selectedReport.id === queueItemId) {
        console.log('Updating selectedReport status to:', newStatus);
        setSelectedReport(prev => ({
          ...prev,
          status: newStatus
        }));
      }

      // Update stats based on new status
      setStats(prev => {
        const newStats = {
          ...prev,
          pendingReports: (newStatus === 'resolved' || newStatus === 'dismissed' || newStatus === 'approved' || newStatus === 'banned') ? prev.pendingReports - 1 : prev.pendingReports,
          resolvedToday: (newStatus === 'resolved' || newStatus === 'approved' || newStatus === 'banned') ? prev.resolvedToday + 1 : prev.resolvedToday,
          bannedUsers: newStatus === 'banned' ? prev.bannedUsers + 1 : (action === 'unban' ? Math.max(0, prev.bannedUsers - 1) : prev.bannedUsers)
        };
        console.log('Updated stats:', newStats);
        return newStats;
      });

      toast.success(`Report ${action}ed successfully`);
      
      // Don't refresh data immediately - let the local state update show first
      // await fetchModerationData();

    } catch (error) {
      console.error('Error handling moderation action:', error);
      toast.error('Failed to process action');
    } finally {
      setIsActionLoading(false);
    }
  };

  const filteredReports = moderationQueue.filter(report => {
    const reportedUserName = report.reported_user?.name || 'Unknown User';
    const matchesSearch = report.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         reportedUserName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         report.reason.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = selectedFilter === 'all' || report.status === selectedFilter;
    return matchesSearch && matchesFilter;
  });

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return 'Less than 1 hour ago';
    if (diffInHours < 24) return `${diffInHours} hours ago`;
    
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays === 1) return '1 day ago';
    if (diffInDays < 7) return `${diffInDays} days ago`;
    
    return date.toLocaleDateString();
  };

  return (
    <div className="space-y-6">
      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Pending Reports</p>
                <h3 className="text-2xl font-bold mt-1">
                  {isLoading ? '-' : stats.pendingReports}
                </h3>
                <p className="text-xs text-red-500 mt-1">Requires attention</p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-red-900' : 'bg-red-100'}`}>
                <AlertTriangle className="text-red-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Auto-Flagged</p>
                <h3 className="text-2xl font-bold mt-1">
                  {isLoading ? '-' : stats.autoFlagged}
                </h3>
                <p className="text-xs text-orange-500 mt-1">AI detected</p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-orange-900' : 'bg-orange-100'}`}>
                <Shield className="text-orange-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Resolved Today</p>
                <h3 className="text-2xl font-bold mt-1">
                  {isLoading ? '-' : stats.resolvedToday}
                </h3>
                <p className="text-xs text-green-500 mt-1">Cases closed</p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                <CheckCircle className="text-green-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Banned Users</p>
                <h3 className="text-2xl font-bold mt-1">
                  {isLoading ? '-' : stats.bannedUsers}
                </h3>
                <p className="text-xs text-gray-500 mt-1">Active bans</p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-gray-700' : 'bg-gray-100'}`}>
                <Ban className="text-gray-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
        <CardHeader>
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <CardTitle>Content Reports</CardTitle>
            
            <div className="flex flex-col sm:flex-row gap-2">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Search reports..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className={`pl-10 ${isDarkMode ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}
                />
              </div>

              {/* Filter */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="flex items-center gap-2">
                    <Filter className="h-4 w-4" />
                    Filter: {selectedFilter === 'all' ? 'All' : selectedFilter}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent>
                  <DropdownMenuItem onClick={() => setSelectedFilter('all')}>
                    All Reports
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setSelectedFilter('pending')}>
                    Pending
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setSelectedFilter('resolved')}>
                    Resolved
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setSelectedFilter('dismissed')}>
                    Dismissed
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </CardHeader>

        <CardContent>
          <Tabs defaultValue="reports" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="reports">Reports</TabsTrigger>
              <TabsTrigger value="auto-flagged">Auto-Flagged</TabsTrigger>
              <TabsTrigger value="banned">Banned Users</TabsTrigger>
            </TabsList>

            <TabsContent value="reports" className="space-y-4">
              {isLoading ? (
                <div className="flex justify-center items-center h-32">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
              ) : (
                <div className="rounded-md border">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Type</TableHead>
                        <TableHead>Reason</TableHead>
                        <TableHead>Reported User</TableHead>
                        <TableHead>Priority</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Time</TableHead>
                        <TableHead>Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredReports.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={7} className="text-center py-8">
                            No reports found matching your criteria.
                          </TableCell>
                        </TableRow>
                      ) : (
                        filteredReports.map((report) => (
                          <TableRow key={report.id}>
                            <TableCell>
                              <div className="flex items-center gap-2">
                                {getContentTypeIcon(report.type)}
                                <span className="capitalize">{report.type}</span>
                                {report.auto_flagged && (
                                  <Badge variant="outline" className="text-orange-600">
                                    Auto
                                  </Badge>
                                )}
                              </div>
                            </TableCell>
                            <TableCell>
                              <div className="max-w-xs">
                                <div className="font-medium">{report.reason}</div>
                                {report.description && (
                                  <div className="text-sm text-gray-500 truncate">
                                    {report.description}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                            <TableCell>
                              <div>
                                <div className="font-medium">
                                  User ID: {report.reported_id.slice(0, 8)}...
                                </div>
                                <div className="text-sm text-gray-500">
                                  Reporter: {report.reporter_id.slice(0, 8)}...
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>
                              {getPriorityBadge(report.priority)}
                            </TableCell>
                            <TableCell>
                              {console.log('Rendering status for report:', report.id, 'status:', report.status)}
                              {getStatusBadge(report.status)}
                            </TableCell>
                            <TableCell>
                              <div className="flex items-center gap-1">
                                <Clock className="h-4 w-4 text-gray-400" />
                                <span className="text-sm">{formatTimeAgo(report.created_at)}</span>
                              </div>
                            </TableCell>
                            <TableCell>
                              <div className="flex items-center gap-2">
                                <Sheet>
                                  <SheetTrigger asChild>
                                    <Button
                                      variant="ghost"
                                      size="sm"
                                      onClick={() => setSelectedReport(report)}
                                    >
                                      <Eye className="h-4 w-4" />
                                    </Button>
                                  </SheetTrigger>
                                  <SheetContent className="min-w-[600px] bg-gray-900/95 backdrop-blur-md border-gray-700">
                                    <SheetHeader>
                                      <SheetTitle className="text-white">Report Details</SheetTitle>
                                      <SheetDescription className="text-gray-300">
                                        Review and take action on this content report
                                      </SheetDescription>
                                    </SheetHeader>
                                    
                                    {selectedReport && (
                                      <div className="space-y-6 mt-6">
                                        <div className="grid grid-cols-2 gap-4">
                                          <div>
                                            <h4 className="font-medium text-white">Content Type</h4>
                                            <p className="text-sm text-gray-300 mt-1 capitalize">
                                              {selectedReport.type || 'Unknown'}
                                            </p>
                                          </div>
                                          <div>
                                            <h4 className="font-medium text-white">Reported User</h4>
                                            <p className="text-sm text-gray-300 mt-1">
                                              User ID: {selectedReport.reported_id?.slice(0, 8)}...
                                            </p>
                                            <p className="text-xs text-gray-400">
                                              Reporter: {selectedReport.reporter_id?.slice(0, 8)}...
                                            </p>
                                          </div>
                                        </div>

                                        <div>
                                          <h4 className="font-medium text-white">Reason</h4>
                                          <p className="text-sm text-gray-300 mt-1">{selectedReport.reason}</p>
                                        </div>

                                        {selectedReport.description && (
                                          <div>
                                            <h4 className="font-medium text-white">Description</h4>
                                            <p className="text-sm text-gray-300 mt-1">{selectedReport.description}</p>
                                          </div>
                                        )}

                                        <div className="grid grid-cols-3 gap-4">
                                          <div>
                                            <h4 className="font-medium text-white">Priority</h4>
                                            <div className="mt-1">{getPriorityBadge(selectedReport.priority)}</div>
                                          </div>
                                          <div>
                                            <h4 className="font-medium text-white">Status</h4>
                                            <div className="mt-1">{getStatusBadge(selectedReport.status)}</div>
                                          </div>
                                          <div>
                                            <h4 className="font-medium text-white">Auto-flagged</h4>
                                            <p className="text-sm text-gray-300 mt-1">
                                              {selectedReport.auto_flagged ? 'Yes' : 'No'}
                                            </p>
                                          </div>
                                        </div>

                                        <div className="pt-4 border-t border-gray-600">
                                          <h4 className="font-medium text-white mb-3">Actions</h4>
                                          <div className="grid grid-cols-2 gap-3">
                                            <Button 
                                              className={selectedReport.status === 'approved' 
                                                ? "bg-gray-600 hover:bg-gray-700 text-white" 
                                                : "bg-green-600 hover:bg-green-700 text-white"
                                              }
                                              onClick={() => handleModerationAction(selectedReport.id, 'approve')}
                                              disabled={isActionLoading || selectedReport.status === 'approved' || selectedReport.status === 'banned'}
                                            >
                                              <CheckCircle className="h-4 w-4 mr-2" />
                                              {selectedReport.status === 'approved' ? 'Approved' : 'Approve Content'}
                                            </Button>
                                            <Button 
                                              variant="destructive"
                                              onClick={() => handleModerationAction(selectedReport.id, 'remove')}
                                              disabled={isActionLoading || selectedReport.status === 'banned'}
                                            >
                                              <XCircle className="h-4 w-4 mr-2" />
                                              Remove Content
                                            </Button>
                                            <Button 
                                              className={selectedReport.status === 'banned' 
                                                ? "bg-orange-600 hover:bg-orange-700 text-white" 
                                                : "bg-red-600 hover:bg-red-700 text-white"
                                              }
                                              onClick={() => handleModerationAction(selectedReport.id, selectedReport.status === 'banned' ? 'unban' : 'ban')}
                                              disabled={isActionLoading}
                                            >
                                              <Ban className="h-4 w-4 mr-2" />
                                              {selectedReport.status === 'banned' ? 'Unban User' : 'Ban User'}
                                            </Button>
                                            <Button 
                                              variant="secondary"
                                              className="bg-gray-700 hover:bg-gray-600 text-gray-300"
                                              onClick={() => handleModerationAction(selectedReport.id, 'dismiss')}
                                              disabled={isActionLoading || selectedReport.status === 'banned'}
                                            >
                                              <EyeOff className="h-4 w-4 mr-2" />
                                              Dismiss
                                            </Button>
                                          </div>
                                        </div>
                                      </div>
                                    )}
                                  </SheetContent>
                                </Sheet>

                                {report.status === 'pending' && (
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <Button variant="ghost" size="sm" disabled={isActionLoading}>
                                        <MoreVertical className="h-4 w-4" />
                                      </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent>
                                      <DropdownMenuItem 
                                        onClick={() => handleModerationAction(report.id, 'approve')}
                                      >
                                        <CheckCircle className="h-4 w-4 mr-2" />
                                        Approve
                                      </DropdownMenuItem>
                                      <DropdownMenuItem 
                                        onClick={() => handleModerationAction(report.id, 'remove')}
                                      >
                                        <XCircle className="h-4 w-4 mr-2" />
                                        Remove Content
                                      </DropdownMenuItem>
                                      <DropdownMenuItem 
                                        onClick={() => handleModerationAction(report.id, 'ban')}
                                      >
                                        <Ban className="h-4 w-4 mr-2" />
                                        Ban User
                                      </DropdownMenuItem>
                                      <DropdownMenuItem 
                                        onClick={() => handleModerationAction(report.id, 'dismiss')}
                                      >
                                        <EyeOff className="h-4 w-4 mr-2" />
                                        Dismiss Report
                                      </DropdownMenuItem>
                                    </DropdownMenuContent>
                                  </DropdownMenu>
                                )}
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>
              )}
            </TabsContent>

            <TabsContent value="auto-flagged" className="space-y-4">
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Type</TableHead>
                      <TableHead>Reason</TableHead>
                      <TableHead>User</TableHead>
                      <TableHead>Confidence</TableHead>
                      <TableHead>Time</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredReports.filter(report => report.auto_flagged).length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="text-center py-8">
                          No auto-flagged content found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      filteredReports
                        .filter(report => report.auto_flagged)
                        .map((report) => (
                          <TableRow key={report.id}>
                            <TableCell>
                              <div className="flex items-center gap-2">
                                {getContentTypeIcon(report.type)}
                                <span className="capitalize">{report.type}</span>
                              </div>
                            </TableCell>
                            <TableCell>{report.reason}</TableCell>
                            <TableCell>
                              {report.reported_user?.name || 'Unknown User'}
                            </TableCell>
                            <TableCell>
                              {report.confidence_score ? 
                                <Badge variant="outline">
                                  {Math.round(report.confidence_score * 100)}%
                                </Badge> : 
                                'N/A'
                              }
                            </TableCell>
                            <TableCell>{formatTimeAgo(report.created_at)}</TableCell>
                            <TableCell>
                              <div className="flex gap-2">
                                <Button 
                                  size="sm" 
                                  variant="outline"
                                  onClick={() => handleModerationAction(report.id, 'approve')}
                                  disabled={isActionLoading || report.status !== 'pending'}
                                >
                                  Approve
                                </Button>
                                <Button 
                                  size="sm" 
                                  variant="destructive"
                                  onClick={() => handleModerationAction(report.id, 'remove')}
                                  disabled={isActionLoading || report.status !== 'pending'}
                                >
                                  Remove
                                </Button>
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                    )}
                  </TableBody>
                </Table>
              </div>
            </TabsContent>

            <TabsContent value="banned" className="space-y-4">
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>User</TableHead>
                      <TableHead>Reason</TableHead>
                      <TableHead>Ban Type</TableHead>
                      <TableHead>Banned Date</TableHead>
                      <TableHead>Expires</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {bannedUsers.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="text-center py-8">
                          No banned users found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      bannedUsers.map((ban) => (
                        <TableRow key={ban.id}>
                          <TableCell>
                            <div>
                              <div className="font-medium">
                                {ban.profiles?.name || 'Unknown User'}
                              </div>
                              <div className="text-sm text-gray-500">
                                ID: {ban.user_id.slice(0, 8)}...
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="max-w-xs">
                              <div className="font-medium">{ban.reason}</div>
                              {ban.description && (
                                <div className="text-sm text-gray-500 truncate">
                                  {ban.description}
                                </div>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge variant={ban.ban_type === 'permanent' ? 'destructive' : 'secondary'}>
                              {ban.ban_type}
                            </Badge>
                          </TableCell>
                          <TableCell>{formatTimeAgo(ban.created_at)}</TableCell>
                          <TableCell>
                            {ban.expires_at ? formatTimeAgo(ban.expires_at) : 'Never'}
                          </TableCell>
                          <TableCell>
                            <Button size="sm" variant="outline">
                              Unban
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
};

export default ContentModeration;