import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import {
  Users,
  FileText,
  CheckCircle2,
  Clock,
  AlertCircle,
  LogOut,
  Search,
  Eye,
  Filter
} from 'lucide-react';

interface Client {
  id: string;
  company_name: string;
  pic_name: string;
  email: string;
  phone: string;
  business_type: string;
  status: string;
  created_at: string;
}

interface OnboardingProgress {
  client_id: string;
  total_steps: number;
  completed_steps: number;
  progress_percentage: number;
}

export function AdminDashboard() {
  const { signOut } = useAuth();
  const [clients, setClients] = useState<Client[]>([]);
  const [progress, setProgress] = useState<Record<string, OnboardingProgress>>({});
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);

  useEffect(() => {
    loadClients();
  }, []);

  const loadClients = async () => {
    try {
      const { data: clientsData, error: clientsError } = await supabase
        .from('clients')
        .select('*')
        .order('created_at', { ascending: false });

      if (clientsError) throw clientsError;

      setClients(clientsData || []);

      if (clientsData) {
        const progressMap: Record<string, OnboardingProgress> = {};

        for (const client of clientsData) {
          const { data: stepsData } = await supabase
            .from('client_onboarding_progress')
            .select('status')
            .eq('client_id', client.id);

          const totalSteps = stepsData?.length || 0;
          const completedSteps = stepsData?.filter(s => s.status === 'completed').length || 0;

          progressMap[client.id] = {
            client_id: client.id,
            total_steps: totalSteps,
            completed_steps: completedSteps,
            progress_percentage: totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 0
          };
        }

        setProgress(progressMap);
      }
    } catch (error) {
      console.error('Error loading clients:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
      verified: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
      approved: 'bg-green-500/10 text-green-400 border-green-500/20',
      rejected: 'bg-red-500/10 text-red-400 border-red-500/20',
      active: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
    };

    const labels: Record<string, string> = {
      pending: 'Pending',
      verified: 'Verified',
      approved: 'Approved',
      rejected: 'Rejected',
      active: 'Active'
    };

    return (
      <span className={`px-3 py-1 rounded-full text-xs font-medium border ${styles[status] || styles.pending}`}>
        {labels[status] || status}
      </span>
    );
  };

  const filteredClients = clients.filter(client => {
    const matchesSearch =
      client.company_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.pic_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || client.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const stats = {
    total: clients.length,
    pending: clients.filter(c => c.status === 'pending').length,
    active: clients.filter(c => c.status === 'active').length,
    completed: clients.filter(c => {
      const p = progress[c.id];
      return p && p.progress_percentage === 100;
    }).length
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-white text-lg">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900">
      <header className="bg-slate-800 border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-white">Admin Dashboard</h1>
              <p className="text-slate-400 text-sm mt-1">Vista Produk - Client Management</p>
            </div>
            <button
              onClick={signOut}
              className="flex items-center gap-2 px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors"
            >
              <LogOut className="h-4 w-4" />
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-slate-800 rounded-xl p-6 border border-slate-700">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-400 text-sm">Total Clients</p>
                <p className="text-3xl font-bold text-white mt-1">{stats.total}</p>
              </div>
              <Users className="h-10 w-10 text-blue-400" />
            </div>
          </div>

          <div className="bg-slate-800 rounded-xl p-6 border border-slate-700">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-400 text-sm">Pending</p>
                <p className="text-3xl font-bold text-white mt-1">{stats.pending}</p>
              </div>
              <Clock className="h-10 w-10 text-yellow-400" />
            </div>
          </div>

          <div className="bg-slate-800 rounded-xl p-6 border border-slate-700">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-400 text-sm">Active</p>
                <p className="text-3xl font-bold text-white mt-1">{stats.active}</p>
              </div>
              <CheckCircle2 className="h-10 w-10 text-green-400" />
            </div>
          </div>

          <div className="bg-slate-800 rounded-xl p-6 border border-slate-700">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-400 text-sm">Completed</p>
                <p className="text-3xl font-bold text-white mt-1">{stats.completed}</p>
              </div>
              <FileText className="h-10 w-10 text-emerald-400" />
            </div>
          </div>
        </div>

        <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
          <div className="p-6 border-b border-slate-700">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 h-5 w-5" />
                <input
                  type="text"
                  placeholder="Search clients..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <div className="flex items-center gap-2">
                <Filter className="h-5 w-5 text-slate-400" />
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="all">All Status</option>
                  <option value="pending">Pending</option>
                  <option value="verified">Verified</option>
                  <option value="approved">Approved</option>
                  <option value="active">Active</option>
                  <option value="rejected">Rejected</option>
                </select>
              </div>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-700/50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Company
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    PIC
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Contact
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Progress
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700">
                {filteredClients.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-8 text-center text-slate-400">
                      No clients found
                    </td>
                  </tr>
                ) : (
                  filteredClients.map((client) => {
                    const clientProgress = progress[client.id];
                    return (
                      <tr key={client.id} className="hover:bg-slate-700/30 transition-colors">
                        <td className="px-6 py-4">
                          <div>
                            <div className="text-white font-medium">{client.company_name}</div>
                            <div className="text-slate-400 text-sm">{client.business_type}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-slate-300">
                          {client.pic_name}
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-slate-300 text-sm">
                            <div>{client.email}</div>
                            <div className="text-slate-400">{client.phone}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          {getStatusBadge(client.status)}
                        </td>
                        <td className="px-6 py-4">
                          {clientProgress ? (
                            <div>
                              <div className="flex items-center gap-2 mb-1">
                                <div className="flex-1 bg-slate-700 rounded-full h-2 overflow-hidden">
                                  <div
                                    className="bg-emerald-500 h-full transition-all duration-300"
                                    style={{ width: `${clientProgress.progress_percentage}%` }}
                                  />
                                </div>
                                <span className="text-xs text-slate-400 min-w-[3rem]">
                                  {Math.round(clientProgress.progress_percentage)}%
                                </span>
                              </div>
                              <div className="text-xs text-slate-400">
                                {clientProgress.completed_steps}/{clientProgress.total_steps} steps
                              </div>
                            </div>
                          ) : (
                            <span className="text-slate-400 text-sm">No progress</span>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <button
                            onClick={() => setSelectedClient(client)}
                            className="flex items-center gap-2 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg transition-colors text-sm"
                          >
                            <Eye className="h-4 w-4" />
                            View
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      </main>

      {selectedClient && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-slate-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto border border-slate-700">
            <div className="p-6 border-b border-slate-700 flex justify-between items-start">
              <div>
                <h3 className="text-xl font-bold text-white">{selectedClient.company_name}</h3>
                <p className="text-slate-400 text-sm mt-1">Client Details</p>
              </div>
              <button
                onClick={() => setSelectedClient(null)}
                className="text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="text-sm text-slate-400">PIC Name</label>
                <p className="text-white mt-1">{selectedClient.pic_name}</p>
              </div>

              <div>
                <label className="text-sm text-slate-400">Email</label>
                <p className="text-white mt-1">{selectedClient.email}</p>
              </div>

              <div>
                <label className="text-sm text-slate-400">Phone</label>
                <p className="text-white mt-1">{selectedClient.phone}</p>
              </div>

              <div>
                <label className="text-sm text-slate-400">Business Type</label>
                <p className="text-white mt-1">{selectedClient.business_type}</p>
              </div>

              <div>
                <label className="text-sm text-slate-400">Address</label>
                <p className="text-white mt-1">{selectedClient.address}</p>
              </div>

              <div>
                <label className="text-sm text-slate-400">Status</label>
                <div className="mt-1">{getStatusBadge(selectedClient.status)}</div>
              </div>

              <div>
                <label className="text-sm text-slate-400">Created</label>
                <p className="text-white mt-1">
                  {new Date(selectedClient.created_at).toLocaleDateString('id-ID', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
