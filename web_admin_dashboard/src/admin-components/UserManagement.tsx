import React, { useState, useEffect } from 'react';
import {
  Search, Filter, MoreHorizontal, Eye, Edit, Ban, CheckCircle,
  XCircle, Mail, Phone, Calendar, MapPin, Heart, Users,
  AlertTriangle, Shield, UserX, UserCheck, Download
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
import { supabase } from '../admin-integrations/supabase/client';
import { toast } from 'sonner';

interface UserManagementProps {
  isDarkMode: boolean;
}

interface User {
  id: string;
  name: string;
  age: number;
  gender: string;
  location: string;
  description: string;
  created_at: string;
  is_active: boolean;
  last_seen: string;
  photos?: any[];
  hobbies?: string[];
  distance?: string;
  profile_picture?: string;
  subscription?: {
    status: string;
    plan_name: string;
  };
  matches_count?: number;
  reports_count?: number;
}

interface UserStats {
  totalUsers: number;
  activeUsers: number;
  reportedUsers: number;
  suspendedUsers: number;
}

const UserManagement: React.FC<UserManagementProps> = ({ isDarkMode }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [users, setUsers] = useState<User[]>([]);
  const [userStats, setUserStats] = useState<UserStats>({
    totalUsers: 0,
    activeUsers: 0,
    reportedUsers: 0,
    suspendedUsers: 0
  });
  const [isLoading, setIsLoading] = useState(true);

  // Fetch users and stats
  const fetchUsers = async () => {
    try {
      setIsLoading(true);
      
      // Get users with basic profile info
      const { data: profilesData, error: profilesError } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (profilesError) {
        console.error('Error fetching profiles:', profilesError);
        toast.error('Failed to fetch profiles: ' + profilesError.message);
        return;
      }

      console.log('Fetched profiles data:', profilesData);

      // Transform data to match User interface
      const transformedUsers: User[] = profilesData?.map((profile: any) => {
        // Get the first photo as profile picture
        const profilePicture = profile.photos && profile.photos.length > 0 
          ? profile.photos[0] 
          : null;

        return {
          id: profile.id,
          name: profile.name || 'Unknown User',
          age: profile.age || 0,
          gender: profile.gender || 'Not specified',
          location: profile.location || 'Not specified',
          description: profile.description || '',
          created_at: profile.created_at,
          is_active: profile.is_active || false,
          last_seen: profile.last_seen || profile.created_at,
          photos: profile.photos || [],
          hobbies: profile.hobbies || [],
          distance: profile.distance || 'Unknown',
          profile_picture: profilePicture,
          subscription: {
            status: 'inactive',
            plan_name: 'Free'
          },
          matches_count: 0, // Will be fetched separately if needed
          reports_count: 0  // Will be fetched separately if needed
        };
      }) || [];

      console.log('Transformed users:', transformedUsers);
      setUsers(transformedUsers);

      // Get user statistics
      const { count: totalCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true });

      const { count: activeCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      // Get reported users count
      const { count: reportedCount } = await supabase
        .from('reports')
        .select('reported_id', { count: 'exact', head: true });

      setUserStats({
        totalUsers: totalCount || 0,
        activeUsers: activeCount || 0,
        reportedUsers: reportedCount || 0,
        suspendedUsers: (totalCount || 0) - (activeCount || 0)
      });

    } catch (error) {
      console.error('Error fetching users:', error);
      toast.error('Failed to fetch users');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const getStatusBadge = (isActive: boolean) => {
    return isActive 
      ? 'bg-green-100 text-green-600'
      : 'bg-red-100 text-red-600';
  };

  const getSubscriptionBadge = (planName: string) => {
    const variants: { [key: string]: string } = {
      'Free': 'bg-gray-100 text-gray-600',
      'Premium': 'bg-purple-100 text-purple-600',
      'Premium Plus': 'bg-pink-100 text-pink-600'
    };
    return variants[planName] || variants['Free'];
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = selectedFilter === 'all' || 
      (selectedFilter === 'active' && user.is_active) ||
      (selectedFilter === 'inactive' && !user.is_active);
    return matchesSearch && matchesFilter;
  });

  const handleUserAction = async (userId: string, action: string) => {
    try {
      switch (action) {
        case 'activate':
          await supabase
            .from('profiles')
            .update({ is_active: true })
            .eq('id', userId);
          break;
        case 'deactivate':
          await supabase
            .from('profiles')
            .update({ is_active: false })
            .eq('id', userId);
          break;
        default:
          console.log(`Action ${action} not implemented yet`);
      }
      
      // Refresh users after action
      fetchUsers();
      toast.success(`User ${action}d successfully`);
    } catch (error) {
      console.error(`Error performing action ${action}:`, error);
      toast.error(`Failed to ${action} user`);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-blue-900' : 'bg-blue-100'}`}>
                <Users className="text-blue-600 h-6 w-6" />
              </div>
              <div className="ml-4">
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Total Users</p>
                <h3 className="text-2xl font-bold">
                  {isLoading ? '-' : userStats.totalUsers.toLocaleString()}
                </h3>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-green-900' : 'bg-green-100'}`}>
                <CheckCircle className="text-green-600 h-6 w-6" />
              </div>
              <div className="ml-4">
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Active Users</p>
                <h3 className="text-2xl font-bold">
                  {isLoading ? '-' : userStats.activeUsers.toLocaleString()}
                </h3>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-yellow-900' : 'bg-yellow-100'}`}>
                <AlertTriangle className="text-yellow-600 h-6 w-6" />
              </div>
              <div className="ml-4">
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Reported Users</p>
                <h3 className="text-2xl font-bold">
                  {isLoading ? '-' : userStats.reportedUsers.toLocaleString()}
                </h3>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className={`w-12 h-12 rounded-full flex items-center justify-center ${isDarkMode ? 'bg-red-900' : 'bg-red-100'}`}>
                <UserX className="text-red-600 h-6 w-6" />
              </div>
              <div className="ml-4">
                <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>Inactive Users</p>
                <h3 className="text-2xl font-bold">
                  {isLoading ? '-' : userStats.suspendedUsers.toLocaleString()}
                </h3>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'}`}>
        <CardHeader>
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <CardTitle>User Management</CardTitle>
            <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Search users..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10 w-full sm:w-64"
                />
              </div>
              <select
                value={selectedFilter}
                onChange={(e) => setSelectedFilter(e.target.value)}
                className={`px-3 py-2 rounded-md border ${isDarkMode ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}
              >
                <option value="all">All Users</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
              <Button variant="outline" className="flex items-center gap-2">
                <Download className="h-4 w-4" />
                Export
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Location</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Subscription</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Last Seen</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-8">
                      No users found matching your criteria.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredUsers.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell>
                        <div className="flex items-center">
                          {user.profile_picture ? (
                            <img 
                              src={user.profile_picture} 
                              alt={user.name}
                              className="w-10 h-10 rounded-full object-cover"
                              onError={(e) => {
                                // Fallback to initials if image fails to load
                                const target = e.target as HTMLImageElement;
                                target.style.display = 'none';
                                const parent = target.parentElement;
                                if (parent) {
                                  parent.innerHTML = `
                                    <div class="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center text-white font-semibold">
                                      ${user.name.slice(0, 2).toUpperCase()}
                                    </div>
                                  `;
                                }
                              }}
                            />
                          ) : (
                            <div className="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center text-white font-semibold">
                              {user.name.slice(0, 2).toUpperCase()}
                            </div>
                          )}
                          <div className="ml-3">
                            <p className="font-medium">{user.name}</p>
                            <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                              {user.age} years, {user.gender}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center text-sm">
                          <MapPin className="h-3 w-3 mr-1" />
                          {user.location}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge className={getStatusBadge(user.is_active)}>
                          {user.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge className={getSubscriptionBadge(user.subscription?.plan_name || 'Free')}>
                          {user.subscription?.plan_name || 'Free'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm">
                          {new Date(user.created_at).toLocaleDateString()}
                        </span>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm">
                          {user.last_seen ? new Date(user.last_seen).toLocaleDateString() : 'Never'}
                        </span>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          <Sheet open={isDetailOpen && selectedUser?.id === user.id} onOpenChange={setIsDetailOpen}>
                            <SheetTrigger asChild>
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => {
                                  setSelectedUser(user);
                                  setIsDetailOpen(true);
                                }}
                              >
                                <Eye className="h-4 w-4" />
                              </Button>
                            </SheetTrigger>
                            <SheetContent className="w-[400px] sm:w-[540px]">
                              <SheetHeader>
                                <SheetTitle>User Details</SheetTitle>
                                <SheetDescription>
                                  Manage user account and view detailed information
                                </SheetDescription>
                              </SheetHeader>
                              {selectedUser && (
                                <div className="mt-6 space-y-6">
                                  {/* User Profile Section */}
                                  <div className="flex items-center space-x-4">
                                    {selectedUser.profile_picture ? (
                                      <img 
                                        src={selectedUser.profile_picture} 
                                        alt={selectedUser.name}
                                        className="w-16 h-16 rounded-full object-cover"
                                        onError={(e) => {
                                          // Fallback to initials if image fails to load
                                          const target = e.target as HTMLImageElement;
                                          target.style.display = 'none';
                                          const parent = target.parentElement;
                                          if (parent) {
                                            parent.innerHTML = `
                                              <div class="w-16 h-16 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center text-white font-bold text-xl">
                                                ${selectedUser.name.slice(0, 2).toUpperCase()}
                                              </div>
                                            `;
                                          }
                                        }}
                                      />
                                    ) : (
                                      <div className="w-16 h-16 rounded-full bg-gradient-to-r from-pink-500 to-purple-600 flex items-center justify-center text-white font-bold text-xl">
                                        {selectedUser.name.slice(0, 2).toUpperCase()}
                                      </div>
                                    )}
                                    <div>
                                      <h3 className="text-lg font-semibold">{selectedUser.name}</h3>
                                      <p className="text-gray-500">{selectedUser.age} years, {selectedUser.gender}</p>
                                      <Badge className={getStatusBadge(selectedUser.is_active)}>
                                        {selectedUser.is_active ? 'Active' : 'Inactive'}
                                      </Badge>
                                    </div>
                                  </div>

                                  {/* User Info */}
                                  <div className="space-y-3">
                                    <div className="flex justify-between">
                                      <span className="text-gray-500">Location:</span>
                                      <span>{selectedUser.location}</span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-500">Description:</span>
                                      <span className="text-right max-w-[200px] truncate">
                                        {selectedUser.description || 'No description'}
                                      </span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-500">Join Date:</span>
                                      <span>{new Date(selectedUser.created_at).toLocaleDateString()}</span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-500">Subscription:</span>
                                      <Badge className={getSubscriptionBadge(selectedUser.subscription?.plan_name || 'Free')}>
                                        {selectedUser.subscription?.plan_name || 'Free'}
                                      </Badge>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-500">Last Seen:</span>
                                      <span>
                                        {selectedUser.last_seen ? new Date(selectedUser.last_seen).toLocaleDateString() : 'Never'}
                                      </span>
                                    </div>
                                  </div>

                                  {/* Photos Section */}
                                  {selectedUser.photos && selectedUser.photos.length > 0 && (
                                    <div className="space-y-3">
                                      <h4 className="font-medium">Profile Photos</h4>
                                      <div className="grid grid-cols-3 gap-2">
                                        {selectedUser.photos.map((photo, index) => (
                                          <img
                                            key={index}
                                            src={photo}
                                            alt={`${selectedUser.name} photo ${index + 1}`}
                                            className="w-full h-20 object-cover rounded-lg"
                                            onError={(e) => {
                                              const target = e.target as HTMLImageElement;
                                              target.style.display = 'none';
                                            }}
                                          />
                                        ))}
                                      </div>
                                    </div>
                                  )}

                                  {/* Action Buttons */}
                                  <div className="flex space-x-2 pt-4">
                                    {selectedUser.is_active ? (
                                      <Button
                                        variant="destructive"
                                        size="sm"
                                        onClick={() => handleUserAction(selectedUser.id, 'deactivate')}
                                      >
                                        <UserX className="h-4 w-4 mr-2" />
                                        Deactivate
                                      </Button>
                                    ) : (
                                      <Button
                                        variant="default"
                                        size="sm"
                                        onClick={() => handleUserAction(selectedUser.id, 'activate')}
                                      >
                                        <UserCheck className="h-4 w-4 mr-2" />
                                        Activate
                                      </Button>
                                    )}
                                  </div>
                                </div>
                              )}
                            </SheetContent>
                          </Sheet>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default UserManagement;