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
  const [communicationStats, setCommunicationStats] = useState<CommunicationStats>({
    totalMessages: 0,
    activeChats: 0,
    flaggedMessages: 0,
    blockedUsers: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCommunicationData();
  }, []);

  const fetchCommunicationData = async () => {
    try {
      setLoading(true);
      
      // Fetch conversation metadata with match and profile data
      const { data: conversationsData, error: conversationsError } = await supabase
        .from('conversation_metadata')
        .select(`
          *,
          match:matches!conversation_metadata_match_id_fkey(
            id,
            user_id_1,
            user_id_2,
            created_at,
            status
          )
        `)
        .order('last_activity', { ascending: false });

      if (conversationsError) {
        console.error('Error fetching conversations:', conversationsError);
        toast.error('Failed to load conversations');
        return;
      }

      // Get profile data for participants
      const userIds = new Set<string>();
      conversationsData?.forEach(conv => {
        if (conv.match) {
          userIds.add(conv.match.user_id_1);
          userIds.add(conv.match.user_id_2);
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

      // Fetch message analytics for stats
      const { data: analyticsData } = await supabase
        .from('message_analytics')
        .select('*')
        .order('date', { ascending: false })
        .limit(1)
        .single();

      // Count flagged conversations and blocked users
      const flaggedCount = conversationsData?.filter(conv => conv.is_flagged).length || 0;
      const { count: blockedCount } = await supabase
        .from('banned_users')
        .select('*', { count: 'exact' })
        .eq('is_active', true);

      // Transform conversation data
      const transformedConversations: Conversation[] = conversationsData?.map(conv => ({
        id: conv.match.id,
        participants: [
          profilesMap[conv.match.user_id_1] || 'Unknown User',
          profilesMap[conv.match.user_id_2] || 'Unknown User'
        ],
        userIds: [conv.match.user_id_1, conv.match.user_id_2],
        lastMessage: conv.is_flagged ? 'This conversation has been flagged for review' : 'Recent conversation activity...',
        timestamp: formatTimestamp(conv.last_activity || conv.created_at),
        messageCount: conv.message_count || 0,
        status: conv.is_flagged ? 'flagged' : (conv.match.status === 'matched' ? 'active' : 'blocked'),
        flagged: conv.is_flagged,
        flaggedReason: conv.flagged_reason,
        riskScore: conv.risk_score || 0,
        hasMedia: Math.random() > 0.5 // Random for demo, could be real data
      })) || [];

      setConversations(transformedConversations);

      // Set stats
      setCommunicationStats({
        totalMessages: analyticsData?.total_messages || 0,
        activeChats: transformedConversations.filter(c => c.status === 'active').length,
        flaggedMessages: analyticsData?.flagged_messages || 0,
        blockedUsers: blockedCount || 0
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

      if (error) {
        console.error('Error fetching messages:', error);
        return;
      }

      // Get unique sender IDs and fetch their profiles
      const senderIds = [...new Set(messagesData?.map(msg => msg.sender_id) || [])];
      const { data: sendersData } = await supabase
        .from('profiles')
        .select('id, name')
        .in('id', senderIds);

      const sendersMap = sendersData?.reduce((acc, profile) => {
        acc[profile.id] = profile.name || `User ${profile.id.slice(0, 8)}`;
        return acc;
      }, {} as Record<string, string>) || {};

      const transformedMessages: Message[] = messagesData?.map(msg => ({
        id: msg.id,
        sender: sendersMap[msg.sender_id] || 'Unknown User',
        message: msg.message_type === 'text' ? msg.content : '[Media shared]',
        timestamp: formatTimestamp(msg.created_at),
        type: msg.message_type === 'text' ? 'text' : 'media',
        flagged: false // You can add message flag checks here
      })) || [];

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

  const handleConversationView = (conversation: Conversation) => {
    setSelectedConversation(conversation);
    fetchMessageHistory(conversation.id);
  };

  const filteredConversations = conversations.filter(conv => {
    const matchesSearch = conv.participants.some(name => 
      name.toLowerCase().includes(searchTerm.toLowerCase())
    ) || conv.lastMessage.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = selectedStatus === 'all' || conv.status === selectedStatus;
    
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
                <p className="text-xs text-green-500 mt-1 flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" /> +12% from yesterday
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
                <p className="text-xs text-green-500 mt-1 flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" /> +8% from yesterday
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
                <p className="text-xs text-red-500 mt-1 flex items-center">
                  <AlertTriangle className="h-3 w-3 mr-1" /> +3 from yesterday
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
                <p className="text-xs text-red-500 mt-1 flex items-center">
                  <Ban className="h-3 w-3 mr-1" /> +2 from yesterday
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
                  <TableRow key={conv.id}>
                    <TableCell>
                      <div>
                        <p className="font-medium">{conv.participants.join(' & ')}</p>
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
                      {getStatusBadge(conv.status, conv.flagged)}
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
                          <SheetContent className="w-[600px] sm:w-[800px]">
                            <SheetHeader>
                              <SheetTitle>Conversation Details</SheetTitle>
                              <SheetDescription>
                                {selectedConversation?.participants.join(' & ')} - {selectedConversation?.messageCount} messages
                              </SheetDescription>
                            </SheetHeader>
                            
                            <div className="mt-6 space-y-4">
                              <div className="grid grid-cols-2 gap-4">
                                <div>
                                  <Label className="text-sm font-medium">Participants</Label>
                                  <div className="mt-1 space-y-1">
                                    {selectedConversation?.participants.map((participant, index) => (
                                      <p key={index} className="text-sm">
                                        {participant} (ID: {selectedConversation.userIds[index].slice(0, 8)}...)
                                      </p>
                                    ))}
                                  </div>
                                </div>
                                <div>
                                  <Label className="text-sm font-medium">Status</Label>
                                  <div className="mt-1 flex flex-col gap-2">
                                    {selectedConversation && getStatusBadge(selectedConversation.status, selectedConversation.flagged)}
                                    {selectedConversation?.riskScore && selectedConversation.riskScore > 50 && (
                                      <Badge variant="destructive" className="text-xs w-fit">
                                        High Risk: {selectedConversation.riskScore}/100
                                      </Badge>
                                    )}
                                  </div>
                                </div>
                              </div>

                              {selectedConversation?.flaggedReason && (
                                <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                                  <Label className="text-sm font-medium text-red-800">Flagged Reason</Label>
                                  <p className="text-sm text-red-700 mt-1">{selectedConversation.flaggedReason}</p>
                                </div>
                              )}
                              
                              <div>
                                <Label className="text-sm font-medium">Recent Messages</Label>
                                <ScrollArea className="h-[400px] mt-2 border rounded-lg p-4">
                                  <div className="space-y-3">
                                    {messageHistory.length > 0 ? messageHistory.map((msg) => (
                                      <div key={msg.id} className="space-y-1">
                                        <div className="flex justify-between items-center">
                                          <span className="font-medium text-sm">{msg.sender}</span>
                                          <span className="text-xs text-gray-500">{msg.timestamp}</span>
                                        </div>
                                        <div className={`p-2 rounded-lg text-sm ${
                                          msg.sender === selectedConversation?.participants[0]
                                            ? 'bg-pink-50 text-pink-800 ml-8' 
                                            : 'bg-gray-50 text-gray-800 mr-8'
                                        }`}>
                                          {msg.message}
                                          {msg.flagged && (
                                            <Badge variant="destructive" className="ml-2 text-xs">
                                              Flagged
                                            </Badge>
                                          )}
                                        </div>
                                      </div>
                                    )) : (
                                      <p className="text-sm text-gray-500">No messages available</p>
                                    )}
                                  </div>
                                </ScrollArea>
                              </div>
                              
                              <div className="flex gap-2 pt-4 border-t">
                                <Button variant="outline" size="sm" className="flex items-center gap-2">
                                  <Flag className="h-4 w-4" />
                                  Flag Conversation
                                </Button>
                                <Button variant="destructive" size="sm" className="flex items-center gap-2">
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