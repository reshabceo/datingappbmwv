import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { Download, Mail, Search, Calendar, Users } from 'lucide-react';
import { supabase } from '../admin-integrations/supabase/client';

interface EarlyAccessEmail {
  id: string;
  email: string;
  subscribed_at: string;
  created_at: string;
}

interface EarlyAccessManagementProps {
  isDarkMode: boolean;
}

const EarlyAccessManagement: React.FC<EarlyAccessManagementProps> = ({ isDarkMode }) => {
  const [emails, setEmails] = useState<EarlyAccessEmail[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [totalCount, setTotalCount] = useState(0);

  useEffect(() => {
    fetchEarlyAccessEmails();
  }, []);

  const fetchEarlyAccessEmails = async () => {
    try {
      setLoading(true);
      console.log('🔍 Fetching early access emails...');
      
      const { data, error, count } = await supabase
        .from('early_access_emails')
        .select('*', { count: 'exact' })
        .order('subscribed_at', { ascending: false });

      console.log('📊 Supabase response:', { data, error, count });

      if (error) {
        console.error('❌ Error fetching early access emails:', error);
        alert('Error fetching emails: ' + error.message);
        return;
      }

      console.log('✅ Successfully fetched emails:', data);
      setEmails(data || []);
      setTotalCount(count || 0);
    } catch (error) {
      console.error('❌ Exception:', error);
      alert('Exception: ' + error);
    } finally {
      setLoading(false);
    }
  };

  const exportEmails = () => {
    const csvContent = [
      'Email,Subscribed Date',
      ...emails.map(email => `${email.email},${new Date(email.subscribed_at).toLocaleDateString()}`)
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `early-access-emails-${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  };

  const filteredEmails = emails.filter(email =>
    email.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold">Early Access Management</h2>
          <p className="text-gray-600 dark:text-gray-400">
            Manage early access email subscriptions
          </p>
        </div>
        <div className="flex gap-2">
          <Button onClick={exportEmails} variant="outline" className="flex items-center gap-2">
            <Download className="h-4 w-4" />
            Export CSV
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className={isDarkMode ? 'bg-gray-800' : 'bg-white'}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-blue-500" />
              <div className="ml-4">
                <p className="text-sm text-gray-600 dark:text-gray-400">Total Subscribers</p>
                <p className="text-2xl font-bold">{totalCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={isDarkMode ? 'bg-gray-800' : 'bg-white'}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Mail className="h-8 w-8 text-green-500" />
              <div className="ml-4">
                <p className="text-sm text-gray-600 dark:text-gray-400">This Week</p>
                <p className="text-2xl font-bold">
                  {emails.filter(email => {
                    const weekAgo = new Date();
                    weekAgo.setDate(weekAgo.getDate() - 7);
                    return new Date(email.subscribed_at) > weekAgo;
                  }).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={isDarkMode ? 'bg-gray-800' : 'bg-white'}>
          <CardContent className="p-6">
            <div className="flex items-center">
              <Calendar className="h-8 w-8 text-purple-500" />
              <div className="ml-4">
                <p className="text-sm text-gray-600 dark:text-gray-400">Today</p>
                <p className="text-2xl font-bold">
                  {emails.filter(email => {
                    const today = new Date();
                    const emailDate = new Date(email.subscribed_at);
                    return emailDate.toDateString() === today.toDateString();
                  }).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card className={isDarkMode ? 'bg-gray-800' : 'bg-white'}>
        <CardContent className="p-6">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="Search emails..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Emails List */}
      <Card className={isDarkMode ? 'bg-gray-800' : 'bg-white'}>
        <CardHeader>
          <CardTitle>Early Access Subscribers ({filteredEmails.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
              <p className="mt-2 text-gray-600 dark:text-gray-400">Loading emails...</p>
            </div>
          ) : filteredEmails.length === 0 ? (
            <div className="text-center py-8">
              <Mail className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600 dark:text-gray-400">
                {searchTerm ? 'No emails found matching your search.' : 'No early access subscribers yet.'}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredEmails.map((email) => (
                <div
                  key={email.id}
                  className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  <div className="flex items-center space-x-4">
                    <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                      <Mail className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <p className="font-medium">{email.email}</p>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        Subscribed {formatDate(email.subscribed_at)}
                      </p>
                    </div>
                  </div>
                  <Badge variant="secondary">
                    Early Access
                  </Badge>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default EarlyAccessManagement;
