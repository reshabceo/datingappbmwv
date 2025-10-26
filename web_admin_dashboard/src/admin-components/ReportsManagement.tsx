import React, { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { toast } from 'react-hot-toast';

const supabase = createClient(
  'https://dkcitxzvojvecuvacwsp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
);

interface Report {
  id: string;
  reporter_id: string;
  reported_id: string;
  reason: string;
  description: string;
  status: string;
  created_at: string;
  reporter_name?: string;
  reported_name?: string;
  report_count?: number;
}

interface UserStats {
  totalReports: number;
  pendingReports: number;
  resolvedReports: number;
  highRiskUsers: number;
}

const ReportsManagement: React.FC = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<UserStats>({
    totalReports: 0,
    pendingReports: 0,
    resolvedReports: 0,
    highRiskUsers: 0
  });
  const [filter, setFilter] = useState<'all' | 'pending' | 'resolved' | 'high-risk'>('all');

  useEffect(() => {
    fetchReports();
  }, [filter]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      
      // Get reports with user names
      const { data: reportsData, error: reportsError } = await supabase
        .from('reports')
        .select(`
          *,
          reporter:profiles!reports_reporter_id_fkey(name),
          reported:profiles!reports_reported_id_fkey(name)
        `)
        .order('created_at', { ascending: false });

      if (reportsError) {
        console.error('Error fetching reports:', reportsError);
        toast.error('Failed to fetch reports');
        return;
      }

      // Get report counts per user
      const { data: reportCounts, error: countError } = await supabase
        .from('reports')
        .select('reported_id')
        .eq('status', 'pending');

      if (countError) {
        console.error('Error fetching report counts:', countError);
      }

      // Count reports per user
      const userReportCounts: { [key: string]: number } = {};
      reportCounts?.forEach(report => {
        userReportCounts[report.reported_id] = (userReportCounts[report.reported_id] || 0) + 1;
      });

      // Transform data
      const transformedReports: Report[] = reportsData?.map((report: any) => ({
        ...report,
        reporter_name: report.reporter?.name || 'Unknown',
        reported_name: report.reported?.name || 'Unknown',
        report_count: userReportCounts[report.reported_id] || 0
      })) || [];

      // Filter reports
      let filteredReports = transformedReports;
      if (filter === 'pending') {
        filteredReports = transformedReports.filter(r => r.status === 'pending');
      } else if (filter === 'resolved') {
        filteredReports = transformedReports.filter(r => r.status === 'resolved');
      } else if (filter === 'high-risk') {
        filteredReports = transformedReports.filter(r => r.report_count >= 3);
      }

      setReports(filteredReports);

      // Calculate stats
      const totalReports = transformedReports.length;
      const pendingReports = transformedReports.filter(r => r.status === 'pending').length;
      const resolvedReports = transformedReports.filter(r => r.status === 'resolved').length;
      const highRiskUsers = Object.values(userReportCounts).filter(count => count >= 3).length;

      setStats({
        totalReports,
        pendingReports,
        resolvedReports,
        highRiskUsers
      });

    } catch (error) {
      console.error('Error:', error);
      toast.error('Failed to fetch reports');
    } finally {
      setLoading(false);
    }
  };

  const updateReportStatus = async (reportId: string, status: string) => {
    try {
      const { error } = await supabase
        .from('reports')
        .update({ status })
        .eq('id', reportId);

      if (error) {
        console.error('Error updating report:', error);
        toast.error('Failed to update report');
        return;
      }

      toast.success(`Report ${status}`);
      fetchReports();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Failed to update report');
    }
  };

  const deactivateUser = async (userId: string) => {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ is_active: false })
        .eq('id', userId);

      if (error) {
        console.error('Error deactivating user:', error);
        toast.error('Failed to deactivate user');
        return;
      }

      toast.success('User deactivated');
      fetchReports();
    } catch (error) {
      console.error('Error:', error);
      toast.error('Failed to deactivate user');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'text-yellow-600 bg-yellow-100';
      case 'resolved': return 'text-green-600 bg-green-100';
      case 'dismissed': return 'text-gray-600 bg-gray-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getRiskLevel = (reportCount: number) => {
    if (reportCount >= 5) return { level: 'Critical', color: 'text-red-600 bg-red-100' };
    if (reportCount >= 3) return { level: 'High', color: 'text-orange-600 bg-orange-100' };
    if (reportCount >= 2) return { level: 'Medium', color: 'text-yellow-600 bg-yellow-100' };
    return { level: 'Low', color: 'text-green-600 bg-green-100' };
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Reports Management</h1>
        <p className="text-gray-600">Manage user reports and take appropriate actions</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-blue-600">{stats.totalReports}</div>
          <div className="text-sm text-gray-600">Total Reports</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-yellow-600">{stats.pendingReports}</div>
          <div className="text-sm text-gray-600">Pending</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-green-600">{stats.resolvedReports}</div>
          <div className="text-sm text-gray-600">Resolved</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-red-600">{stats.highRiskUsers}</div>
          <div className="text-sm text-gray-600">High Risk Users</div>
        </div>
      </div>

      {/* Filter Buttons */}
      <div className="mb-4">
        <div className="flex space-x-2">
          {[
            { key: 'all', label: 'All Reports' },
            { key: 'pending', label: 'Pending' },
            { key: 'resolved', label: 'Resolved' },
            { key: 'high-risk', label: 'High Risk' }
          ].map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setFilter(key as any)}
              className={`px-4 py-2 rounded-lg text-sm font-medium ${
                filter === key
                  ? 'bg-pink-500 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Reports Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Report Details
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Users
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Risk Level
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {reports.map((report) => {
                const riskLevel = getRiskLevel(report.report_count || 0);
                return (
                  <tr key={report.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">{report.reason}</div>
                        <div className="text-sm text-gray-500">{report.description}</div>
                        <div className="text-xs text-gray-400">
                          {new Date(report.created_at).toLocaleDateString()}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm text-gray-900">
                          <span className="font-medium">Reporter:</span> {report.reporter_name}
                        </div>
                        <div className="text-sm text-gray-900">
                          <span className="font-medium">Reported:</span> {report.reported_name}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${riskLevel.color}`}>
                        {riskLevel.level} ({report.report_count} reports)
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(report.status)}`}>
                        {report.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex space-x-2">
                        {report.status === 'pending' && (
                          <>
                            <button
                              onClick={() => updateReportStatus(report.id, 'resolved')}
                              className="text-green-600 hover:text-green-900"
                            >
                              Resolve
                            </button>
                            <button
                              onClick={() => updateReportStatus(report.id, 'dismissed')}
                              className="text-gray-600 hover:text-gray-900"
                            >
                              Dismiss
                            </button>
                          </>
                        )}
                        {report.report_count >= 3 && (
                          <button
                            onClick={() => deactivateUser(report.reported_id)}
                            className="text-red-600 hover:text-red-900"
                          >
                            Deactivate User
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        
        {reports.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No reports found for the selected filter.
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportsManagement;
