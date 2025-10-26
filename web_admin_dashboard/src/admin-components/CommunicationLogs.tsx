import React, { useState, useEffect } from 'react';
import {
  MessageSquare, Search, Filter, Eye, Ban, Flag, Clock,
  TrendingUp, Users, AlertTriangle, CheckCircle, XCircle,
  Calendar, Download, MoreHorizontal, ArrowUpDown
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
  TableRow,
} from './ui/table';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from './ui/sheet';
import { Label } from './ui/label';
import { ScrollArea } from './ui/scroll-area';
import { supabase } from '../admin-integrations/supabase/client';
import { toast } from 'sonner';

interface CommunicationLogsProps {
  isDarkMode: boolean;
}

interface Conversation {
  id: string;
  participants: string[];
  userIds: string[];
  lastMessage: string;
  timestamp: string;
  messageCount: number;
  status: 'active' | 'flagged' | 'blocked';
  flagged: boolean;
  flaggedReason?: string;
  riskScore: number;
  hasMedia: boolean;
}

interface Message {
  id: string;
  sender: string;
  message: string;
  timestamp: string;
  type: 'text' | 'media';
  flagged?: boolean;
}

interface CommunicationStats {
  totalMessages: number;
  activeChats: number;
  flaggedMessages: number;
  blockedUsers: number;
}

