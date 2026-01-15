import { useEffect, useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { supabase } from '../../lib/supabase';
import { Client } from '../../types';
import { OnboardingTracker } from '../onboarding/OnboardingTracker';
import { DocumentUpload } from '../onboarding/DocumentUpload';
import { Building2, User, Mail, Phone, MapPin, LogOut } from 'lucide-react';

export function ClientDashboard() {
  const { user, signOut } = useAuth();
  const [client, setClient] = useState<Client | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user) {
      fetchClientData();
    }
  }, [user]);

  const fetchClientData = async () => {
    try {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('user_id', user?.id)
        .maybeSingle();

      if (error) throw error;

      setClient(data);
    } catch (error) {
      console.error('Error fetching client data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { bg: 'bg-amber-500/20', text: 'text-amber-400', border: 'border-amber-500/30', label: 'Menunggu Verifikasi' },
      verified: { bg: 'bg-blue-500/20', text: 'text-blue-400', border: 'border-blue-500/30', label: 'Terverifikasi' },
      approved: { bg: 'bg-emerald-500/20', text: 'text-emerald-400', border: 'border-emerald-500/30', label: 'Disetujui' },
      rejected: { bg: 'bg-red-500/20', text: 'text-red-400', border: 'border-red-500/30', label: 'Ditolak' },
      active: { bg: 'bg-emerald-500/20', text: 'text-emerald-400', border: 'border-emerald-500/30', label: 'Aktif' },
    };

    const config = statusConfig[status as keyof typeof statusConfig] || statusConfig.pending;

    return (
      <span className={`px-4 py-2 rounded-xl text-sm font-bold border ${config.bg} ${config.text} ${config.border}`}>
        {config.label}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 bg-grid-pattern">
      <nav className="bg-slate-800/80 backdrop-blur-sm border-b border-amber-500/20 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-20">
            <div className="flex items-center gap-4">
              <img
                src="/vista-logo_white.png"
                alt="Vista Client Portal"
                className="h-12 w-auto animate-float"
              />
              <div>
                <h1 className="text-xl font-bold text-white">Vista Client Portal</h1>
                <p className="text-xs text-slate-400 font-medium">Onboarding & Document Management</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <p className="text-sm font-bold text-white">{client?.pic_name}</p>
                <p className="text-xs text-slate-400">{client?.company_name}</p>
              </div>
              <button
                onClick={signOut}
                className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-slate-700 to-slate-600 hover:from-slate-600 hover:to-slate-500 text-white rounded-xl transition-all font-semibold shadow-lg"
              >
                <LogOut className="w-4 h-4" />
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm rounded-2xl shadow-xl border border-slate-700/50 p-8 mb-8 animate-slide-up">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-amber-500/20 rounded-xl flex items-center justify-center">
                <Building2 className="w-6 h-6 text-amber-400" />
              </div>
              <h2 className="text-2xl font-bold text-white">Informasi Perusahaan</h2>
            </div>
            {client && getStatusBadge(client.status)}
          </div>

          {client && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex items-start gap-3 p-4 bg-slate-900/30 rounded-xl border border-slate-700/50">
                <div className="w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Building2 className="w-5 h-5 text-amber-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-400 font-medium">Nama Perusahaan</p>
                  <p className="font-bold text-white text-lg">{client.company_name}</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-slate-900/30 rounded-xl border border-slate-700/50">
                <div className="w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <User className="w-5 h-5 text-amber-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-400 font-medium">PIC</p>
                  <p className="font-bold text-white text-lg">{client.pic_name}</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-slate-900/30 rounded-xl border border-slate-700/50">
                <div className="w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Mail className="w-5 h-5 text-amber-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-400 font-medium">Email</p>
                  <p className="font-bold text-white text-lg">{client.email}</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-slate-900/30 rounded-xl border border-slate-700/50">
                <div className="w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Phone className="w-5 h-5 text-amber-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-400 font-medium">Telepon</p>
                  <p className="font-bold text-white text-lg">{client.phone}</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-slate-900/30 rounded-xl border border-slate-700/50 md:col-span-2">
                <div className="w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                  <MapPin className="w-5 h-5 text-amber-400" />
                </div>
                <div className="flex-1">
                  <p className="text-sm text-slate-400 font-medium">Alamat</p>
                  <p className="font-bold text-white text-lg">{client.address}</p>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            {client && <OnboardingTracker clientId={client.id} />}
          </div>
          <div>
            {client && <DocumentUpload clientId={client.id} />}
          </div>
        </div>
      </div>
    </div>
  );
}
