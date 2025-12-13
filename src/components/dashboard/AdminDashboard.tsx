import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { ClientDetailView } from './ClientDetailView';
import { PasswordChangeModal } from '../auth/PasswordChangeModal';
import {
  Users,
  FileText,
  CheckCircle2,
  Clock,
  AlertCircle,
  LogOut,
  Search,
  Eye,
  Filter,
  Shield,
  XCircle,
  Calendar
} from 'lucide-react';

interface Client {
  id: string;
  full_name: string;
  company_name: string;
  pic_name: string;
  email: string;
  phone: string;
  business_type: string;
  product_type: 'ea_trading' | 'bimbel_prop' | 'vip_membership' | null;
  risk_profile: 'aggressive' | 'moderate' | 'conservative' | null;
  status: string;
  created_at: string;
  registration_completed_at: string;
}

interface OnboardingProgress {
  client_id: string;
  total_steps: number;
  completed_steps: number;
  progress_percentage: number;
}

export function AdminDashboard() {
  const { signOut, mustChangePassword } = useAuth();
  const [clients, setClients] = useState<Client[]>([]);
  const [progress, setProgress] = useState<Record<string, OnboardingProgress>>({});
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedClientId, setSelectedClientId] = useState<string | null>(null);

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
      (client.full_name?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (client.company_name?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      (client.pic_name?.toLowerCase() || '').includes(searchTerm.toLowerCase()) ||
      client.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'all' || client.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const stats = {
    total: clients.length,
    today: clients.filter(c => {
      const regDate = new Date(c.registration_completed_at || c.created_at);
      regDate.setHours(0, 0, 0, 0);
      return regDate.getTime() === today.getTime();
    }).length,
    pending: clients.filter(c => c.status === 'pending').length,
    approved: clients.filter(c => c.status === 'approved').length,
    rejected: clients.filter(c => c.status === 'rejected').length
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-white text-lg">Loading...</div>
      </div>
    );
  }

  return (
    <>
      {mustChangePassword && <PasswordChangeModal />}

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <header className="bg-slate-800/80 backdrop-blur-sm border-b border-teal-500/20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-5">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white via-teal-100 to-emerald-100">Vista Admin Portal</h1>
              <p className="text-slate-300 text-sm mt-1.5 font-medium">Client Management & Onboarding System</p>
            </div>
            <button
              onClick={signOut}
              className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-slate-700 to-slate-600 hover:from-slate-600 hover:to-slate-500 text-white rounded-xl transition-all font-semibold shadow-lg"
            >
              <LogOut className="h-4 w-4" />
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-white mb-2">Dashboard Overview</h2>
          <p className="text-slate-300 text-lg">Monitoring dan manajemen client onboarding</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-10">
          <div className="bg-gradient-to-br from-slate-800 to-slate-700 rounded-2xl p-6 border border-teal-500/30 shadow-lg hover:shadow-teal-500/20 transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-300 text-sm font-medium">Total Submissions</p>
                <p className="text-4xl font-bold text-white mt-2">{stats.total}</p>
              </div>
              <div className="w-12 h-12 bg-teal-500/20 rounded-xl flex items-center justify-center">
                <Users className="h-7 w-7 text-teal-400" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-slate-800 to-slate-700 rounded-2xl p-6 border border-emerald-500/30 shadow-lg hover:shadow-emerald-500/20 transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-300 text-sm font-medium">Today</p>
                <p className="text-4xl font-bold text-white mt-2">{stats.today}</p>
              </div>
              <div className="w-12 h-12 bg-emerald-500/20 rounded-xl flex items-center justify-center">
                <Calendar className="h-7 w-7 text-emerald-400" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-slate-800 to-slate-700 rounded-2xl p-6 border border-amber-500/30 shadow-lg hover:shadow-amber-500/20 transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-300 text-sm font-medium">Pending Review</p>
                <p className="text-4xl font-bold text-white mt-2">{stats.pending}</p>
              </div>
              <div className="w-12 h-12 bg-amber-500/20 rounded-xl flex items-center justify-center">
                <Clock className="h-7 w-7 text-amber-400" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-slate-800 to-slate-700 rounded-2xl p-6 border border-emerald-500/30 shadow-lg hover:shadow-emerald-500/20 transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-300 text-sm font-medium">Approved</p>
                <p className="text-4xl font-bold text-white mt-2">{stats.approved}</p>
              </div>
              <div className="w-12 h-12 bg-emerald-500/20 rounded-xl flex items-center justify-center">
                <CheckCircle2 className="h-7 w-7 text-emerald-400" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-slate-800 to-slate-700 rounded-2xl p-6 border border-red-500/30 shadow-lg hover:shadow-red-500/20 transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-slate-300 text-sm font-medium">Rejected</p>
                <p className="text-4xl font-bold text-white mt-2">{stats.rejected}</p>
              </div>
              <div className="w-12 h-12 bg-red-500/20 rounded-xl flex items-center justify-center">
                <XCircle className="h-7 w-7 text-red-400" />
              </div>
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
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Product
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Risk Profile
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Contact
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Status
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
                    const getProductLabel = () => {
                      switch (client.product_type) {
                        case 'ea_trading': return 'EA Trading';
                        case 'bimbel_prop': return 'Bimbel + Prop';
                        case 'vip_membership': return 'VIP Member';
                        default: return '-';
                      }
                    };

                    const getRiskLabel = () => {
                      switch (client.risk_profile) {
                        case 'aggressive': return 'Agresif';
                        case 'moderate': return 'Moderat';
                        case 'conservative': return 'Konservatif';
                        default: return '-';
                      }
                    };

                    return (
                      <tr key={client.id} className="hover:bg-slate-700/30 transition-colors">
                        <td className="px-6 py-4">
                          <div>
                            <div className="text-white font-medium">{client.full_name || client.company_name}</div>
                            <div className="text-slate-400 text-sm">{client.email}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <Shield className="h-4 w-4 text-blue-400" />
                            <span className="text-slate-300 text-sm">{getProductLabel()}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-slate-300 text-sm">
                          {getRiskLabel()}
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-slate-300 text-sm">
                            <div className="text-slate-400">{client.phone}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          {getStatusBadge(client.status)}
                        </td>
                        <td className="px-6 py-4">
                          <button
                            onClick={() => setSelectedClientId(client.id)}
                            className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white rounded-lg transition-all text-sm font-semibold shadow-lg shadow-teal-500/30 hover:shadow-xl hover:shadow-teal-500/40"
                          >
                            <Eye className="h-4 w-4" />
                            Review
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

      {selectedClientId && (
        <ClientDetailView
          clientId={selectedClientId}
          onClose={() => setSelectedClientId(null)}
          onUpdate={loadClients}
        />
      )}
    </div>
    </>
  );
}