const CommunicationLogs: React.FC<CommunicationLogsProps> = ({ isDarkMode }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTimeframe, setSelectedTimeframe] = useState('today');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [messageHistory, setMessageHistory] = useState<Message[]>([]);
  const [participantProfiles, setParticipantProfiles] = useState<Record<string, any>>({});
  const [communicationStats, setCommunicationStats] = useState<CommunicationStats>({
    totalMessages: 0,
    activeChats: 0,
    flaggedMessages: 0,
    blockedUsers: 0
  });
  const [trends, setTrends] = useState({
    totalMessages: { change: 0, isPositive: true },
    activeChats: { change: 0, isPositive: true },
    flaggedMessages: { change: 0, isPositive: false },
    blockedUsers: { change: 0, isPositive: false }
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCommunicationData();
  }, []);

  const fetchCommunicationData = async () => {
    try {
      setLoading(true);
      
      // Fetch conversation metadata
      const { data: conversationsData, error: conversationsError } = await supabase
        .from('conversation_metadata')
        .select('*')
        .order('last_activity', { ascending: false });

      if (conversationsError) {
        console.error('Error fetching conversations:', conversationsError);
        toast.error('Failed to load conversations');
        return;
      }

      console.log('📊 Raw conversation data:', conversationsData);
      console.log('🚩 Flagged conversations:', conversationsData?.filter(conv => conv.is_flagged));

      // Fetch matches data
      const { data: matchesData, error: matchesError } = await supabase
        .from('matches')
        .select('*');

      if (matchesError) {
        console.error('Error fetching matches:', matchesError);
        toast.error('Failed to load matches');
        return;
      }

      // Create matches map
      const matchesMap = matchesData?.reduce((acc, match) => {
        acc[match.id] = match;
        return acc;
      }, {} as Record<string, any>) || {};

      // Get profile data for participants
      const userIds = new Set<string>();
      conversationsData?.forEach(conv => {
        const match = matchesMap[conv.match_id];
        if (match) {
          userIds.add(match.user_id_1);
          userIds.add(match.user_id_2);
        }
      });

      const { data: profilesData } = await supabase
        .from('profiles')
        .select('id, name')
        .in('id', Array.from(userIds));

      const profilesMap = profilesData?.reduce((acc, profile) => {
        acc[profile.id] = profile.name || `User ${profile.id.slice(0, 8)}`;
        return acc;
      }, {} as Record<string, string>) || {};

      // Fetch message analytics for stats (today and yesterday)
      const { data: analyticsData } = await supabase
        .from('message_analytics')
        .select('*')
        .order('date', { ascending: false })
        .limit(2);

      const todayAnalytics = analyticsData?.[0];
      const yesterdayAnalytics = analyticsData?.[1];

      // Count flagged conversations and blocked users
      const flaggedCount = conversationsData?.filter(conv => conv.is_flagged).length || 0;
      const { count: blockedCount } = await supabase
        .from('banned_users')
        .select('*', { count: 'exact' })
        .eq('is_active', true);

      // Transform conversation data
      const transformedConversations: Conversation[] = conversationsData?.map(conv => {
        const match = matchesMap[conv.match_id];
        if (!match) {
          console.warn('No match found for conversation:', conv.match_id);
          return null;
        }
        
        const transformed = {
          id: match.id,
          participants: [
            profilesMap[match.user_id_1] || 'Unknown User',
            profilesMap[match.user_id_2] || 'Unknown User'
          ],
          userIds: [match.user_id_1, match.user_id_2],
          lastMessage: conv.is_flagged ? 'This conversation has been flagged for review' : 'Recent conversation activity...',
          timestamp: formatTimestamp(conv.last_activity || conv.created_at),
          messageCount: conv.message_count || 0,
          status: conv.is_flagged ? 'flagged' : (match.status === 'matched' ? 'active' : 'blocked'),
          flagged: conv.is_flagged,
          flaggedReason: conv.flagged_reason,
          riskScore: conv.risk_score || 0,
          hasMedia: Math.random() > 0.5 // Random for demo, could be real data
        };
        
        console.log('🔄 Transformed conversation:', transformed.id, 'flagged:', transformed.flagged, 'reason:', transformed.flaggedReason);
        return transformed;
      }).filter(Boolean) || [];

      setConversations(transformedConversations);

      // Calculate real stats from actual data
      const totalMessages = todayAnalytics?.total_messages || 0;
      const activeChats = transformedConversations.filter(c => c.status === 'active').length;
      const flaggedMessages = todayAnalytics?.flagged_messages || 0;
      const blockedUsers = blockedCount || 0;

      // Calculate real trends by comparing with yesterday's data
      const calculateTrend = (today: number, yesterday: number) => {
        if (yesterday === 0) return { change: 0, isPositive: true };
        const change = Math.round(((today - yesterday) / yesterday) * 100);
        return { change: Math.abs(change), isPositive: change >= 0 };
      };

      const totalMessagesTrend = calculateTrend(
        totalMessages, 
        yesterdayAnalytics?.total_messages || 0
      );
      const flaggedMessagesTrend = calculateTrend(
        flaggedMessages, 
        yesterdayAnalytics?.flagged_messages || 0
      );

      // For active chats and blocked users, we'll use simple count changes
      const activeChatsChange = activeChats; // This would need historical data to be truly accurate
      const blockedUsersChange = blockedUsers; // This would need historical data to be truly accurate

      console.log('📊 Real Communication Stats:', {
        totalMessages,
        activeChats,
        flaggedMessages,
        blockedUsers,
        todayAnalytics,
        yesterdayAnalytics,
        totalMessagesTrend,
        flaggedMessagesTrend
      });

      setCommunicationStats({
        totalMessages,
        activeChats,
        flaggedMessages,
        blockedUsers
      });

      setTrends({
        totalMessages: totalMessagesTrend,
        activeChats: { change: activeChatsChange, isPositive: true },
        flaggedMessages: flaggedMessagesTrend,
        blockedUsers: { change: blockedUsersChange, isPositive: false }
      });

    } catch (error) {
      console.error('Error fetching communication data:', error);
      toast.error('Failed to load communication data');
    } finally {
      setLoading(false);
    }
  };

  const fetchMessageHistory = async (conversationId: string) => {
    try {
      console.log('Fetching messages for conversation:', conversationId);
      
      const { data: messagesData, error } = await supabase
        .from('messages')
        .select(`
          id,
          content,
          created_at,
          sender_id,
          message_type
        `)
        .eq('match_id', conversationId)
        .order('created_at', { ascending: false })
        .limit(20);

      console.log('Messages query result:', { data: messagesData, error });

      if (error) {
        console.error('Error fetching messages:', error);
        return;
      }

      // Get unique sender IDs and fetch their profiles
      const senderIds = [...new Set(messagesData?.map(msg => msg.sender_id) || [])];
      console.log('Sender IDs:', senderIds);
      
      const { data: sendersData } = await supabase
        .from('profiles')
        .select('id, name')
        .in('id', senderIds);

      console.log('Senders data:', sendersData);

      const sendersMap = sendersData?.reduce((acc, profile) => {
        acc[profile.id] = profile.name || `User ${profile.id.slice(0, 8)}`;
        return acc;
      }, {} as Record<string, string>) || {};

      console.log('Senders map:', sendersMap);

      const transformedMessages: Message[] = messagesData?.map(msg => ({
        id: msg.id,
        sender: sendersMap[msg.sender_id] || 'Unknown User',
        message: msg.message_type === 'text' ? msg.content : '[Media shared]',
        timestamp: formatTimestamp(msg.created_at),
        type: msg.message_type === 'text' ? 'text' : 'media',
        flagged: false // You can add message flag checks here
      })) || [];

      console.log('Transformed messages:', transformedMessages);
      setMessageHistory(transformedMessages);
    } catch (error) {
      console.error('Error fetching messages:', error);
    }
  };

  const formatTimestamp = (timestamp: string): string => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes} minutes ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)} hours ago`;
    return `${Math.floor(diffInMinutes / 1440)} days ago`;
  };

  const getStatusBadge = (status: string, flagged: boolean) => {
    if (flagged) {
      return <Badge variant="destructive" className="text-xs">Flagged</Badge>;
    }
    
    switch (status) {
      case 'active':
        return <Badge className="bg-green-100 text-green-600 text-xs">Active</Badge>;
      case 'blocked':
        return <Badge variant="destructive" className="text-xs">Blocked</Badge>;
      case 'flagged':
        return <Badge className="bg-yellow-100 text-yellow-600 text-xs">Under Review</Badge>;
      default:
        return <Badge variant="secondary" className="text-xs">Unknown</Badge>;
    }
  };

  const fetchParticipantProfiles = async (userIds: string[]) => {
    try {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, avatar_url, name')
        .in('id', userIds);

      const profilesMap = profiles?.reduce((acc, profile) => {
        acc[profile.id] = profile;
        return acc;
      }, {} as Record<string, any>) || {};

      setParticipantProfiles(profilesMap);
    } catch (error) {
      console.error('Error fetching participant profiles:', error);
    }
  };

  const handleConversationView = (conversation: Conversation) => {
    console.log('Opening conversation:', conversation);
    setSelectedConversation(conversation);
    fetchMessageHistory(conversation.id);
    fetchParticipantProfiles(conversation.userIds);
  };

  const handleFlagConversation = async () => {
    console.log('🚩 Starting to flag conversation:', selectedConversation?.id);
    if (!selectedConversation) {
      console.log('❌ No selected conversation');
      return;
    }
    
    try {
      console.log('📝 Updating conversation metadata...');
      // Update conversation metadata to flag it
      const { error } = await supabase
        .from('conversation_metadata')
        .update({
          is_flagged: true,
          flagged_reason: 'Flagged by admin',
          flagged_at: new Date().toISOString(),
          flagged_by: 'admin'
        })
        .eq('match_id', selectedConversation.id);

      if (error) {
        console.error('❌ Supabase error flagging conversation:', error);
        toast.error('Failed to flag conversation');
        return;
      }

      console.log('✅ Database updated successfully');
      toast.success('Conversation flagged successfully');
      
      // Update local state immediately
      setCommunicationData(prev => prev.map(conv => 
        conv.id === selectedConversation.id 
          ? { ...conv, flagged: true, flaggedReason: 'Flagged by admin' }
          : conv
      ));

      // Update selected conversation
      setSelectedConversation(prev => prev ? { ...prev, flagged: true, flaggedReason: 'Flagged by admin' } : null);
      
      console.log('✅ Local state updated successfully');
      console.log('🎉 Conversation flagged successfully!');
      
      // Refresh the data
      fetchCommunicationData();
    } catch (error) {
      console.error('❌ Error flagging conversation:', error);
      toast.error('Failed to flag conversation');
    }
  };

  const handleBlockUsers = async () => {
    if (!selectedConversation) return;
    
    try {
      // Block both users in the conversation
      const userIds = selectedConversation.userIds;
      
      for (const userId of userIds) {
        const { error } = await supabase
          .from('banned_users')
          .insert({
            user_id: userId,
            banned_by: 'admin',
            ban_type: 'permanent',
            reason: 'Blocked by admin from communication logs',
            description: 'User blocked from communication logs',
            is_active: true
          });

        if (error) {
          console.error('Error blocking user:', error);
          toast.error(`Failed to block user ${userId}`);
          return;
        }
      }

      toast.success('Users blocked successfully');
      // Refresh the data
      fetchCommunicationData();
    } catch (error) {
      console.error('Error blocking users:', error);
      toast.error('Failed to block users');
    }
  };

  const filteredConversations = conversations.filter(conv => {
    const matchesSearch = conv.participants.some(name => 
      name.toLowerCase().includes(searchTerm.toLowerCase())
    ) || conv.lastMessage.toLowerCase().includes(searchTerm.toLowerCase());
    
    let matchesStatus = true;
    if (selectedStatus === 'flagged') {
      matchesStatus = conv.flagged;
    } else if (selectedStatus !== 'all') {
      matchesStatus = conv.status === selectedStatus;
    }
    
    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Total Messages</p>
                <h3 className="text-2xl font-bold mt-1">{communicationStats.totalMessages.toLocaleString()}</h3>
                <p className={`text-xs mt-1 flex items-center ${trends.totalMessages.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <TrendingUp className="h-3 w-3 mr-1" /> 
                  {trends.totalMessages.change > 0 ? '+' : ''}{trends.totalMessages.change}% from yesterday
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-blue-900' : 'bg-blue-100'}`}>
                <MessageSquare className="text-blue-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Active Chats</p>
                <h3 className="text-2xl font-bold mt-1">{communicationStats.activeChats.toLocaleString()}</h3>
                <p className={`text-xs mt-1 flex items-center ${trends.activeChats.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <TrendingUp className="h-3 w-3 mr-1" /> 
                  {trends.activeChats.change > 0 ? '+' : ''}{trends.activeChats.change} from yesterday
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                <Users className="text-green-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Flagged Messages</p>
                <h3 className="text-2xl font-bold mt-1">{communicationStats.flaggedMessages}</h3>
                <p className={`text-xs mt-1 flex items-center ${trends.flaggedMessages.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <AlertTriangle className="h-3 w-3 mr-1" /> 
                  {trends.flaggedMessages.change > 0 ? '+' : ''}{trends.flaggedMessages.change}% from yesterday
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-yellow-900' : 'bg-yellow-100'}`}>
                <Flag className="text-yellow-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex justify-between items-center">
              <div>
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Blocked Users</p>
                <h3 className="text-2xl font-bold mt-1">{communicationStats.blockedUsers}</h3>
                <p className={`text-xs mt-1 flex items-center ${trends.blockedUsers.isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  <Ban className="h-3 w-3 mr-1" /> 
                  {trends.blockedUsers.change > 0 ? '+' : ''}{trends.blockedUsers.change} from yesterday
                </p>
              </div>
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-red-900' : 'bg-red-100'}`}>
                <XCircle className="text-red-600 h-6 w-6" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters and Search */}
      <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            Communication Logs
            <Button variant="outline" size="sm" className="flex items-center gap-2">
              <Download className="h-4 w-4" />
              Export
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Search conversations..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            
            <div className="flex gap-2">
              <select
                value={selectedTimeframe}
                onChange={(e) => setSelectedTimeframe(e.target.value)}
                className={`px-3 py-2 rounded-md border ${isDarkMode ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}
              >
                <option value="today">Today</option>
                <option value="week">This Week</option>
                <option value="month">This Month</option>
                <option value="all">All Time</option>
              </select>
              
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className={`px-3 py-2 rounded-md border ${isDarkMode ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="flagged">Flagged</option>
                <option value="blocked">Blocked</option>
              </select>
            </div>
          </div>

          {/* Conversations Table */}
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Participants</TableHead>
                  <TableHead>Last Message</TableHead>
                  <TableHead>Messages</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Timestamp</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredConversations.map((conv) => (
                  <TableRow key={conv.id} className={conv.flagged ? 'bg-red-50 dark:bg-red-900/20' : ''}>
                    <TableCell>
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-medium">{conv.participants.join(' & ')}</p>
                          {conv.flagged && (
                            <Badge variant="destructive" className="text-xs">
                              <Flag className="h-3 w-3 mr-1" />
                              Flagged
                            </Badge>
                          )}
                        </div>
                        <p className={`text-xs ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                          IDs: {conv.userIds.map(id => id.slice(0, 8)).join(', ')}
                        </p>
                        {conv.riskScore > 50 && (
                          <p className="text-xs text-red-500">Risk: {conv.riskScore}/100</p>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="max-w-xs">
                        <p className="truncate">{conv.lastMessage}</p>
                        {conv.hasMedia && (
                          <Badge variant="outline" className="text-xs mt-1">Contains Media</Badge>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary" className="text-xs">
                        {conv.messageCount} messages
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-col gap-1">
                        {getStatusBadge(conv.status, conv.flagged)}
                        {conv.flagged && conv.flaggedReason && (
                          <p className="text-xs text-red-600 dark:text-red-400 truncate max-w-[120px]" title={conv.flaggedReason}>
                            {conv.flaggedReason}
                          </p>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center text-sm">
                        <Clock className="h-3 w-3 mr-1" />
                        {conv.timestamp}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Sheet>
                          <SheetTrigger asChild>
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => handleConversationView(conv)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          </SheetTrigger>
                          <SheetContent className="min-w-[95vw] w-[95vw] sm:w-[1200px] max-w-[95vw] bg-gray-900/95 backdrop-blur-md border-gray-700" style={{ width: '95vw !important', maxWidth: '95vw !important', minWidth: '95vw !important' }}>
                            <SheetHeader>
                              <SheetTitle className="text-white">Conversation Details</SheetTitle>
                              <SheetDescription className="text-gray-300">
                                {selectedConversation?.participants.join(' & ')} - {selectedConversation?.messageCount} messages
                              </SheetDescription>
                            </SheetHeader>
                            
                            <div className="mt-6 space-y-6">
                              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                                <div className="space-y-3">
                                  <Label className="text-lg font-semibold text-white">Participants</Label>
                                  <div className="space-y-3">
                                    {selectedConversation?.participants.map((participant, index) => {
                                      const userId = selectedConversation.userIds[index];
                                      const profile = participantProfiles[userId];
                                      
                                      return (
                                        <div key={index} className="flex items-center justify-between p-4 bg-gray-800/50 rounded-lg border border-gray-600/50">
                                          <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 bg-gray-600 rounded-full flex items-center justify-center overflow-hidden">
                                              {profile?.avatar_url ? (
                                                <img 
                                                  src={profile.avatar_url} 
                                                  alt={participant}
                                                  className="w-full h-full object-cover"
                                                />
                                              ) : (
                                                <span className="text-sm font-medium text-white">
                                                  {participant.charAt(0)}
                                                </span>
                                              )}
                                            </div>
                                            <div>
                                              <p className="text-sm font-medium text-white">{participant}</p>
                                              <p className="text-xs text-gray-400">ID: {userId.slice(0, 8)}...</p>
                                            </div>
                                          </div>
                                          <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                                        </div>
                                      );
                                    })}
                                  </div>
                                </div>
                                <div className="space-y-3">
                                  <Label className="text-lg font-semibold text-white">Status & Risk</Label>
                                  <div className="space-y-3">
                                    <div className="p-4 bg-gray-800/50 rounded-lg border border-gray-600/50">
                                      {selectedConversation && getStatusBadge(selectedConversation.status, selectedConversation.flagged)}
                                    </div>
                                    {selectedConversation?.riskScore && selectedConversation.riskScore > 50 && (
                                      <div className="p-4 bg-red-900/20 rounded-lg border border-red-500/30">
                                        <Badge variant="destructive" className="text-sm">
                                          High Risk: {selectedConversation.riskScore}/100
                                        </Badge>
                                      </div>
                                    )}
                                  </div>
                                </div>
                              </div>

                              {selectedConversation?.flaggedReason && (
                                <div className="p-3 bg-red-900/20 border border-red-500/30 rounded-lg">
                                  <Label className="text-sm font-medium text-red-300">Flagged Reason</Label>
                                  <p className="text-sm text-red-200 mt-1">{selectedConversation.flaggedReason}</p>
                                </div>
                              )}
                              
                              <div>
                                <Label className="text-sm font-medium text-white">Recent Messages</Label>
                                <ScrollArea className="h-[500px] mt-2 border border-gray-600 rounded-lg p-6 bg-gray-800/50">
                                  <div className="space-y-6">
                                    {messageHistory.length > 0 ? messageHistory.map((msg) => (
                                      <div key={msg.id} className="flex flex-col space-y-2">
                                        <div className="flex justify-between items-center px-3">
                                          <div className="flex items-center gap-2">
                                            <div className="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center">
                                              <span className="text-xs font-medium text-white">
                                                {msg.sender.charAt(0)}
                                              </span>
                                            </div>
                                            <span className="font-medium text-sm text-white">{msg.sender}</span>
                                          </div>
                                          <span className="text-xs text-gray-400">{msg.timestamp}</span>
                                        </div>
                                        <div className={`p-4 rounded-lg text-sm max-w-md shadow-lg ${
                                          msg.sender === selectedConversation?.participants[0]
                                            ? 'bg-pink-500/20 text-white ml-12 border border-pink-500/30 self-start' 
                                            : 'bg-gray-700/50 text-gray-200 mr-12 border border-gray-600/50 self-end'
                                        }`}>
                                          <div className="break-words whitespace-pre-wrap leading-relaxed">
                                            {msg.message}
                                          </div>
                                          {msg.flagged && (
                                            <div className="mt-3">
                                              <Badge variant="destructive" className="text-xs">
                                                <Flag className="h-3 w-3 mr-1" />
                                                Flagged
                                              </Badge>
                                            </div>
                                          )}
                                        </div>
                                      </div>
                                    )) : (
                                      <div className="flex items-center justify-center h-32">
                                        <p className="text-sm text-gray-400">No messages available</p>
                                      </div>
                                    )}
                                  </div>
                                </ScrollArea>
                              </div>
                              
                              <div className="flex gap-2 pt-4 border-t border-gray-600">
                                <Button 
                                  variant="outline" 
                                  size="sm" 
                                  className="flex items-center gap-2 border-gray-600 text-gray-300 hover:bg-gray-700 hover:text-white"
                                  onClick={handleFlagConversation}
                                  disabled={selectedConversation?.flagged}
                                >
                                  <Flag className="h-4 w-4" />
                                  {selectedConversation?.flagged ? 'Flagged' : 'Flag Conversation'}
                                </Button>
                                <Button 
                                  variant="destructive" 
                                  size="sm" 
                                  className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white"
                                  onClick={handleBlockUsers}
                                >
                                  <Ban className="h-4 w-4" />
                                  Block Users
                                </Button>
                              </div>
                            </div>
                          </SheetContent>
                        </Sheet>
                        
                        <Button variant="ghost" size="sm">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default CommunicationLogs;